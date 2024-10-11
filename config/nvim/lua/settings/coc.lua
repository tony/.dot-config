-- lua/settings/coc.lua

local M = {}

function M.setup()
  -- Global CoC extensions configuration
  vim.g.coc_global_extensions = {
    "coc-json",
    "coc-pyright",
    "coc-tsserver",
    "coc-rust-analyzer",
    "coc-prettier",
    "coc-yaml",
    "coc-toml",
    "coc-git",
    "coc-lists",
    "coc-eslint",
    "coc-biome",
  }

  -- Remap keys for CoC functionality
  vim.api.nvim_set_keymap("i", "<TAB>",
    [[coc#pum#visible() ? coc#pum#next(1) : CheckBackspace() ? "\<Tab>" : coc#refresh()]],
    { noremap = true, silent = true, expr = true })
  vim.api.nvim_set_keymap("i", "<S-TAB>",
    [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]],
    { noremap = true, silent = true, expr = true })
  vim.api.nvim_set_keymap("i", "<CR>",
    [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]],
    { noremap = true, silent = true, expr = true })

  vim.api.nvim_set_keymap("n", "<F12>", "<Plug>(coc-definition)", { silent = true })
  vim.api.nvim_set_keymap("n", "gd", "<Plug>(coc-definition)", { silent = true })
  vim.api.nvim_set_keymap("n", "gi", "<Plug>(coc-implementation)", { silent = true })
  vim.api.nvim_set_keymap("n", "gr", "<Plug>(coc-references)", { silent = true })

  -- Set up an autocommand to trigger highlight on cursor hold
  vim.api.nvim_create_autocmd("CursorHold", {
    pattern = "*",
    callback = function()
      vim.fn.CocActionAsync("highlight")
    end,
  })
end

return M
