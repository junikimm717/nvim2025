#!/usr/bin/env bash
# The standard suite: the full editing pass with this machine's config, then
# quick runs over every theme config and the edge cases of configs/init.lua.
#
#   bash variants.sh WORK
#
# Runs sequentially (they share WORK/data). Takes ~15 minutes; start it with
# run_in_background and wait for the notification.
set -uo pipefail
WORK="$(cd "${1:?usage: variants.sh WORK}" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
run() { bash "$HERE/run.sh" "$WORK" "$@"; }

if [ -f "$WORK/local-configs-init.lua" ]; then run full @local 0; else run full 'return require("configs.catppuccin")' 0; fi
for c in $(cd "$WORK/src/lua/configs" && ls *.lua | sed 's/\.lua$//' | grep -v '^init$'); do
  run "theme-$c" "return require(\"configs.$c\")" 1
done
run missing-init @none 1
echo "  missing-init: configs/init.lua afterwards = $(cat "$WORK/runs/missing-init/cfg/nvim/lua/configs/init.lua" 2>&1)"
run malformed-init 'return { lazy = require("themes.gruvbox"), mason = {' 1
echo "  malformed-init: file afterwards (must be unchanged) = $(cat "$WORK/runs/malformed-init/cfg/nvim/lua/configs/init.lua")"
run empty-lists 'return { lazy = require("themes.gruvbox"), mason = {}, treesitter = {} }' 1
echo ALL-DONE
