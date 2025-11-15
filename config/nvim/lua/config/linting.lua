local M = {}

local lint = require('lint')

local function pick_eslint()
  if vim.fn.executable('eslint_d') == 1 then
    return 'eslint_d'
  end
  if vim.fn.executable('eslint') == 1 then
    return 'eslint'
  end
end

local function ensure_ts_linters()
  local eslint = pick_eslint()
  if eslint then
    lint.linters_by_ft.javascript = { eslint }
    lint.linters_by_ft.javascriptreact = { eslint }
    lint.linters_by_ft.typescript = { eslint }
    lint.linters_by_ft.typescriptreact = { eslint }
    lint.linters_by_ft.vue = { eslint }
  else
    lint.linters_by_ft.javascript = nil
    lint.linters_by_ft.javascriptreact = nil
    lint.linters_by_ft.typescript = nil
    lint.linters_by_ft.typescriptreact = nil
    lint.linters_by_ft.vue = nil
  end
end

function M.setup()
  lint.linters_by_ft = lint.linters_by_ft or {}

  lint.linters_by_ft.python = { 'ruff', 'mypy' }
  lint.linters_by_ft.markdown = { 'markdownlint' }
  lint.linters_by_ft.json = { 'jsonlint' }
  lint.linters_by_ft.jsonc = { 'jsonlint' }
  lint.linters_by_ft.sh = { 'shellcheck' }

  ensure_ts_linters()

  if lint.linters.mypy then
    lint.linters.mypy.args = { '--hide-error-codes', '--hide-error-context', '--show-column-numbers', '%filepath%' }
    lint.linters.mypy.stdin = false
    lint.linters.mypy.condition = function()
      return vim.fn.executable('mypy') == 1
    end
  end

  if lint.linters.ruff then
    lint.linters.ruff.args = { 'check', '--stdin-filename', '%filepath%', '--quiet', '--no-cache', '--exit-zero' }
    lint.linters.ruff.ignore_exitcode = true
    lint.linters.ruff.condition = function()
      return vim.fn.executable('ruff') == 1
    end
  end

  if lint.linters.shellcheck then
    lint.linters.shellcheck.condition = function()
      return vim.fn.executable('shellcheck') == 1
    end
  end

  if lint.linters.markdownlint then
    lint.linters.markdownlint.condition = function()
      return vim.fn.executable('markdownlint') == 1
    end
  end

  if lint.linters.jsonlint then
    lint.linters.jsonlint.condition = function()
      return vim.fn.executable('jsonlint') == 1
    end
  end

  local group = vim.api.nvim_create_augroup('nvim_lint_autocmds', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].buftype ~= '' then
        return
      end
      ensure_ts_linters()
      lint.try_lint(nil, { bufnr = args.buf })
    end,
  })

  vim.api.nvim_create_user_command('Lint', function()
    ensure_ts_linters()
    lint.try_lint()
  end, {})
end

return M
