#!/usr/bin/env bash
# Prepare an isolated test workspace for this Neovim config.
#
#   bash setup.sh WORK [REF]
#
# WORK  directory to create (put it in the session scratchpad)
# REF   git ref to test; "." (default) tests the working tree as it is now,
#       including uncommitted changes
#
# Creates:
#   WORK/src        the config under test (no .git), plus your lazy-lock.json
#   WORK/data/nvim  a copy of ~/.local/share/nvim/{lazy,mason,site}, so runs
#                   never touch your real plugins
#   WORK/files      sample files (see make-samples.sh)
set -euo pipefail

WORK="${1:?usage: setup.sh WORK [REF]}"
REF="${2:-.}"
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(git -C "$HERE" rev-parse --show-toplevel)"

mkdir -p "$WORK"
WORK="$(cd "$WORK" && pwd)"
rm -rf "$WORK/src"
mkdir -p "$WORK/src"

if [ "$REF" = "." ]; then
  # tracked + untracked-but-not-ignored files, as they are on disk
  (cd "$REPO" && git ls-files -co --exclude-standard -z | tar --null -T - -cf -) | tar -xf - -C "$WORK/src"
else
  git -C "$REPO" archive "$REF" | tar -xf - -C "$WORK/src"
fi
# Never test the skill's own files as part of the config.
rm -rf "$WORK/src/.agents" "$WORK/src/.claude"

# Same plugin versions as the seeded data dir.
if [ -f "$HOME/.config/nvim/lazy-lock.json" ]; then
  cp "$HOME/.config/nvim/lazy-lock.json" "$WORK/src/"
fi
# The machine's own configs/init.lua (gitignored), used by the @local variant.
if [ -f "$REPO/lua/configs/init.lua" ]; then
  cp "$REPO/lua/configs/init.lua" "$WORK/local-configs-init.lua"
fi

if [ ! -d "$WORK/data/nvim/lazy" ]; then
  mkdir -p "$WORK/data/nvim"
  for d in lazy mason site; do
    if [ -d "$HOME/.local/share/nvim/$d" ]; then
      cp -a "$HOME/.local/share/nvim/$d" "$WORK/data/nvim/"
    fi
  done
fi

bash "$HERE/make-samples.sh" "$WORK/files"

echo "workspace ready: $WORK"
echo "  src:   $(cd "$REPO" && if [ "$REF" = "." ]; then echo "working tree ($(git rev-parse --short HEAD) + local changes)"; else git rev-parse --short "$REF"; fi)"
echo "  data:  $(du -sh "$WORK/data" | cut -f1)"
echo "  files: $(find "$WORK/files" -type f ! -path '*/.git/*' | wc -l) samples"
