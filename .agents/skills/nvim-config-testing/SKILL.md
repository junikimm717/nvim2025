---
name: nvim-config-testing
description: Test this Neovim config end to end on the local machine - fuzz a real Neovim through 37 sample files (typing, completion, lint, format, harpoon, telescope, oil, terminal), every theme/configs variant, the Docker images, and the no-admin bootstrap - then diagnose hangs. Use when asked to test, verify, fuzz or smoke-test config changes, check a PR before merging, or find breakage in the images or bootstrap.
---

# Testing this Neovim config

Everything runs in an isolated workspace: a copy of the config, a copy of
`~/.local/share/nvim`, and per-run state. **Your real plugins, Mason
packages, harpoon marks and swap files are never touched.** All scripts are
bash; run them as `bash scripts/X.sh` (the user's shell is zsh, which errors
on unmatched globs and treats `$var:x` as a modifier).

Use the session scratchpad for `WORK`, e.g. `WORK=$SCRATCHPAD/nvt`.

## Workflow

1. **Set up** (once per thing you test; ~10s):
   `bash scripts/setup.sh $WORK [REF]`. REF defaults to `.` (the working
   tree, including uncommitted changes); pass a branch or commit otherwise.
   Re-run it after every fix so the next run tests the new code.
2. **Pick what to run** (independent; run them in parallel with
   `run_in_background` and wait for notifications, never poll with sleep):

   | Changed | Run | Time |
   |---|---|---|
   | Any Lua config | `bash scripts/variants.sh $WORK` | ~15 min |
   | One area, quick repro | `FZ_ONLY=$'./a.c\n./a.cpp' bash scripts/run.sh $WORK repro @local` | 1-2 min |
   | `dockerfile/`, `pkgs/`, Mason or treesitter lists, plugin versions | `bash scripts/images.sh $WORK` | ~5 min |
   | `_bootstrap.sh`, `Makefile`, `pkgs/` | `bash scripts/bootstrap.sh $WORK` (+ `images.sh $WORK bootstrap` for a full clean-machine install) | ~1 min |

3. **Read results**: `python3 scripts/summary.py $WORK/runs/*/out.jsonl`
   prints only unexplained output (exit 1 if any). `--all` shows the known
   noise too. Image results print directly; files are in `$WORK/images/`.
4. **A run printed HUNG**: `bash scripts/stalled.sh $WORK NAME`, then see
   "Diagnosing hangs" below. Fix, re-run `setup.sh`, re-run the suite.
5. **Always finish with** `bash scripts/cleanup.sh $WORK --images`. Runs
   leave language servers, prettierd daemons, containers and (after a hang)
   a spinning Neovim behind.

Before blaming a finding on the change under test, check whether master has
it too: `bash scripts/setup.sh $WORK-master master` and run the same thing.

## What each test proves

- **variants.sh**: `full` opens every sample file (30 filetypes plus an empty
  file, a 100k-line file, binary data, paths with spaces and Unicode, a
  read-only file, CRLF, 500 levels of nesting). For each one it types and
  accepts a completion, lints (`<leader>fl`), adds a harpoon mark, formats
  (`<leader>ft`) and saves. Then it runs Telescope, oil, the harpoon menu,
  harpoon jumps, the terminal and buffer close. After that come quick runs
  for every `lua/configs/*.lua` theme, a missing `configs/init.lua` (it must
  get created), a malformed one (it must stay unchanged), and empty
  Mason/treesitter lists.
- **images.sh**: a build exiting 0 proves little, because errors inside the
  headless `FullSetup` don't fail it. So for each image it also scans the
  FullSetup log, runs every Mason binary, and opens 11 filetypes in a real
  Neovim. Check that servers attach where installed, `blink fuzzy: rust`
  shows (`lua` means its binary download failed), and `messages: -` shows.
  A HUNG image is almost always a prompt; its screen is printed.
- **bootstrap.sh**: checks the download URLs for both architectures, the
  no-argument usage message, and that a dropped download fails the script
  and `make` (no marker written) while a rerun recovers.

## Known noise (ignored by summary.py)

Each entry is explained; if you add one to `NOISE` in summary.py, add it here.

- `E116 ... dictwatcherdel` at startup: barbar removes watchers under
  `silent!`, so it only lands in `v:errmsg`.
- `E117 repeat#set` and `E490 No fold found`: LuaSnip and gitsigns call
  vim-repeat under `silent!`.
- `Too large file: huge.lua skipped`: lua_ls skipping the 1.5MB sample.
- `Formatter failed` on css/go/json/lua/deep.py: the harness types `foo`,
  which makes those files invalid, and black gives up on 500 levels of
  nesting. Check `$WORK/runs/NAME/state/nvim/conform.log`: the errors should
  all be syntax errors. Any other formatter error is real (eslint_d failing
  without an ESLint config was one).
- `W10 readonly`: the read-only sample. `Type :qa` and `E35`: harness
  keystrokes (`<C-c>`, then `n` after a close that didn't prompt).
- `tailwindcss` attaching to markdown or other files: lspconfig falls back
  to `.git` as its root (for Tailwind v4), and the samples dir is a git repo.
  Outside a Tailwind project it returns no completions.

## Diagnosing hangs

`stalled.sh` shows the last step, the screen, CPU usage, gdb stacks and the
harness's `vim.schedule` counts.

- **High CPU, stacks in `nlua_schedule_event`, and one huge entry in the
  schedule counts**: a callback storm. The top entry names the function
  (`wrap(file:line)` is the function given to `vim.schedule_wrap`). This is
  how the barbar animation freeze was found: `barbar/animate.lua:87` with
  750,000 calls. Exit can hang the same way (stack in
  `getout`/`VimLeavePre`), because `vim.wait` on exit drains the storm.
- **Low CPU and a prompt on screen**: the harness didn't dismiss it. A
  swap-file prompt means state was shared between runs; `run.sh` uses a
  fresh `XDG_STATE_HOME` per run to avoid that.
- **Doesn't reproduce in a small repro**: the hang depends on accumulated
  state (many buffers, harpoon marks). Re-run `full` and catch it live
  rather than guessing.

## Pitfalls

These each cost real time once:

- **Headless is not enough.** Completion menus, redraw-time work (barbar,
  colorizer, indent guides) and prompts need a UI. Run Neovim in tmux, and
  wait a few seconds after opening a file before calling it fine.
- **Harness rules** (see the header of `harness.lua`):
  - Log with `io.open`, not `vim.fn.writefile` (textlock).
  - Run each step under `pcall` and always reschedule the next one.
  - Dismiss hit-enter prompts.
  - Space keystrokes about 200ms apart. Sending `<CR><Esc>` in one batch
    trips a blink.cmp race that no human can hit.
- **Give each container check its own output file.** A shared file gets
  overwritten.
- **Kill only your own things**, by name (`nvt-*`) or by image
  (`nvim2025-test:*`). The permission classifier blocks broad
  `docker kill $(docker ps -q)`, and it would hit the user's containers.
- **Don't `pkill -f` a pattern** that also appears in your own command line;
  it kills your shell. Find the child pid instead.
- **Plugins float.** `lazy-lock.json` is gitignored, so images install
  whatever is newest, and the local data dir differs from the images. A
  break that appears only in images (VimTeX master requiring Neovim 0.12.4
  was one) can be an upstream change on the day you test. Compare plugin
  versions (`git -C <plugin> log -1`) before assuming your change caused it.
- **Wall-clock budget.** A full image build plus checks takes ~5 minutes,
  and `alpine-c@arm64` under QEMU about 3 more. `debian@arm64` compiles
  Neovim under QEMU and takes far longer; only run it when the Debian
  Dockerfile changed.
