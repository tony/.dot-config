local lazyvim_path = vim.fn.expand('~/study/vim/LazyVim')
local spec = {}

if vim.loop.fs_stat(lazyvim_path) then
  table.insert(spec, { dir = lazyvim_path, import = 'lazyvim.plugins' })
else
  table.insert(spec, { 'LazyVim/LazyVim', import = 'lazyvim.plugins' })
end

local extras = {
  { import = 'lazyvim.plugins.extras.editor.telescope' },
  { import = 'lazyvim.plugins.extras.editor.snacks_explorer' },
  { import = 'lazyvim.plugins.extras.lang.typescript' },
  { import = 'lazyvim.plugins.extras.lang.json' },
  { import = 'lazyvim.plugins.extras.lang.yaml' },
  { import = 'lazyvim.plugins.extras.lang.markdown' },
  { import = 'lazyvim.plugins.extras.lang.python' },
  { import = 'lazyvim.plugins.extras.formatting.black' },
  { import = 'lazyvim.plugins.extras.linting.eslint' },
  { import = 'lazyvim.plugins.extras.lsp.none-ls' },
  { import = 'lazyvim.plugins.extras.util.project' },
  { import = 'lazyvim.plugins.extras.ai.copilot' },
}

for _, entry in ipairs(extras) do
  table.insert(spec, entry)
end

table.insert(spec, { import = 'plugins' })

require('lazy').setup({
  spec = spec,
  defaults = {
    lazy = false,
    version = false,
  },
  install = {
    colorscheme = {
      'tokyonight-night',
      'catppuccin',
      'everforest',
      'gruvbox-material',
      'desert-warm-256',
    },
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
