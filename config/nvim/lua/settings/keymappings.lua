-- lua/settings/keymappings.lua

-- Map leader and localleader key to comma
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Format / indent code
vim.keymap.set("n", "<leader>3", "gg=G", { silent = true })

-- Toggle paste mode
vim.keymap.set("n", "<leader>4", ":set paste!<CR>", { silent = true })

-- Delete into the blackhole register
vim.keymap.set("n", "d", '"_d')
vim.keymap.set("n", "dd", "dd")

-- Toggle relative number
local function number_relative_toggle()
  if vim.wo.relativenumber == false and vim.wo.number == false then
    print("Line numbers not enabled, use <leader>7 or :set number / :set relativenumber")
  elseif vim.wo.relativenumber == true then
    vim.wo.relativenumber = false
  else
    vim.wo.relativenumber = true
  end
end

vim.keymap.set("n", "<leader>6", number_relative_toggle, { silent = true })

-- Toggle number
local function number_toggle()
  vim.wo.relativenumber = false
  if vim.wo.number == true then
    vim.wo.number = false
  else
    vim.wo.number = true
  end
end

vim.keymap.set("n", "<leader>7", number_toggle, { silent = true })

-- Copy full path of the current file
vim.keymap.set("n", "<leader>p", function()
  local file_path = vim.fn.expand("%:p")
  vim.fn.setreg("+", file_path)
  print("Copied current file path: " .. file_path)
end, { silent = true })

-- Close window
vim.keymap.set("n", "Q", ":q<CR>", { silent = true })

-- Clear search highlighting and Coc completion window
local function clear_spam()
  vim.cmd("nohlsearch")
  if vim.fn["coc#pum#visible"]() then
    vim.fn["coc#pum#_close"]()
  end
end

vim.keymap.set("n", "<c-c>", clear_spam, { silent = true })

-- Visual mode key mappings
vim.keymap.set("v", "<c-r>", '"hy:%s/<C-r>h//gc<left><left><left>', { silent = true })
vim.keymap.set("v", "<CR>", 'y:let @/ = @"<CR>:set hlsearch<CR>', { silent = true })
vim.keymap.set("v", "<BS>", "c", { silent = true })
vim.keymap.set("x", "<", "<gv", { silent = true })
vim.keymap.set("x", ">", ">gv", { silent = true })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { silent = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { silent = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { silent = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { silent = true })
vim.keymap.set("n", "<C-=>", "<C-w>=", { silent = true })

-- Buffer navigation
vim.keymap.set("n", ";]", ":bnext<CR>", { silent = true })
vim.keymap.set("n", "<leader>]", ":bnext<CR>", { silent = true })
vim.keymap.set("n", ";[", ":bprev<CR>", { silent = true })
vim.keymap.set("n", "<leader>[", ":bprev<CR>", { silent = true })

-- NERDTree
vim.keymap.set("n", "<leader>e", ":NERDTreeFocus<CR>", { silent = true })
