-- Fuzz harness: drives a real (tmux-hosted) Neovim through every sample file
-- and a set of global actions, recording anything that looks like an error.
-- Started by run.sh as `nvim -c 'luafile harness.lua'`.
--
-- Env: FZ_OUT   output path; writes FZ_OUT (JSONL), FZ_OUT.progress, FZ_OUT.sched
--      FZ_FILES newline-separated files to visit
--      FZ_QUICK "1" = only open each file (config-variant smoke runs)
--
-- Hard-won rules (each one hung or silently broke a run before):
--  * Log progress with io.open. vim.fn.writefile fails under textlock, and a
--    failing logger hides exactly the step you need to see.
--  * Run every step, the prompt check included, under pcall, and always
--    schedule the next step. An uncaught error ends the timer chain silently.
--  * Dismiss hit-enter prompts. One prompt otherwise blocks every later step.
--  * Separate keystrokes by ~200ms. <CR><Esc> in one feedkeys batch trips a
--    blink.cmp race (E785 from its dot-repeat hack) no human can hit.
local OUT = os.getenv("FZ_OUT")

-- Count vim.schedule calls by caller and dump the top callers every 5000
-- calls. When Neovim spins at 100% CPU this names the runaway callback; for
-- vim.schedule_wrap it names the wrapped function via the closure's upvalue.
local sched_counts, sched_total = {}, 0
local orig_schedule = vim.schedule
vim.schedule = function(fn)
  local info = debug.getinfo(2, "Sl")
  local key = info and (info.short_src .. ":" .. (info.currentline or 0)) or "?"
  if key:find("_core/editor", 1, true) then
    local wrapper = debug.getinfo(2, "f").func
    local wrapped = "?"
    for n = 1, 5 do
      local name, val = debug.getupvalue(wrapper, n)
      if name == "fn" and type(val) == "function" then
        local d = debug.getinfo(val, "S")
        wrapped = d.short_src .. ":" .. d.linedefined
      end
    end
    local caller = debug.getinfo(3, "Sl")
    key = "wrap(" .. wrapped .. ") from " .. (caller and (caller.short_src .. ":" .. (caller.currentline or 0)) or "?")
  end
  sched_counts[key] = (sched_counts[key] or 0) + 1
  sched_total = sched_total + 1
  if sched_total % 5000 == 0 then
    local top = {}
    for k, v in pairs(sched_counts) do top[#top + 1] = { k, v } end
    table.sort(top, function(a, b) return a[2] > b[2] end)
    local f = io.open(OUT .. ".sched", "a")
    if f then
      f:write(("--- total %d at %s\n"):format(sched_total, os.date("%H:%M:%S")))
      for n = 1, math.min(6, #top) do f:write(("%8d %s\n"):format(top[n][2], top[n][1])) end
      f:close()
    end
  end
  return orig_schedule(fn)
end

local FILES = vim.split(os.getenv("FZ_FILES") or "", "\n", { trimempty = true })
local QUICK = os.getenv("FZ_QUICK") == "1"
local log = {}

local notes = {}
local orig_notify = vim.notify
vim.notify = function(msg, level, opts)
  if (level or 0) >= vim.log.levels.WARN then
    notes[#notes + 1] = ("notify[%s] %s"):format(level, tostring(msg))
  end
  return orig_notify(msg, level, opts)
end

local function keys(s)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s, true, false, true), "t", false)
end

local function record(label)
  local msgs = vim.trim(vim.fn.execute("messages"))
  local entry = { label = label }
  if vim.v.errmsg ~= "" then entry.errmsg = vim.v.errmsg end
  if msgs ~= "" then entry.messages = msgs end
  if #notes > 0 then entry.notify = notes end
  entry.mode = vim.api.nvim_get_mode().mode
  entry.ft = vim.bo.filetype
  entry.clients = table.concat(vim.tbl_map(function(c) return c.name end, vim.lsp.get_clients({ bufnr = 0 })), ",")
  log[#log + 1] = entry
  vim.v.errmsg = ""
  notes = {}
  pcall(vim.cmd, "messages clear")
end

local steps = {}
local function step(delay, fn) steps[#steps + 1] = { delay = delay, fn = fn } end

-- Keymaps below are this config's: <leader>fl lint, <leader>p harpoon add,
-- <leader>ft format, <C-p> files, - oil, <leader>h harpoon menu, <leader>c close.
for _, f in ipairs(FILES) do
  step(300, function() vim.cmd("silent! %bwipeout!") end)
  step(QUICK and 800 or 2500, function() vim.cmd("edit " .. vim.fn.fnameescape(f)) end)
  step(200, function() record("open " .. f) end)
  if not QUICK then
    -- Typing "foo" makes most files invalid, so the format step below
    -- failing for css/go/json/lua is expected (see SKILL.md, known noise).
    step(800, function() keys("Gofoo") end)
    step(600, function() keys("<C-n>") end)
    step(200, function() keys("<CR>") end)
    step(200, function() keys("<Esc>") end)
    step(200, function() record("type+complete " .. f) end)
    step(300, function() keys("<Esc> fl") end)
    step(300, function() keys(" p") end)
    step(1500, function() keys(" ft") end)
    step(200, function() record("lint/harpoon/format " .. f) end)
    step(500, function() vim.cmd("silent! write!") end)
    step(200, function() record("write " .. f) end)
  end
end

if not QUICK then
  step(500, function() keys("<Esc><C-p>") end)
  step(1200, function() keys("<Esc><Esc>") end)
  step(200, function() record("telescope <C-p>") end)
  step(500, function() keys(" ff") end)
  step(1000, function() keys("<Esc><Esc>") end)
  step(200, function() record("telescope ff") end)
  step(500, function() keys("-") end)
  step(1000, function() record("oil open") end)
  step(300, function() keys("<C-c>"); vim.cmd("silent! bwipeout!") end)
  step(200, function() record("oil close") end)
  step(500, function() keys(" h") end)
  step(800, function() keys("q") end)
  step(200, function() record("harpoon menu") end)
  step(300, function() keys(" 1") end)
  step(500, function() keys(" 2") end)
  step(500, function() keys(" 3") end)
  step(500, function() record("harpoon jumps") end)
  step(300, function() vim.cmd("terminal") end)
  step(1000, function() keys("iexit<CR>") end)
  step(1000, function() record("terminal") end)
  step(300, function() keys("<Esc> c") end)
  step(500, function() keys("n") end)
  step(300, function() record("close buffer") end)
end

local function plog(line)
  local f = io.open(OUT .. ".progress", "a")
  if f then f:write(line .. "\n"); f:close() end
end

local i = 0
local function nxt()
  i = i + 1
  if i > #steps then
    record("end")
    local lines = {}
    for _, e in ipairs(log) do lines[#lines + 1] = vim.json.encode(e) end
    vim.fn.writefile(lines, OUT)
    vim.cmd("qa!")
    return
  end
  local ok, err = pcall(function()
    plog(("%d/%d mode=%s buf=%s"):format(i, #steps, vim.api.nvim_get_mode().mode, vim.fn.bufname()))
    if vim.api.nvim_get_mode().mode:sub(1, 1) == "r" then
      local okm, msgs = pcall(vim.fn.execute, "messages")
      notes[#notes + 1] = "HIT-ENTER PROMPT: " .. (okm and vim.trim(msgs):gsub("\n", " | ") or "?")
      keys("<CR>")
    end
    steps[i].fn()
  end)
  if not ok then
    notes[#notes + 1] = "HARNESS step " .. i .. " error: " .. tostring(err)
    plog("  step " .. i .. " ERROR: " .. tostring(err))
  end
  vim.defer_fn(nxt, steps[i].delay)
end
vim.defer_fn(function() record("startup"); nxt() end, 1500)
