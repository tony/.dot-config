local lazyvim_path = vim.fn.expand('~/study/vim/LazyVim')
local lazyvim_spec

if vim.loop.fs_stat(lazyvim_path) then
  lazyvim_spec = { dir = lazyvim_path, name = 'LazyVim', import = 'lazyvim.plugins', opts = {} }
else
  lazyvim_spec = { 'LazyVim/LazyVim', import = 'lazyvim.plugins', opts = {} }
end

require('lazy').setup({
  spec = {
    lazyvim_spec,
    { import = 'lazyvim.plugins.extras.editor.telescope' },
    { import = 'lazyvim.plugins.extras.editor.snacks_explorer' },
    { import = 'lazyvim.plugins.extras.lang.typescript' },
    { import = 'lazyvim.plugins.extras.lang.json' },
    { import = 'lazyvim.plugins.extras.lang.yaml' },
    { import = 'lazyvim.plugins.extras.lang.markdown' },
    { import = 'lazyvim.plugins.extras.lang.python' },
    { import = 'lazyvim.plugins.extras.formatting.biome' },
    { import = 'lazyvim.plugins.extras.formatting.black' },
    { import = 'lazyvim.plugins.extras.formatting.prettier' },
    { import = 'lazyvim.plugins.extras.linting.eslint' },
    { import = 'lazyvim.plugins.extras.lsp.none-ls' },
    { import = 'lazyvim.plugins.extras.util.project' },
    { import = 'lazyvim.plugins.extras.ai.copilot' },
    { import = 'plugins' },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = {
    colorscheme = { 'tokyonight-night', 'catppuccin', 'everforest', 'gruvbox-material', 'desert-warm-256' },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        'gzip',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
  change_detection = {
    notify = false,
  },
})
