-- lua/togglewin.lua
---@class ToggleWinOpts
---@field width? integer
---@field height? integer
---@field startinsert? boolean  -- enter terminal mode on open (default: true)

local M = {}

-- One shared terminal buffer; one toggled window
local state = {
  win = nil, ---@type integer|nil
  buf = nil, ---@type integer|nil  -- terminal buffer
  mode = nil, ---@type "float"|"split"|nil
}

-- ========= utilities (LuaJIT & lua_ls friendly) =========

-- Coerce to integer with a hard fallback (eliminates optional types)
local function to_int(n, fallback)
  if n == nil then
    return math.floor(tonumber(fallback or 0))
  end
  local num = tonumber(n) or tonumber(fallback or 0)
  -- emulate truncation toward zero to be explicit
  if num >= 0 then
    return math.floor(num)
  else
    return -math.floor(-num)
  end
end

-- Clamp helper that returns a plain number
local function clamp(x, lo, hi)
  if x < lo then
    return lo
  end
  if x > hi then
    return hi
  end
  return x
end

-- Close only the window; keep buffer alive
local function close_if_open()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.mode = nil
end

-- Is a terminal job alive?
local function job_is_alive(job_id)
  if type(job_id) ~= 'number' or job_id <= 0 then
    return false
  end
  local ok = vim.fn.jobwait({ job_id }, 0) -- 0ms timeout; -1 means running
  return ok and ok[1] == -1
end

-- ========= persistent terminal buffer =========
local function ensure_term_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) and vim.bo[state.buf].buftype == 'terminal' then
    local jid = vim.b[state.buf].terminal_job_id
    if not job_is_alive(jid) then
      -- Re-spawn a shell in the same buffer
      vim.api.nvim_buf_call(state.buf, function()
        local shell = (vim.o.shell ~= '' and vim.o.shell) or '/bin/sh'
        vim.fn.termopen(shell)
      end)
    end
    return state.buf
  end

  -- Create a new terminal buffer that PERSISTS when window closes
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = 'hide' -- keep buffer when not displayed
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].buflisted = true

  vim.api.nvim_buf_call(state.buf, function()
    local shell = (vim.o.shell ~= '' and vim.o.shell) or '/bin/sh'
    vim.fn.termopen(shell)
  end)

  -- q to close just the window
  vim.keymap.set('n', 'q', function()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_close(state.win, true)
    end
  end, { buffer = state.buf, nowait = true, silent = true })

  return state.buf
end

-- Set window-local options using modern API (avoids “Deprecated”)
local function set_win_opts(win)
  vim.api.nvim_set_option_value('winblend', 0, { win = win })
  vim.api.nvim_set_option_value('number', false, { win = win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = win })
  vim.api.nvim_set_option_value('signcolumn', 'no', { win = win })
end

-- ========= public toggles =========

---@param opts? ToggleWinOpts
function M.toggle_float(opts)
  if state.mode == 'float' and state.win and vim.api.nvim_win_is_valid(state.win) then
    close_if_open()
    return
  end
  close_if_open()

  opts = opts or {} ---@type ToggleWinOpts

  -- Editor dimensions (force concrete numbers)
  local columns = to_int(vim.o.columns, 120)
  local lines = to_int(vim.o.lines, 40) - to_int(vim.o.cmdheight, 1) - 2

  -- Defaults: ~80% of screen
  local def_w = to_int(math.floor(columns * 0.8 + 0.5), 80)
  local def_h = to_int(math.floor(lines * 0.8 + 0.5), 20)
  local width = to_int(opts.width or def_w, def_w)
  local height = to_int(opts.height or def_h, def_h)

  width = clamp(width, 10, columns - 2)
  height = clamp(height, 3, lines - 2)

  local row = to_int(math.floor((lines - height) / 2), 0)
  local col = to_int(math.floor((columns - width) / 2), 0)

  local win_opts = {
    style = 'minimal',
    relative = 'editor',
    row = row, -- number (not optional)
    col = col, -- number (not optional)
    width = width,
    height = height,
    border = 'rounded',
  }

  local buf = ensure_term_buf()
  state.win = vim.api.nvim_open_win(buf, true, win_opts)
  state.mode = 'float'

  local win = assert(state.win) ---@type integer
  set_win_opts(win)

  if opts.startinsert ~= false then
    vim.cmd 'startinsert'
  end
end

---@param opts? ToggleWinOpts
function M.toggle_split(opts)
  if state.mode == 'split' and state.win and vim.api.nvim_win_is_valid(state.win) then
    close_if_open()
    return
  end
  close_if_open()

  opts = opts or {} ---@type ToggleWinOpts

  local lines = to_int(vim.o.lines, 40) - to_int(vim.o.cmdheight, 1)
  local h_def = math.max(6, to_int(math.floor(lines * 0.3 + 0.5), 12))
  local height = to_int(opts.height or h_def, h_def) ---@type integer

  local buf = ensure_term_buf()
  vim.cmd 'botright split'
  state.win = vim.api.nvim_get_current_win()
  state.mode = 'split'
  vim.api.nvim_win_set_buf(assert(state.win), buf)
  vim.api.nvim_win_set_height(assert(state.win), height)

  local win = assert(state.win) ---@type integer
  set_win_opts(win)

  if opts.startinsert ~= false then
    vim.cmd 'startinsert'
  end
end

function M.close()
  close_if_open()
end

-- Close current floating or split window with Ctrl+\ even in terminal mode
vim.keymap.set({ 't', 'n' }, '<C-\\>', function()
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end, { desc = 'Close current window (float or split)' })

return M
