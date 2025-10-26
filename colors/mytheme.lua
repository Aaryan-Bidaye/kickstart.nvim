-- colors/mytheme.lua
-- Monokai-inspired Neovim colorscheme with transparent popups and floating windows.

vim.o.termguicolors = true
vim.cmd 'highlight clear'
if vim.fn.exists 'syntax_on' == 1 then
  vim.cmd 'syntax reset'
end
vim.o.background = 'dark'
vim.g.colors_name = 'mytheme'

local p = {
  bg = '#272822',
  bg_alt = '#1f201c',
  surface = '#2e2f29',
  cursorln = '#32342c',
  selection = '#49483e',
  border = '#3a3b35',

  fg = '#f8f8f2',
  muted = '#a6a69c',
  comment = '#75715e',

  pink = '#f92672', -- Monokai keyword red/pink
  orange = '#fd971f',
  yellow = '#e6db74',
  green = '#a6e22e',
  aqua = '#66d9ef', -- cyan/blue-ish in this palette
  purple = '#ae81ff',
  red = '#ff5555',

  info = '#66d9ef',
  warn = '#e6db74',
  error = '#f92672',
  hint = '#a6e22e',
  success = '#a6e22e',

  diff_add = '#113311',
  diff_change = '#102a3a',
  diff_delete = '#341a1a',
  diff_text = '#1d3f55',
}

local O = {
  transparent = vim.g.mytheme_transparent == true,
  italic = vim.g.mytheme_italic ~= false,
  bold = vim.g.mytheme_bold ~= false,
  dim_inactive = vim.g.mytheme_dim_inactive == true,
}

local NONE = 'NONE'
local bg = O.transparent and NONE or p.bg
local function hi(g, s)
  vim.api.nvim_set_hl(0, g, s)
end

-- UI
hi('Normal', { fg = p.fg, bg = bg })
hi('NormalNC', { fg = p.fg, bg = O.dim_inactive and p.bg_alt or bg })
hi('NormalFloat', { fg = p.fg, bg = NONE })
hi('FloatBorder', { fg = p.border, bg = NONE })
hi('WinSeparator', { fg = p.border })
hi('CursorLine', { bg = p.cursorln })
hi('Visual', { bg = p.selection })
hi('LineNr', { fg = p.comment, bg = bg })
hi('CursorLineNr', { fg = p.yellow, bg = p.cursorln, bold = O.bold })
hi('SignColumn', { fg = p.comment, bg = bg })
hi('StatusLine', { fg = p.fg, bg = p.surface })
hi('StatusLineNC', { fg = p.muted, bg = p.bg_alt })
-- Terminal statusline variant: make text black as requested
hi('StatusLineTerm', { fg = '#000000', bg = p.surface })
hi('StatusLineTermNC', { fg = '#000000', bg = p.bg_alt })

hi('Pmenu', { fg = p.fg, bg = NONE })
hi('PmenuSel', { fg = p.bg, bg = p.green })
hi('PmenuSbar', { bg = NONE })
hi('PmenuThumb', { bg = p.border })
hi('Search', { fg = p.bg, bg = p.orange })
hi('IncSearch', { fg = p.bg, bg = p.pink })
hi('MatchParen', { fg = p.orange, bold = true })
hi('Folded', { fg = p.comment, bg = p.selection })
hi('Whitespace', { fg = p.border })

-- Dedicated yank highlight group (TokyoNight-like orange)
hi('YankHighlight', { fg = p.bg, bg = p.orange })

-- Syntax
hi('Comment', { fg = p.comment, italic = O.italic })
hi('String', { fg = p.yellow })
hi('Character', { fg = p.yellow })
hi('Number', { fg = p.purple })
hi('Float', { fg = p.purple })
hi('Boolean', { fg = p.purple })
hi('Identifier', { fg = p.fg })
hi('Function', { fg = p.green, bold = O.bold })
hi('Keyword', { fg = p.pink, italic = O.italic })
hi('Operator', { fg = p.pink })
hi('Statement', { fg = p.pink })
hi('Type', { fg = p.aqua })
hi('Constant', { fg = p.purple })
hi('PreProc', { fg = p.aqua })
hi('Special', { fg = p.orange })
hi('Todo', { fg = p.orange, bold = O.bold })
hi('Error', { fg = p.error, bold = O.bold })
hi('WarningMsg', { fg = p.warn })

-- Diagnostics
hi('DiagnosticError', { fg = p.error })
hi('DiagnosticWarn', { fg = p.warn })
hi('DiagnosticInfo', { fg = p.info })
hi('DiagnosticHint', { fg = p.hint })
hi('DiagnosticOk', { fg = p.success })
hi('DiagnosticUnderlineError', { undercurl = true, sp = p.error })
hi('DiagnosticUnderlineWarn', { undercurl = true, sp = p.warn })
hi('DiagnosticUnderlineInfo', { undercurl = true, sp = p.info })
hi('DiagnosticUnderlineHint', { undercurl = true, sp = p.hint })

-- Treesitter
hi('@comment', { fg = p.comment, italic = O.italic })
hi('@string', { fg = p.yellow })
hi('@character', { fg = p.yellow })
hi('@number', { fg = p.purple })
hi('@boolean', { fg = p.purple })
hi('@float', { fg = p.purple })
hi('@constant', { fg = p.purple })
hi('@constant.builtin', { fg = p.aqua })
hi('@variable', { fg = p.fg })
hi('@variable.builtin', { fg = p.orange })
hi('@field', { fg = p.fg })
hi('@property', { fg = p.fg })
hi('@parameter', { fg = p.fg })
hi('@function', { fg = p.green, bold = O.bold })
hi('@function.call', { fg = p.green })
hi('@function.builtin', { fg = p.green })
hi('@keyword', { fg = p.pink, italic = O.italic })
hi('@keyword.function', { fg = p.pink, italic = O.italic })
hi('@operator', { fg = p.pink })
hi('@type', { fg = p.aqua })
hi('@type.builtin', { fg = p.aqua })
hi('@tag', { fg = p.orange })
hi('@punctuation', { fg = p.muted })

-- Git / Diff / Plugins
hi('GitSignsAdd', { fg = p.green })
hi('GitSignsChange', { fg = p.aqua })
hi('GitSignsDelete', { fg = p.pink })
hi('DiffAdd', { bg = p.diff_add })
hi('DiffChange', { bg = p.diff_change })
hi('DiffDelete', { bg = p.diff_delete })
hi('DiffText', { bg = p.diff_text })

-- Telescope and popups (transparent)
hi('TelescopeNormal', { fg = p.fg, bg = NONE })
hi('TelescopeBorder', { fg = p.border, bg = NONE })
hi('TelescopeSelection', { fg = p.fg, bg = p.selection, bold = true })
hi('TelescopeMatching', { fg = p.orange, bold = true })
hi('TelescopePromptNormal', { fg = p.fg, bg = NONE })
hi('TelescopePromptBorder', { fg = p.border, bg = NONE })
hi('TelescopePromptPrefix', { fg = p.pink })

-- NvimTree (transparent popups)
hi('NvimTreeNormal', { fg = p.fg, bg = NONE })
hi('NvimTreeFolderName', { fg = p.aqua })
hi('NvimTreeOpenedFile', { fg = p.green })
hi('NvimTreeRootFolder', { fg = p.pink, bold = true })

-- Terminal colors
-- swap BLUE (index 4) with Monokai keyword red/pink, and move blue tone to RED (index 1)
vim.g.terminal_color_0 = p.bg
vim.g.terminal_color_1 = p.aqua -- was p.pink; now blue-ish goes to "red" slot
vim.g.terminal_color_2 = p.green
vim.g.terminal_color_3 = p.yellow
vim.g.terminal_color_4 = p.pink -- BLUE slot now uses Monokai keyword red/pink
vim.g.terminal_color_5 = p.purple
vim.g.terminal_color_6 = '#66cccc'
vim.g.terminal_color_7 = p.fg
vim.g.terminal_color_8 = p.comment
vim.g.terminal_color_9 = p.red -- bright red remains a conventional fallback
vim.g.terminal_color_10 = p.green
vim.g.terminal_color_11 = p.orange
vim.g.terminal_color_12 = p.pink -- bright blue follows the swap too
vim.g.terminal_color_13 = p.purple
vim.g.terminal_color_14 = p.aqua
vim.g.terminal_color_15 = '#ffffff'
