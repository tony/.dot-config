local map = vim.keymap.set
local command = vim.api.nvim_create_user_command

local function with_desc(desc, extra)
  extra = extra or {}
  extra.desc = desc
  extra.silent = extra.silent ~= false
  extra.noremap = extra.noremap ~= false
  return extra
end

local function reindent_buffer()
  local view = vim.fn.winsaveview()
  vim.cmd('normal! gg=G')
  vim.fn.winrestview(view)
end

local function toggle_paste()
  vim.o.paste = not vim.o.paste
  vim.notify('paste mode: ' .. (vim.o.paste and 'ON' or 'off'), vim.log.levels.INFO)
end

local function copy_file_path()
  local path = vim.fn.expand('%:p')
  if path == '' then
    vim.notify('No file path available for this buffer', vim.log.levels.WARN)
    return
  end
  vim.fn.setreg('+', path)
  vim.notify("Copied current file path '" .. path .. "' to clipboard")
end

local function open_explorer()
  local snacks = rawget(_G, 'Snacks')
  if snacks and snacks.explorer then
    local ok, root = pcall(function()
      return rawget(_G, 'LazyVim') and LazyVim.root and LazyVim.root({ normalize = true })
    end)
    snacks.explorer({ cwd = ok and root or nil })
  else
    vim.cmd('Ex')
  end
end

local function require_lsp(action)
  return function()
    local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
    if #clients == 0 then
      vim.notify('No LSP attached to current buffer', vim.log.levels.WARN)
      return
    end
    action()
  end
end

command('BLines', function()
  local ok, err = pcall(vim.cmd.Telescope, 'current_buffer_fuzzy_find')
  if not ok then
    vim.notify('Telescope current_buffer_fuzzy_find failed: ' .. err, vim.log.levels.ERROR)
  end
end, { desc = 'Fuzzy search current buffer' })

command('BB', function()
  local ok, err = pcall(vim.cmd.Telescope, 'buffers')
  if not ok then
    vim.notify('Telescope buffers failed: ' .. err, vim.log.levels.ERROR)
  end
end, { desc = 'Buffer picker' })

command('BD', function(opts)
  local target = opts.args
  local bufnr
  if target ~= '' then
    bufnr = tonumber(target) or vim.fn.bufnr(target)
    if not bufnr or bufnr < 0 then
      vim.notify('Invalid buffer: ' .. target, vim.log.levels.WARN)
      return
    end
  end
  local snacks = rawget(_G, 'Snacks')
  if snacks and snacks.bufdelete then
    snacks.bufdelete(bufnr)
    return
  end
  if bufnr then
    vim.cmd(('bdelete %d'):format(bufnr))
  else
    vim.cmd('bdelete')
  end
end, { nargs = '?', complete = 'buffer', desc = 'Delete buffer' })

map('n', '<leader>3', reindent_buffer, with_desc('Reindent entire buffer'))
map('n', '<leader>f', reindent_buffer, with_desc('Reindent entire buffer'))
map('n', '<leader>4', toggle_paste, with_desc('Toggle paste mode'))
map('n', 'd', '"_d', with_desc('Delete without yanking'))
map('n', 'dd', 'dd', { noremap = true, silent = true })
map('x', 'd', '"_d', with_desc('Delete without yanking'))
map('x', 'p', '"_dP', with_desc('Paste without clobbering register'))
map('x', 'y', 'y`]', with_desc('Yank and keep selection boundary'))

map('n', '<leader>6', function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, with_desc('Toggle relative numbers'))

map('n', '<leader>7', function()
  vim.wo.number = not vim.wo.number
end, with_desc('Toggle absolute numbers'))

map('n', '<leader>b', '<cmd>BLines<CR>', with_desc('Search within buffer'))
map('n', '<leader>yp', copy_file_path, with_desc('Copy absolute file path'))
map('n', 'Q', '<cmd>quit<CR>', with_desc('Quit window'))

map({ 'n', 'v' }, '<C-c>', function()
  pcall(vim.cmd.nohlsearch)
  local ok, cmp = pcall(require, 'cmp')
  if ok then
    cmp.abort()
  end
end, with_desc('Clear highlights and close completion'))

map('v', '<C-r>', [["hy:%s/<C-r>h//gc<Left><Left><Left>]], with_desc('Search & replace selection', { noremap = true }))
map('v', '<C-s>', [[:s/\%V//g<Left><Left><Left>]], with_desc('Substitute inside selection', { noremap = true }))

map('x', '<CR>', [[y:let @/=@"<CR>:set hlsearch<CR>]], with_desc('Search visual selection', { silent = true }))
map('x', '<BS>', 'c', with_desc('Change selection', { silent = false }))
map('x', '<Tab>', '>', with_desc('Indent selection'))
map('x', '<S-Tab>', '<', with_desc('Unindent selection'))
map('x', '<', '<gv', with_desc('Indent left and reselect'))
map('x', '>', '>gv', with_desc('Indent right and reselect'))
map('x', '.', ':normal.<CR>', with_desc('Repeat last command', { silent = true }))
map('x', '@', ':normal@', with_desc('Replay macro across selection', { silent = false }))
map('x', '\\', function()
  local ok, api = pcall(require, 'Comment.api')
  if ok then
    api.toggle.linewise(vim.fn.visualmode())
  end
end, with_desc('Toggle selection comment'))

map('n', '<leader>x', '<cmd>Ex<CR>', with_desc('Open netrw explorer'))
map('n', '<leader>d', '<cmd>BD<CR>', with_desc('Delete current buffer'))
map('n', '<leader>p', '<cmd>bprevious<CR>', with_desc('Previous buffer', { nowait = true }))
map('n', '<leader>n', '<cmd>bnext<CR>', with_desc('Next buffer', { nowait = true }))
map('n', '<leader>]', '<cmd>bnext<CR>', with_desc('Next buffer (alt)'))
map('n', '<leader>[', '<cmd>bprevious<CR>', with_desc('Previous buffer (alt)'))
map('n', '<leader>c', '<cmd>BB<CR>', with_desc('Buffer picker'))
map('n', '<leader><BS>', '<cmd>BB<CR>', with_desc('Buffer picker (Backspace)'))
map('n', '<leader><Del>', '<cmd>BB<CR>', with_desc('Buffer picker (Delete)'))
map('n', '<leader>e', open_explorer, with_desc('Focus file explorer'))
map('n', '<leader>q', '<cmd>cwindow<CR>', with_desc('Open quickfix'))
map('n', '<C-q>', '<cmd>cclose<CR>', with_desc('Close quickfix'))
map('n', '<C-h>', '<C-w>h', with_desc('Move to left window'))
map('n', '<C-j>', '<C-w>j', with_desc('Move to lower window'))
map('n', '<C-k>', '<C-w>k', with_desc('Move to upper window'))
map('n', '<C-l>', '<C-w>l', with_desc('Move to right window'))
map('n', '<C-=>', '<C-w>=', with_desc('Equalize splits'))

local goto_definition = require_lsp(function()
  vim.lsp.buf.definition()
end)
local goto_type_definition = require_lsp(function()
  if vim.lsp.buf.type_definition then
    vim.lsp.buf.type_definition()
  else
    vim.lsp.buf.definition()
  end
end)
local goto_implementation = require_lsp(function()
  vim.lsp.buf.implementation()
end)
local goto_references = require_lsp(function()
  vim.lsp.buf.references()
end)

map('n', '<leader>g', goto_definition, with_desc('Goto definition (legacy ,g)'))
map('n', '<leader>G', goto_type_definition, with_desc('Goto type definition (legacy ,G)'))
map('n', '<C-t>', goto_definition, with_desc('Goto definition (legacy <C-t>)'))
map('n', '<F12>', goto_definition, with_desc('Goto definition (legacy <F12>)'))
map('n', '<C-F12>', goto_implementation, with_desc('Goto implementation (legacy <C-F12>)'))
map('n', '<S-F12>', goto_references, with_desc('Goto references (legacy <S-F12>)'))
