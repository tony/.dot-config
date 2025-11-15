local opt = vim.opt
local g = vim.g

g.mapleader = ','
g.maplocalleader = ','

g.loaded_matchparen = 1

g.editorconfig = true

opt.hidden = true
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.clipboard = vim.fn.has('unnamedplus') == 1 and 'unnamedplus' or 'unnamed'
opt.termguicolors = true
opt.timeoutlen = 400
opt.updatetime = 300
opt.signcolumn = 'yes'
opt.shortmess:append('c')
opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.list = true
opt.listchars = { tab = '▸ ', trail = '·', extends = '»', precedes = '«', nbsp = '+' }
opt.number = true
opt.relativenumber = false
opt.mouse = 'a'
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.wildmode = { 'list', 'longest', 'full' }
opt.foldenable = true
opt.fillchars:append({ eob = ' ' })
opt.background = 'dark'
opt.sessionoptions:remove('options')
