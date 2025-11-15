local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local general = augroup('general_settings', { clear = true })

autocmd('FocusGained', {
  group = general,
  callback = function()
    vim.cmd('checktime')
    vim.cmd('redraw!')
  end,
})

autocmd('QuickFixCmdPost', {
  group = general,
  pattern = '*grep*',
  command = 'cwindow',
})

autocmd('FileType', {
  group = general,
  pattern = 'netrw',
  callback = function()
    vim.opt_local.bufhidden = 'delete'
  end,
})

autocmd('FileType', {
  group = general,
  pattern = 'gitcommit',
  callback = function()
    vim.opt_local.spell = true
  end,
})

autocmd('FileType', {
  group = general,
  pattern = { 'git', 'gitcommit' },
  callback = function()
    vim.opt_local.foldmethod = 'syntax'
    vim.opt_local.foldlevel = 1
  end,
})

local indent_group = augroup('filetype_indents', { clear = true })

local indent_settings = {
  ['javascript,typescript,typescriptreact'] = { 2, true },
  ['typescript.tsx'] = { 2, true },
  ['html,mustache,ejs,erb,handlebars'] = { 2, true },
  ['css,scss,less'] = { 2, true },
  ['lua'] = { 2, true },
  ['yaml'] = { 2, true },
  ['vim'] = { 2, true, 8, 2 },
  ['sh,zsh,bash,fish'] = { 4, true },
  ['c,cpp,rust,go,php'] = { 4, true, nil, 4 },
  ['rst'] = { 4, true },
}

for patterns, config in pairs(indent_settings) do
  autocmd('FileType', {
    group = indent_group,
    pattern = vim.split(patterns, ',', { trimempty = true }),
    callback = function()
      local shift = config[1]
      local expand = config[2]
      local tabstop = config[3] or shift
      local soft = config[4] or shift
      local opt_local = vim.opt_local
      opt_local.shiftwidth = shift
      opt_local.tabstop = tabstop
      opt_local.softtabstop = soft
      opt_local.expandtab = expand
    end,
  })
end

autocmd('FileType', {
  group = indent_group,
  pattern = 'rst',
  callback = function()
    vim.opt_local.formatoptions:append({ 'n', 'q', 't' })
    vim.opt_local.textwidth = 74
  end,
})

autocmd('FileType', {
  group = indent_group,
  pattern = 'markdown',
  callback = function()
    vim.opt_local.textwidth = 80
  end,
})

autocmd({ 'BufNewFile', 'BufRead' }, {
  group = general,
  pattern = { '*.ejs', '*.jst' },
  callback = function()
    vim.opt_local.filetype = 'html'
  end,
})

autocmd({ 'BufNewFile', 'BufRead' }, {
  group = general,
  pattern = '*.handlebars',
  callback = function()
    vim.opt_local.filetype = 'html'
  end,
})

autocmd({ 'BufNewFile', 'BufRead' }, {
  group = general,
  pattern = { '*.tmpl', '*.jinja', '*.jinja2' },
  callback = function()
    vim.opt_local.filetype = 'jinja'
  end,
})

autocmd({ 'BufNewFile', 'BufRead' }, {
  group = general,
  pattern = '*.py_tmpl',
  callback = function()
    vim.opt_local.filetype = 'python'
  end,
})

autocmd('BufWritePost', {
  group = general,
  pattern = { '.Xdefaults', '.Xresources' },
  callback = function(args)
    vim.fn.jobstart({ 'xrdb', '-load', args.file }, { detach = true })
  end,
})

autocmd('TextYankPost', {
  group = general,
  callback = function()
    vim.highlight.on_yank({ higroup = 'Visual', timeout = 120 })
  end,
})
