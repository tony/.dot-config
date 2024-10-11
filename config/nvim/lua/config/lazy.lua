-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("lazy").setup({
  -- Only load ag.vim if ag is installed
  {
    "rking/ag.vim",
    cond = function() return vim.fn.executable("ag") == 1 end,
  },

  -- Simple plugins
  "qpkorr/vim-bufkill",
  "editorconfig/editorconfig-vim",

  -- FZF configuration with post-installation script
  {
    "junegunn/fzf",
    dir = "~/.fzf",
    build = "./install --all --no-update-rc",
  },
  "junegunn/fzf.vim",

  -- Load vim-toml when pipenv is available
  {
    "cespare/vim-toml",
    cond = function() return vim.fn.executable("pipenv") == 1 end,
    config = function()
      vim.cmd([[
        au BufNewFile,BufRead Pipfile setf toml
        au BufNewFile,BufRead Pipfile.lock setf json
      ]])
    end,
  },

  -- Other filetype and utility plugins
  "GutenYe/json5.vim",
  {
    "ekalinin/Dockerfile.vim",
    cond = function() return vim.fn.executable("docker") == 1 end,
  },

  -- Git-related plugins (conditional on git executable)
  {
    "tpope/vim-fugitive",
    cond = function() return vim.fn.executable("git") == 1 end,
  },
  {
    "iberianpig/tig-explorer.vim",
    cond = function() return vim.fn.executable("git") == 1 end,
  },

  -- SQL plugin for PostgreSQL
  {
    "lifepillar/pgsql.vim",
    cond = function() return vim.fn.executable("psql") == 1 end,
  },

  -- Utility plugins for Unix-like commands
  "tpope/vim-eunuch",

  -- ALE for linting and fixing
  {
    "dense-analysis/ale",
    config = function()
      vim.g.ale_linters_explicit = 1
      vim.g.ale_set_highlights = 0
    end,
  },

  -- Commenting plugins
  "tomtom/tcomment_vim",
  {
    "mustache/vim-mustache-handlebars",
    ft = {"html", "mustache", "hbs"},
  },

  -- Markdown plugins
  {
    "tpope/vim-markdown",
    ft = {"markdown"},
  },
  "airblade/vim-rooter",
  {
    "justinmk/vim-syntax-extra",
    ft = {"c", "cpp"},
  },
  "chaoren/vim-wordmotion",

  -- Color schemes
  "rainux/vim-desert-warm-256",
  "morhetz/gruvbox",
  -- Gruvbox-material is commented out but can be added similarly
  -- "gruvbox-material/vim", {as = 'gruvbox-material'},
  "sainnhe/sonokai",
  "sainnhe/everforest",
  {
    "catppuccin/vim",
    as = "catppuccin",
  },

  -- CoC plugin setup
  {
    "neoclide/coc.nvim",
    branch = "master",
    build = "yarn install --frozen-lockfile",
    config = function()
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

      -- CoC keybindings and auto commands
      vim.cmd([[
        function! OnLoadCoc()
          " Remap keys for CoC functionality
          inoremap <silent><expr> <TAB> coc#pum#visible() ? coc#pum#next(1) : CheckBackspace() ? "\<Tab>" : coc#refresh()
          inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
          inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

          nnoremap <silent> <F12> <Plug>(coc-definition)
          nnoremap <silent> gd <Plug>(coc-definition)
          nnoremap <silent> gi <Plug>(coc-implementation)
          nnoremap <silent> gr <Plug>(coc-references)

          autocmd CursorHold * silent call CocActionAsync('highlight')
        endfunction

        call OnLoadCoc()
      ]])
    end,
  },

  -- Other plugins (quickfix, syntax highlighting, etc.)
  "yssl/QFEnter",
  "github/copilot.vim",
  "vim-python/python-syntax",
  {
    "frazrepo/vim-rainbow",
    config = function()
      vim.g.rainbow_active = 1
    end,
  },
  "preservim/nerdtree",
  "yasuhiroki/github-actions-yaml.vim",

  -- Auto formatters and file-specific setups
  {
    "vim-autoformat/vim-autoformat",
    config = function()
      vim.g.formatdef_dprint = '"dprint stdin-fmt --file-name ".@%'
      vim.g.formatters_json = {"dprint"}
      vim.g.formatters_toml = {"dprint"}
    end,
  },
  {
    "jparise/vim-graphql",
  },
  "cakebaker/scss-syntax.vim",

  -- Plugins based on executables (Node.js, Tmux, Cargo, etc.)
  {
    "leafgarland/typescript-vim",
    cond = function() return vim.fn.executable("node") == 1 end,
  },
  {
    "HerringtonDarkholme/yats.vim",
    cond = function() return vim.fn.executable("node") == 1 end,
  },
  {
    "posva/vim-vue",
    cond = function() return vim.fn.executable("node") == 1 end,
  },
  {
    "wellle/tmux-complete.vim",
    cond = function() return vim.fn.executable("tmux") == 1 end,
  },
  {
    "rust-lang/rust.vim",
    cond = function() return vim.fn.executable("cargo") == 1 end,
  },
  {
    "hashivim/vim-terraform",
    cond = function() return vim.fn.executable("terraform") == 1 end,
  },
  {
    "elixir-editors/vim-elixir",
    cond = function() return vim.fn.executable("mix") == 1 end,
  },

  -- Wilder.nvim for advanced command-line completion
  {
    "gelguy/wilder.nvim",
    build = function()
      vim.cmd("UpdateRemotePlugins")
    end,
    cond = function() return vim.fn.has("nvim") == 1 end,
  },
})
