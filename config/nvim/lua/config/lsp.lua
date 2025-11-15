local M = {}

local function diagnostic_signs()
  local signs = { Error = '', Warn = '', Hint = '', Info = '' }
  for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
  end
end

diagnostic_signs()

local function on_attach(client, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  map('n', 'gd', vim.lsp.buf.definition, 'Goto definition')
  map('n', 'gD', vim.lsp.buf.declaration, 'Goto declaration')
  map('n', 'gr', vim.lsp.buf.references, 'References')
  map('n', 'gi', vim.lsp.buf.implementation, 'Goto implementation')
  map('n', 'K', vim.lsp.buf.hover, 'Hover')
  map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
  map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
  map('n', '<leader>cf', function() vim.lsp.buf.format({ async = true }) end, 'Format')
  map('n', '[d', vim.diagnostic.goto_prev, 'Prev diagnostic')
  map('n', ']d', vim.diagnostic.goto_next, 'Next diagnostic')
  map('n', '<leader>ds', function()
    require('telescope.builtin').lsp_document_symbols()
  end, 'Document symbols')
  map('n', '<leader>ws', function()
    require('telescope.builtin').lsp_dynamic_workspace_symbols()
  end, 'Workspace symbols')
  map('n', '<leader>dl', vim.diagnostic.open_float, 'Line diagnostics')

  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  if client.server_capabilities.documentHighlightProvider then
    local group = vim.api.nvim_create_augroup('lsp_document_highlight_' .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
      group = group,
      buffer = bufnr,
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'BufLeave' }, {
      group = group,
      buffer = bufnr,
      callback = vim.lsp.buf.clear_references,
    })
  end
end

function M.setup()
  local lspconfig = require('lspconfig')
  local mason = require('mason')
  local mason_lspconfig = require('mason-lspconfig')
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  mason.setup({
    ui = {
      border = 'rounded',
    },
  })

  local servers = { 'lua_ls', 'pyright', 'jsonls', 'yamlls', 'bashls', 'tsserver' }

  mason_lspconfig.setup({
    ensure_installed = vim.deepcopy(servers),
    automatic_installation = false,
    automatic_enable = false,
  })

  local function disable_format(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end

  local function setup_server(server)
    local function server_on_attach(client, bufnr)
      on_attach(client, bufnr)
      if client.name == 'lua_ls' or client.name == 'pyright' or client.name == 'tsserver' then
        disable_format(client)
      end
      if client.name == 'tsserver' then
        vim.api.nvim_buf_create_user_command(bufnr, 'TSCOrganizeImports', function()
          vim.lsp.buf.execute_command({
            command = '_typescript.organizeImports',
            arguments = { vim.api.nvim_buf_get_name(bufnr) },
          })
        end, { desc = 'Organize TypeScript imports' })
      end
    end

    local opts = {
      on_attach = server_on_attach,
      capabilities = capabilities,
    }

    if server == 'lua_ls' then
      opts.settings = {
        Lua = {
          runtime = {
            version = 'LuaJIT',
          },
          diagnostics = {
            globals = { 'vim' },
          },
          workspace = {
            checkThirdParty = false,
          },
          telemetry = {
            enable = false,
          },
        },
      }
    elseif server == 'pyright' then
      opts.settings = {
        python = {
          analysis = {
            typeCheckingMode = 'basic',
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = 'openFilesOnly',
          },
        },
      }
    elseif server == 'jsonls' then
      local ok, schemastore = pcall(require, 'schemastore')
      opts.settings = {
        json = {
          schemas = ok and schemastore.json.schemas() or nil,
          validate = { enable = true },
        },
      }
    elseif server == 'yamlls' then
      local ok, schemastore = pcall(require, 'schemastore')
      opts.settings = {
        yaml = {
          schemaStore = {
            enable = false,
            url = '',
          },
          schemas = ok and schemastore.yaml.schemas() or nil,
        },
      }
    elseif server == 'tsserver' then
      opts.settings = {
        typescript = {
          format = {
            enable = false,
          },
        },
        javascript = {
          format = {
            enable = false,
          },
        },
      }
    end

    lspconfig[server].setup(opts)
  end

  for _, server in ipairs(servers) do
    setup_server(server)
  end

  vim.diagnostic.config({
    virtual_text = false,
    severity_sort = true,
    float = {
      border = 'rounded',
      source = 'if_many',
    },
  })
end

return M
