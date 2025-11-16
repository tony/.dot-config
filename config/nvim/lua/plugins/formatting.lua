local prettier_configs = {
  '.prettierrc',
  '.prettierrc.json',
  '.prettierrc.js',
  '.prettierrc.cjs',
  '.prettierrc.mjs',
  '.prettierrc.ts',
  '.prettierrc.yaml',
  '.prettierrc.yml',
  '.prettierrc.toml',
  'prettier.config.js',
  'prettier.config.cjs',
  'prettier.config.mjs',
  'prettier.config.ts',
}

local biome_configs = {
  'biome.json',
  'biome.jsonc',
  'biome.config.json',
  'biome.config.ts',
  'biome.config.js',
  'biome.config.cjs',
  'biome.config.mjs',
}

local ruff_configs = {
  '.ruff.toml',
  'ruff.toml',
  { file = 'pyproject.toml', contains = '[tool.ruff' },
}

local function file_contains(path, needle)
  if not needle then
    return true
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return false
  end
  for _, line in ipairs(lines) do
    if line:find(needle, 1, true) then
      return true
    end
  end
  return false
end

local function find_file(path, target)
  local found = vim.fs.find(target, { upward = true, path = path })[1]
  return found
end

local function has_config(path, patterns)
  if not path or path == '' then
    return false
  end
  for _, entry in ipairs(patterns) do
    if type(entry) == 'string' then
      if find_file(path, entry) then
        return true
      end
    elseif type(entry) == 'table' and entry.file then
      local found = find_file(path, entry.file)
      if found and file_contains(found, entry.contains) then
        return true
      end
    end
  end
  return false
end

local function set_formatter_condition(formatters, name, predicate)
  local existing = formatters[name] or {}
  if existing.condition then
    local previous = existing.condition
    existing.condition = function(...)
      return previous(...) and predicate(...)
    end
  else
    existing.condition = predicate
  end
  formatters[name] = existing
end

local function add_formatter(formatters_by_ft, ft, formatter)
  formatters_by_ft[ft] = formatters_by_ft[ft] or {}
  if not vim.tbl_contains(formatters_by_ft[ft], formatter) then
    table.insert(formatters_by_ft[ft], formatter)
  end
end

return {
  {
    'stevearc/conform.nvim',
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters = opts.formatters or {}

      local biome_filetypes = {
        'astro',
        'css',
        'graphql',
        'javascript',
        'javascriptreact',
        'json',
        'jsonc',
        'svelte',
        'typescript',
        'typescriptreact',
        'vue',
      }

      for _, ft in ipairs(biome_filetypes) do
        add_formatter(opts.formatters_by_ft, ft, 'biome')
      end

      local prettier_filetypes = {
        'css',
        'graphql',
        'handlebars',
        'html',
        'javascript',
        'javascriptreact',
        'json',
        'jsonc',
        'less',
        'markdown',
        'markdown.mdx',
        'scss',
        'typescript',
        'typescriptreact',
        'vue',
        'yaml',
      }

      for _, ft in ipairs(prettier_filetypes) do
        add_formatter(opts.formatters_by_ft, ft, 'prettier')
      end

      add_formatter(opts.formatters_by_ft, 'python', 'ruff_format')

      set_formatter_condition(opts.formatters, 'biome', function(_, ctx)
        return has_config(ctx.dirname, biome_configs)
      end)

      set_formatter_condition(opts.formatters, 'prettier', function(_, ctx)
        return has_config(ctx.dirname, prettier_configs)
      end)

      set_formatter_condition(opts.formatters, 'ruff_format', function(_, ctx)
        return has_config(ctx.dirname, ruff_configs)
      end)
    end,
  },

  {
    'nvimtools/none-ls.nvim',
    opts = function(_, opts)
      local nls = require('null-ls')
      opts.sources = opts.sources or {}

      local function enable(source, patterns)
        if not source then
          return
        end
        table.insert(opts.sources, source.with({
          condition = function(utils)
            return has_config(utils.root, patterns)
          end,
        }))
      end

      enable(nls.builtins.formatting.biome, biome_configs)
      enable(nls.builtins.formatting.prettier, prettier_configs)
    end,
  },
}
