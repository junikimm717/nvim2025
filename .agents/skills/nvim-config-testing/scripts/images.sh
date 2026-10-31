#!/usr/bin/env bash
# Build the Docker images from WORK/src and check each one actually works.
#
#   bash images.sh WORK [TARGET...]
#
# TARGET: debian alpine-c alpine-js bootstrap finch, optionally suffixed
# @arm64 to build under QEMU (e.g. alpine-c@arm64). Default: the four amd64
# images (debian alpine-c alpine-js bootstrap).
# finch builds a Julia stack and debian@arm64 compiles Neovim under QEMU;
# both take very long, so only include them deliberately.
#
# A build exiting 0 proves little: errors inside the headless `FullSetup`
# step don't fail the build. So for each image this also
#   1. scans the FullSetup part of the build log for errors,
#   2. runs every Mason binary's --version,
#   3. opens 11 filetypes in a real Neovim (image-check.lua) inside tmux, so
#      a prompt shows up as a hang with the screen captured instead of
#      silently blocking.
# Output: WORK/images/{build-T.log, T.txt, T-screen.txt, T-mason.txt}
set -uo pipefail
WORK="$(cd "${1:?usage: images.sh WORK [TARGET...]}" && pwd)"; shift
HERE="$(cd "$(dirname "$0")" && pwd)"
TARGETS=("$@"); [ ${#TARGETS[@]} -eq 0 ] && TARGETS=(debian alpine-c alpine-js bootstrap)
O="$WORK/images"; mkdir -p "$O"

dockerfile() {
  case "$1" in
    debian) echo Dockerfile ;; *) echo "$1.Dockerfile" ;;
  esac
}

echo "== building: ${TARGETS[*]}"
for t in "${TARGETS[@]}"; do
  base="${t%@*}"; plat=""; [ "$t" != "$base" ] && plat="--platform linux/${t#*@}"
  tag="nvim2025-test:${t/@/-}"
  (
    start=$(date +%s)
    # shellcheck disable=SC2086
    docker build $plat --progress=plain -f "$WORK/src/dockerfile/$(dockerfile "$base")" -t "$tag" "$WORK/src" > "$O/build-${t/@/-}.log" 2>&1
    echo "EXIT=$? SECONDS=$(( $(date +%s) - start ))" >> "$O/build-${t/@/-}.log"
  ) &
done
wait

for t in "${TARGETS[@]}"; do
  n="${t/@/-}"; tag="nvim2025-test:$n"; plat=""; [ "$t" != "${t%@*}" ] && plat="--platform linux/${t#*@}"
  echo; echo "======== $t: $(tail -1 "$O/build-$n.log")"
  grep -q "EXIT=0" "$O/build-$n.log" || { echo "  build failed; see $O/build-$n.log"; continue; }

  echo "-- errors in the FullSetup step (npm EBADENGINE = Node too old for a package):"
  awk '/Lazy! sync \+FullSetup/{f=1} f' "$O/build-$n.log" | sed 's/\x1b\[[0-9;]*m//g' \
    | grep -iE 'ENOENT|EBADENGINE|error:|error during|failed|traceback|not found|cannot' \
    | grep -vE '"test": "echo|Error: no test specified|Receiving objects|Counting objects' \
    | sed -E 's/^#[0-9]+ [0-9.]+ //' | cut -c1-200 | sort | uniq -c | sort -rn | head -10

  echo "-- Mason binaries that fail to run:"
  # shellcheck disable=SC2086
  docker run --rm $plat "$tag" sh -c '
    B=$(ls -d ~/.local/share/nvim/mason/bin /nvim/build/nvim/share/nvim/mason/bin 2>/dev/null | head -1)
    export PATH="/nvim/build/bin:$PATH"
    for b in $(ls "$B" 2>/dev/null); do
      out=$(timeout 15 "$B/$b" --version </dev/null 2>&1 | head -3 | tr "\n" " ")
      case "$out" in
        *"not found"*|*"No such file"*|*"Error relocating"*|*"symbol not found"*|*"SyntaxError"*|*"cannot execute"*|*"Exec format"*|*"ICU"*|*"Segmentation"*)
          echo "  FAIL $b: $(echo "$out" | cut -c1-150)";;
      esac
    done' > "$O/$n-mason.txt" 2>&1
  if [ -s "$O/$n-mason.txt" ]; then cat "$O/$n-mason.txt"; else echo "  (all run)"; fi

  echo "-- editor check:"
  rm -f "$O/$n.txt" "$O/$n.progress"
  tmux kill-session -t "nvt-img-$n" 2>/dev/null
  # shellcheck disable=SC2086
  tmux new-session -d -s "nvt-img-$n" -x 140 -y 45 \
    "docker run --rm -it $plat --name nvt-img-$n -v '$HERE/image-check.lua:/check.lua:ro' -v '$O:/out' -e IMG=$n $tag nvim -c 'luafile /check.lua'"
  for _ in $(seq 1 180); do [ -f "$O/$n.txt" ] && break; sleep 1; done
  if [ -f "$O/$n.txt" ]; then
    sed 's/^/  /' "$O/$n.txt"
  else
    tmux capture-pane -p -t "nvt-img-$n" > "$O/$n-screen.txt"
    echo "  HUNG while $(tail -1 "$O/$n.progress" 2>/dev/null) -- screen:"
    grep -v '^~ *$' "$O/$n-screen.txt" | tail -15 | sed 's/^/  | /'
  fi
  docker kill "nvt-img-$n" >/dev/null 2>&1
  tmux kill-session -t "nvt-img-$n" 2>/dev/null
done
