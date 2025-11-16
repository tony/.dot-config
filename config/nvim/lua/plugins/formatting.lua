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

local function has_config(path, patterns)
  if not path or path == '' then
    return false
  end
  return vim.fs.find(patterns, { upward = true, path = path })[1] ~= nil
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

      set_formatter_condition(opts.formatters, 'biome', function(_, ctx)
        return has_config(ctx.dirname, biome_configs)
      end)

      set_formatter_condition(opts.formatters, 'prettier', function(_, ctx)
        return has_config(ctx.dirname, prettier_configs)
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
            return utils.root_has_file(patterns)
          end,
        }))
      end

      enable(nls.builtins.formatting.biome, biome_configs)
      enable(nls.builtins.formatting.prettier, prettier_configs)
    end,
  },
}
