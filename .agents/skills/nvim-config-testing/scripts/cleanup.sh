#!/usr/bin/env bash
# Stop everything the test scripts started. Only ever touches our own things:
# tmux sessions named nvt-*, containers named nvt-* or built from
# nvim2025-test:* images, and processes whose working directory is in WORK.
# Never `docker kill $(docker ps -q)` -- that kills the user's containers too.
#
#   bash cleanup.sh WORK [--images]     # --images also removes nvim2025-test:* images
set -uo pipefail
WORK="$(cd "${1:?usage: cleanup.sh WORK [--images]}" && pwd)"

sessions=0
for s in $(tmux ls -F '#S' 2>/dev/null | grep '^nvt-'); do tmux kill-session -t "$s" && sessions=$((sessions + 1)); done
# Closing a session hangs up its Neovim; give it a moment before sweeping.
[ "$sessions" -gt 0 ] && sleep 2
echo "closed $sessions tmux sessions"

ids="$( { docker ps -q --filter name=nvt-; for img in $(docker images --format '{{.Repository}}:{{.Tag}}' | grep '^nvim2025-test:'); do docker ps -q --filter ancestor="$img"; done; } | sort -u)"
[ -n "$ids" ] && docker kill $ids >/dev/null

# Language servers, prettierd daemons and stuck nvim processes started by the
# runs all have their cwd inside WORK.
n=0
for d in /proc/[0-9]*; do
  p="${d#/proc/}"
  cwd="$(readlink "/proc/$p/cwd" 2>/dev/null)" || continue
  case "$cwd" in "$WORK"*) [ "$p" != "$$" ] && kill -9 "$p" 2>/dev/null && n=$((n + 1)) ;; esac
done
# The TUI's `nvim --embed` child may have a different cwd; match its env.
for p in $(pgrep -f "nvim --embed -c luafile .*/harness.lua" || true); do
  tr '\0' '\n' < "/proc/$p/environ" 2>/dev/null | grep -q "^FZ_OUT=$WORK/" && kill -9 "$p" && n=$((n + 1))
done
echo "stopped $n leftover processes"

if [ "${2:-}" = "--images" ]; then
  imgs="$(docker images --format '{{.Repository}}:{{.Tag}}' | grep '^nvim2025-test:' || true)"
  [ -n "$imgs" ] && docker image rm $imgs >/dev/null && echo "removed images: $(echo $imgs)"
fi
