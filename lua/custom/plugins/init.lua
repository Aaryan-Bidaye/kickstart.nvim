-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {

  'christoomey/vim-tmux-navigator',
  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {},
    -- Optional dependencies
    dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
    --dependencies = { 'nvim-tree/nvim-web-devicons' }, -- use if you prefer nvim-web-devicons
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- optional, for icons
    event = 'VeryLazy', -- lazy-load so it’s available after startup
    config = function()
      local ok, lualine = pcall(require, 'lualine')
      if not ok then
        return
      end
      lualine.setup {
        options = {
          theme = 'auto',
          icons_enabled = true,
          globalstatus = true, -- single statusline across splits (nvim 0.7+)
        },
      }
    end,
  },
}
