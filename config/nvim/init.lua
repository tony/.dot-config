require('config.bootstrap')
require('config.options')
require('config.autocmds')
require('config.keymaps')
require('config.lazy')

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    require('config.colors').setup()
  end,
})
