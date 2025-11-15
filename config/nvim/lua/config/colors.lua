local M = {}

local schemes = {
  { name = 'tokyonight-night' },
  { name = 'tokyonight-moon' },
  { name = 'catppuccin-mocha' },
  { name = 'gruvbox' },
  {
    name = 'gruvbox-material',
    setup = function()
      vim.g.gruvbox_material_disable_italic_comment = 1
    end,
  },
  {
    name = 'everforest',
    setup = function()
      vim.g.everforest_background = 'hard'
      vim.g.everforest_transparent_background = 2
      vim.g.everforest_disable_italic_comment = 1
      vim.o.background = 'dark'
    end,
  },
  { name = 'desert-warm-256' },
}

function M.setup()
  for _, entry in ipairs(schemes) do
    if entry.setup then
      entry.setup()
    end
    local ok = pcall(vim.cmd.colorscheme, entry.name)
    if ok then
      vim.api.nvim_set_hl(0, 'SpellBad', { undercurl = true, sp = '#ff0000' })
      return
    end
  end

  vim.cmd.colorscheme('desert')
  vim.api.nvim_set_hl(0, 'SpellBad', { undercurl = true, sp = '#ff0000' })
end

return M
