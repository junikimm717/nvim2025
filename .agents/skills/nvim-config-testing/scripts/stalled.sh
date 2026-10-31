#!/usr/bin/env bash
# Diagnose a fuzz run that run.sh reported as HUNG.
#
#   bash stalled.sh WORK NAME
#
# Prints the last progress lines (the step that never finished), the saved
# screen, CPU usage of the run's Neovim, three gdb stack samples, and the
# harness's vim.schedule counts.
#
# Reading it:
#  * high CPU + stacks in lua/nlua_schedule_event + one dominant entry in the
#    schedule counts  ->  a callback storm; the top `.sched` entry names it
#    (barbar's animate.lua was one).
#  * stack in getout/preserve_exit/VimLeavePre  ->  stuck while exiting.
#  * low CPU + a prompt on screen  ->  a prompt the harness didn't dismiss.
set -uo pipefail
WORK="$(cd "${1:?usage: stalled.sh WORK NAME}" && pwd)"; NAME="${2:?}"
R="$WORK/runs/$NAME"

echo "== last progress"; tail -5 "$R/out.jsonl.progress" 2>/dev/null
echo "== screen"; grep -v '^~ *$' "$R/hung-screen.txt" 2>/dev/null | tail -12

# The TUI forks an `nvim --embed` server; that's the process doing the work.
pids="$(pgrep -f "nvim --embed -c luafile .*/harness.lua" || true)"
for pid in $pids; do
  env_out="$(tr '\0' '\n' < /proc/"$pid"/environ 2>/dev/null | grep "^FZ_OUT=$R/" || true)"
  [ -z "$env_out" ] && continue
  echo "== nvim pid $pid"; ps -o pid,stat,pcpu,etime -p "$pid"
  if command -v gdb >/dev/null; then
    for n in 1 2 3; do
      echo "-- stack sample $n"
      gdb -p "$pid" -batch -ex 'bt 25' 2>/dev/null | grep -E '^#' | head -25
      sleep 1
    done
  else
    echo "(gdb not installed: no stack samples)"
  fi
done

echo "== vim.schedule callers (latest dump)"
if [ -f "$R/out.jsonl.sched" ]; then
  awk '/^---/{block=""} {block=block $0 "\n"} END{printf "%s", block}' "$R/out.jsonl.sched"
else
  echo "(no dump: fewer than 5000 scheduled callbacks, so not a callback storm)"
fi
