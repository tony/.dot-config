return {
  { 'folke/tokyonight.nvim', lazy = false, priority = 1000 },
  { 'catppuccin/nvim', name = 'catppuccin', priority = 999 },
  { 'sainnhe/everforest' },
  { 'morhetz/gruvbox' },
  { 'sainnhe/gruvbox-material' },
  { 'rainux/vim-desert-warm-256' },
  { 'sainnhe/sonokai' },

  { 'editorconfig/editorconfig-vim', event = 'VeryLazy' },
  { 'tpope/vim-eunuch', cmd = { 'Rename', 'Move', 'Delete', 'Chmod', 'Mkdir' } },
  { 'GutenYe/json5.vim', ft = { 'json', 'json5' } },
  { 'jparise/vim-graphql', ft = { 'graphql' } },
  { 'cakebaker/scss-syntax.vim', ft = { 'scss' } },
  { 'yasuhiroki/github-actions-yaml.vim', ft = { 'yaml' } },
  { 'vim-python/python-syntax', ft = { 'python' } },
  { 'kevinhwang91/nvim-bqf', ft = 'qf' },
  { 'HiPhish/rainbow-delimiters.nvim', event = { 'BufReadPost', 'BufNewFile' } },
  { 'gelguy/wilder.nvim', event = 'CmdlineEnter', build = ':UpdateRemotePlugins', config = function() require('config.wilder').setup() end },
  {
    dir = vim.fn.expand('~/study/vim/claudecode.nvim'),
    name = 'claudecode.nvim',
    event = 'VeryLazy',
    dependencies = { 'folke/snacks.nvim' },
    opts = function()
      local claude_cmd = vim.fn.exepath('claude')
      local auto_start = true
      if claude_cmd == '' then
        claude_cmd = nil
        auto_start = false
        vim.schedule(function()
          vim.notify(
            'Claude Code CLI not found in PATH. Install it or set opts.terminal_cmd.',
            vim.log.levels.WARN,
            { title = 'ClaudeCode.nvim' }
          )
        end)
      end
      return {
        terminal_cmd = claude_cmd,
        auto_start = auto_start,
        focus_after_send = true,
      }
    end,
    config = function(_, opts)
      require('claudecode').setup(opts)
    end,
    keys = {
      { '<leader>a', nil, desc = 'Claude Code' },
      { '<leader>ac', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude terminal' },
      { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude terminal' },
      { '<leader>ar', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude session' },
      { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude session' },
      { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
      { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer to Claude' },
      { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send selection to Claude' },
      {
        '<leader>as',
        '<cmd>ClaudeCodeTreeAdd<cr>',
        ft = { 'netrw', 'NvimTree', 'neo-tree', 'oil', 'minifiles' },
        desc = 'Add file to Claude',
      },
      { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept Claude diff' },
      { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Reject Claude diff' },
      { '<leader>ao', '<cmd>ClaudeCodeOpen<cr>', desc = 'Open Claude terminal' },
      { '<leader>aq', '<cmd>ClaudeCodeClose<cr>', desc = 'Close Claude terminal' },
      { '<leader>ai', '<cmd>ClaudeCodeStatus<cr>', desc = 'Claude status' },
      { '<leader>aS', '<cmd>ClaudeCodeStart<cr>', desc = 'Start Claude backend' },
      { '<leader>aQ', '<cmd>ClaudeCodeStop<cr>', desc = 'Stop Claude backend' },
    },
  },
}
