return {
  { 'tpope/vim-fugitive' },
  -- { -- Adds git related signs to the gutter, as well as utilities for managing changes
  --   'lewis6991/gitsigns.nvim',
  --   opts = {
  --     signs = {
  --       add = { text = '+' },
  --       change = { text = '~' },
  --       delete = { text = '_' },
  --       topdelete = { text = '‾' },
  --       changedelete = { text = '~' },
  --     },
  --   },
  --   config = function()
  --     require('gitsigns').setup()
  --
  --     vim.keymap.set('n', '<leader>gp', ':Gitsigns preview_hunk<CR>', { desc = '[G]it [P]review hunk' })
  --     vim.keymap.set('n', '<leader>gt', ':Gitsigns toggle_current_line_blame<CR>', { desc = '[G]it [T]oggle blame' })
  --   end,
  -- },
  --
  { -- Lazygit for git management
    'kdheepak/lazygit.nvim',
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
    },
    config = function()
      require('telescope').load_extension 'lazygit'
      vim.keymap.set('n', '<leader>gg', '<cmd>LazyGit<CR>', { desc = 'Open LazyGit' })
    end,
  },
}
