-- lua/togglewin.lua
---@class ToggleWinOpts
---@field width? integer
---@field height? integer
---@field startinsert? boolean  -- enter terminal mode on open (default: true)

local M = {}

-- Multiple terminal buffers, one per directory
local state = {
  win = nil, ---@type integer|nil
  mode = nil, ---@type "float"|"split"|nil
  terms = {}, ---@type table<string, integer>  -- cwd -> buf mapping
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

-- Get the working directory for current buffer
local function get_current_dir()
  -- Try to get the directory of the current file
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname and bufname ~= '' then
    local dir = vim.fn.fnamemodify(bufname, ':p:h')
    if vim.fn.isdirectory(dir) == 1 then
      return dir
    end
  end
  -- Fallback to Neovim's current working directory
  return vim.fn.getcwd()
end

-- ========= persistent terminal buffers per directory =========
local function ensure_term_buf()
  local cwd = get_current_dir()

  -- Check if we have a valid terminal for this directory
  if state.terms[cwd] and vim.api.nvim_buf_is_valid(state.terms[cwd]) and vim.bo[state.terms[cwd]].buftype == 'terminal' then
    local jid = vim.b[state.terms[cwd]].terminal_job_id
    if not job_is_alive(jid) then
      -- Re-spawn a shell in the same buffer
      vim.api.nvim_buf_call(state.terms[cwd], function()
        local shell = (vim.o.shell ~= '' and vim.o.shell) or '/bin/sh'
        vim.fn.termopen(shell, { cwd = cwd })
      end)
    end
    return state.terms[cwd]
  end

  -- Create a new terminal buffer for this directory
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'hide' -- keep buffer when not displayed
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = true

  vim.api.nvim_buf_call(buf, function()
    local shell = (vim.o.shell ~= '' and vim.o.shell) or '/bin/sh'
    vim.fn.termopen(shell, { cwd = cwd })
  end)

  -- Store the directory in the buffer for reference
  vim.b[buf].terminal_cwd = cwd

  -- q to close just the window
  vim.keymap.set('n', 'q', function()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_close(state.win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })

  state.terms[cwd] = buf
  return buf
end

-- Set window-local options using modern API (avoids "Deprecated")
local function set_win_opts(win)
  vim.api.nvim_set_option_value('winblend', 0, { win = win })
  vim.api.nvim_set_option_value('number', false, { win = win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = win })
  vim.api.nvim_set_option_value('signcolumn', 'no', { win = win })
end

-- ========= public toggles =========

---@param opts? ToggleWinOpts
function M.toggle_float(opts)
  local cwd = get_current_dir()

  -- If we're toggling the same directory's terminal in float mode, close it
  if state.mode == 'float' and state.win and vim.api.nvim_win_is_valid(state.win) then
    local current_buf = vim.api.nvim_win_get_buf(state.win)
    if vim.b[current_buf].terminal_cwd == cwd then
      close_if_open()
      return
    end
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
  local cwd = get_current_dir()

  -- If we're toggling the same directory's terminal in split mode, close it
  if state.mode == 'split' and state.win and vim.api.nvim_win_is_valid(state.win) then
    local current_buf = vim.api.nvim_win_get_buf(state.win)
    if vim.b[current_buf].terminal_cwd == cwd then
      close_if_open()
      return
    end
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

-- List and switch between terminal buffers
function M.list_terminals()
  -- Collect valid terminals
  local terminals = {}
  for cwd, buf in pairs(state.terms) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' then
      table.insert(terminals, {
        cwd = cwd,
        buf = buf,
        display = cwd,
      })
    else
      -- Clean up invalid buffers
      state.terms[cwd] = nil
    end
  end

  if #terminals == 0 then
    vim.notify('No terminal buffers open', vim.log.levels.INFO)
    return
  end

  -- Find the currently open terminal buffer
  local current_buf = nil
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    current_buf = vim.api.nvim_win_get_buf(state.win)
  end

  -- Sort: current buffer first, then alphabetically by directory
  table.sort(terminals, function(a, b)
    local a_is_current = (current_buf and a.buf == current_buf)
    local b_is_current = (current_buf and b.buf == current_buf)

    if a_is_current and not b_is_current then
      return true
    elseif b_is_current and not a_is_current then
      return false
    else
      return a.cwd < b.cwd
    end
  end)

  -- Mark the currently open terminal buffer
  if current_buf then
    for i, term in ipairs(terminals) do
      if term.buf == current_buf then
        term.display = term.cwd .. ' [current]'
        break
      end
    end
  end

  -- Use vim.ui.select for picker (works with telescope/fzf if configured)
  vim.ui.select(terminals, {
    prompt = 'Select terminal:',
    format_item = function(item)
      return item.display
    end,
  }, function(choice)
    if not choice then
      return
    end

    -- If a terminal window is already open, switch to the selected buffer
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      vim.api.nvim_win_set_buf(state.win, choice.buf)
      vim.api.nvim_set_current_win(state.win)
      vim.cmd 'startinsert'
    else
      -- No terminal window open, open in float mode with the selected buffer
      local opts = {}
      local columns = to_int(vim.o.columns, 120)
      local lines = to_int(vim.o.lines, 40) - to_int(vim.o.cmdheight, 1) - 2

      local def_w = to_int(math.floor(columns * 0.8 + 0.5), 80)
      local def_h = to_int(math.floor(lines * 0.8 + 0.5), 20)
      local width = clamp(def_w, 10, columns - 2)
      local height = clamp(def_h, 3, lines - 2)

      local row = to_int(math.floor((lines - height) / 2), 0)
      local col = to_int(math.floor((columns - width) / 2), 0)

      local win_opts = {
        style = 'minimal',
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        border = 'rounded',
      }

      state.win = vim.api.nvim_open_win(choice.buf, true, win_opts)
      state.mode = 'float'

      local win = assert(state.win)
      set_win_opts(win)
      vim.cmd 'startinsert'
    end
  end)
end

-- Close current floating or split window with Ctrl+\ even in terminal mode
vim.keymap.set({ 't', 'n' }, '<C-\\>', function()
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
end, { desc = 'Close current window (float or split)' })

-- Keybind to list/switch terminals
vim.keymap.set('n', '<leader>tl', function()
  M.list_terminals()
end, { desc = 'List and switch terminals' })

return M
