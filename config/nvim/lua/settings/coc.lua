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
  -- vim.api.nvim_set_keymap("i", "<TAB>",
  --   [[coc#pum#visible() ? coc#pum#next(1) : CheckBackspace() ? "\<Tab>" : coc#refresh()]],
  --   { noremap = true, silent = true, expr = true })
  -- vim.api.nvim_set_keymap("i", "<S-TAB>",
  --   [[coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"]],
  --   { noremap = true, silent = true, expr = true })
  -- vim.api.nvim_set_keymap("i", "<CR>",
  --   [[coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"]],
  --   { noremap = true, silent = true, expr = true })
  --
  -- vim.api.nvim_set_keymap("n", "<F12>", "<Plug>(coc-definition)", { silent = true })
  -- vim.api.nvim_set_keymap("n", "gd", "<Plug>(coc-definition)", { silent = true })
  -- vim.api.nvim_set_keymap("n", "gi", "<Plug>(coc-implementation)", { silent = true })
  -- vim.api.nvim_set_keymap("n", "gr", "<Plug>(coc-references)", { silent = true })

  -- Set up an autocommand to trigger highlight on cursor hold
  vim.api.nvim_create_autocmd("CursorHold", {
    pattern = "*",
    callback = function()
      vim.fn.CocActionAsync("highlight")
    end,
  })

  -- Global extensions for coc.nvim
  -- vim.g.coc_global_extensions = {
  --   'coc-tsserver',   -- TypeScript and JavaScript support
  --   'coc-eslint',     -- Linting
  --   'coc-prettier',   -- Formatting
  -- }

  -- Key mappings for coc.nvim

  local keyset = vim.keymap.set

  -- Autocomplete
  function _G.check_back_space()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      if col == 0 then
    return true
      else
    local line = vim.api.nvim_get_current_line()
    local char = line:sub(col, col)
    return char:match('%s') ~= nil
      end
  end

  local opts = {silent = true, noremap = true, expr = true, replace_keycodes = false}
  keyset("i", "<Tab>", 'coc#pum#visible() ? coc#pum#confirm() : v:lua.check_back_space() ? "<Tab>" : coc#refresh()', opts)
  keyset("i", "<S-Tab>", 'coc#pum#visible() ? coc#pum#cancel() : "<C-h>"', opts)

  -- GoTo code navigation
  keyset("n", "gd", "<Plug>(coc-definition)", {silent = true})
  keyset("n", "gy", "<Plug>(coc-type-definition)", {silent = true})
  keyset("n", "gi", "<Plug>(coc-implementation)", {silent = true})
  keyset("n", "gr", "<Plug>(coc-references)", {silent = true})

  -- Show documentation
  function _G.show_docs()
    local cw = vim.fn.expand('<cword>')
    if vim.bo.filetype == 'vim' or vim.bo.filetype == 'help' then
      vim.cmd('h ' .. cw)
    elseif vim.fn['coc#rpc#ready']() then
      vim.fn.CocActionAsync('doHover')
    else
      vim.cmd('!' .. vim.o.keywordprg .. ' ' .. cw)
    end
  end
  keyset("n", "K", '<CMD>lua _G.show_docs()<CR>', {silent = true})

  -- Symbol renaming
  keyset("n", "<leader>rn", "<Plug>(coc-rename)", {silent = true})

  -- Formatting selected code
  keyset("x", "<leader>f", "<Plug>(coc-format-selected)", {silent = true})
  keyset("n", "<leader>f", "<Plug>(coc-format-selected)", {silent = true})

  -- Setup format on save
  vim.cmd([[
    augroup fmt
      autocmd!
      autocmd BufWritePre *.js,*.jsx,*.ts,*.tsx,*.json silent! call CocAction('format')
    augroup END
  ]])

  -- Update signature help on jump placeholder
  vim.cmd('autocmd User CocJumpPlaceholder call CocActionAsync("showSignatureHelp")')

end

return M
