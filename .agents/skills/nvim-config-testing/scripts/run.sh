#!/usr/bin/env bash
# One fuzz run in a real Neovim inside a detached tmux session.
#
#   bash run.sh WORK NAME INIT [quick]
#
# INIT  what lua/configs/init.lua should be for this run:
#         @local  this machine's own configs/init.lua (copied by setup.sh)
#         @none   no file, to test first-run creation
#         anything else is written verbatim, e.g. 'return require("configs.debian")'
# quick "1" only opens each file; omit for the full editing pass.
#
# Env: FZ_ONLY  newline-separated subset of files (e.g. "./a.c\n./a.cpp") to
#               reproduce a failure quickly. FZ_TIMEOUT seconds (default 900).
#
# Results: WORK/runs/NAME/out.jsonl (+ .progress, .sched); prints done/HUNG.
# On a hang the screen is saved to hung-screen.txt and the Neovim process is
# LEFT RUNNING so stalled.sh can inspect it -- run cleanup.sh afterwards.
set -euo pipefail

WORK="$(cd "${1:?usage: run.sh WORK NAME INIT [quick]}" && pwd)"
NAME="${2:?}"; INIT="${3:?}"; QUICK="${4:-0}"
HERE="$(cd "$(dirname "$0")" && pwd)"
R="$WORK/runs/$NAME"

rm -rf "$R"; mkdir -p "$R/cfg"
cp -a "$WORK/src" "$R/cfg/nvim"
rm -f "$R/cfg/nvim/lua/configs/init.lua"
case "$INIT" in
  @none) ;;
  @local) cp "$WORK/local-configs-init.lua" "$R/cfg/nvim/lua/configs/init.lua" ;;
  *) printf '%s\n' "$INIT" > "$R/cfg/nvim/lua/configs/init.lua" ;;
esac
cp -a "$WORK/files" "$R/files"
chmod 444 "$R/files/readonly.lua"

files="${FZ_ONLY:-$(cd "$R/files" && find . -type f ! -path './.git/*' | sort)}"
session="nvt-$NAME"
tmux kill-session -t "$session" 2>/dev/null || true
# Fresh XDG_STATE_HOME per run: shared state leaves swap files behind after a
# hang, and the next run then stops on the swap-file prompt.
tmux new-session -d -s "$session" -x 140 -y 45 -c "$R/files" \
  "env XDG_CONFIG_HOME='$R/cfg' XDG_DATA_HOME='$WORK/data' XDG_STATE_HOME='$R/state' XDG_CACHE_HOME='$R/cache' FZ_OUT='$R/out.jsonl' FZ_QUICK='$QUICK' FZ_FILES='$files' nvim -c 'luafile $HERE/harness.lua' 2>'$R/stderr.txt'"

limit="${FZ_TIMEOUT:-900}"; last=""; still=0
for _ in $(seq 1 "$limit"); do
  tmux has-session -t "$session" 2>/dev/null || break
  sleep 1
  cur="$(tail -1 "$R/out.jsonl.progress" 2>/dev/null || true)"
  if [ "$cur" = "$last" ]; then still=$((still + 1)); else still=0; last="$cur"; fi
  # No step takes 60s; treat that as a hang rather than waiting out the limit.
  [ "$still" -ge 60 ] && break
done

if tmux has-session -t "$session" 2>/dev/null; then
  tmux capture-pane -p -t "$session" > "$R/hung-screen.txt"
  echo "$NAME: HUNG at: $last  (screen: $R/hung-screen.txt; process left running for stalled.sh)"
  exit 1
fi
if [ -f "$R/out.jsonl" ]; then
  echo "$NAME: done ($(wc -l < "$R/out.jsonl") records)"
else
  echo "$NAME: NO OUTPUT (see $R/stderr.txt)"; exit 1
fi
