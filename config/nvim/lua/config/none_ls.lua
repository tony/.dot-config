local M = {}

function M.setup()
  local null_ls = require('null-ls')
  local helpers = require('null-ls.helpers')
  local methods = require('null-ls.methods')
  local formatting = null_ls.builtins.formatting
  local augroup = vim.api.nvim_create_augroup('NoneLSFormat', { clear = true })

  local format_on_save = {
    javascript = true,
    javascriptreact = true,
    typescript = true,
    typescriptreact = true,
    json = true,
    jsonc = true,
    toml = true,
    markdown = true,
    python = true,
  }

  local ruff_format = helpers.make_builtin({
    name = 'ruff_format',
    method = methods.internal.FORMATTING,
    filetypes = { 'python' },
    generator_opts = {
      command = 'ruff',
      args = { 'format', '--stdin-filename', '$FILENAME', '-' },
      to_stdin = true,
    },
    factory = helpers.formatter_factory,
    meta = {
      url = 'https://docs.astral.sh/ruff/',
      description = 'Fast Python formatter provided by Ruff.',
    },
  })

  null_ls.setup({
    debounce = 250,
    sources = {
      formatting.biome,
      formatting.prettierd.with({
        condition = function()
          return vim.fn.executable('prettierd') == 1
        end,
      }),
      formatting.prettier.with({
        condition = function()
          return vim.fn.executable('prettier') == 1
        end,
      }),
      formatting.black.with({
        condition = function()
          return vim.fn.executable('black') == 1
        end,
        extra_args = { '--quiet' },
      }),
      formatting.isort.with({
        condition = function()
          return vim.fn.executable('isort') == 1
        end,
      }),
      ruff_format.with({
        condition = function()
          return vim.fn.executable('ruff') == 1
        end,
      }),
      formatting.shfmt.with({
        condition = function()
          return vim.fn.executable('shfmt') == 1
        end,
        extra_args = { '-i', '2' },
      }),
    },
    on_attach = function(client, bufnr)
      if not client.supports_method('textDocument/formatting') then
        return
      end

      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = augroup,
        buffer = bufnr,
        callback = function()
          if format_on_save[vim.bo[bufnr].filetype] then
            vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 4000 })
          end
        end,
      })
    end,
  })

  vim.api.nvim_create_user_command('Format', function(args)
    vim.lsp.buf.format({ async = args.bang == true })
  end, { bang = true })
end

return M
