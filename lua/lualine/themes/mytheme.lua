-- ─────────────────────────────────────────────────────────────
-- Lualine theme (place in: lua/lualine/themes/mytheme.lua)
-- ─────────────────────────────────────────────────────────────
-- This makes lualine pick colors that match this Monokai theme.
-- Create the file path above and paste the block below into it.
-- Then enable with the setup snippet further down.

-- lua/lualine/themes/mytheme.lua
-- (BEGIN FILE)
-- Note: this is a *separate* file from colors/mytheme.lua
local M = {}

-- Re-declare the palette to avoid runtime deps on the colorscheme file
local p = {
  bg = '#272822',
  bg_alt = '#1f201c',
  surface = '#2e2f29',
  cursorln = '#32342c',
  selection = '#49483e',
  border = '#3a3b35',
  fg = '#f8f8f2',
  comment = '#75715e',
  pink = '#f92672', -- accent for replace/keyword vibe
  orange = '#fd971f',
  yellow = '#e6db74',
  green = '#a6e22e',
  aqua = '#66d9ef', -- accent for normal mode
  purple = '#ae81ff',
}

-- Helper to build a mode style
local function mode(a_bg)
  return {
    a = { fg = p.bg, bg = a_bg, gui = 'bold' },
    b = { fg = p.fg, bg = p.cursorln },
    c = { fg = p.comment, bg = p.surface },
  }
end

M.normal = mode(p.aqua) -- NORMAL → aqua/blue-ish
M.insert = mode(p.green) -- INSERT → green
M.visual = mode(p.purple) -- VISUAL → purple
M.replace = mode(p.pink) -- REPLACE → Monokai pink (keywords)
M.command = mode(p.yellow) -- COMMAND → yellow
M.terminal = mode(p.orange)

M.inactive = {
  a = { fg = p.comment, bg = p.bg_alt, gui = 'bold' },
  b = { fg = p.comment, bg = p.bg_alt },
  c = { fg = p.comment, bg = p.bg_alt },
}

return M
