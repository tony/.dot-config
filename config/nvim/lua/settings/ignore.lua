-- ~/.config/nvim/lua/config/ignore.lua

local M = {}

-- Common ignore patterns
local common_ignores = {
  "*.o", "*.obj", "*~", "*.pyc", "*.swp", ".git", ".hg", ".svn",
  ".ropeproject", ".bzr", ".ipynb_checkpoints", "__pycache__",
  "*.egg", "*.egg-info", ".tox", ".idea", ".sass-cache", ".mypy_cache",
  ".ruff_cache", ".pytest_cache", ".env", ".env[0-9]", ".venv", ".venv[0-9]",
  ".coverage", ".tmp", ".gitkeep", ".vscode", ".splinter-screenshots",
  ".webassets-cache", ".vagrant", ".DS_Store", ".env-pypy", "*.debug.d",
  "*.debug.o", "vendor/rails/**", "vendor/cache/**", "*.gem", "log/**",
  "tmp/**", "*.png", "*.jpg", "*.gif", "*.so", "*.zip", "*/.Trash/**",
  "*.pdf", "*.dmg", "*/Library/**", "*/.rbenv/**", "*/.nx/**", "*.app"
}

-- Set up ignore patterns for various plugins

-- Telescope (replaces Unite)
local telescope_ignores = vim.tbl_extend("force", common_ignores, {
  ".git/", "node_modules", "bower_components", "%.jpg", "%.jpeg", "%.png",
  "%.svg", "%.otf", "%.ttf", "%.webp", "%.eot", "%.gif", "%.woff", "%.woff2"
})

M.setup = function()
  -- Neo-tree (replaces NERDTree and Vimfiler)
  vim.g.neo_tree_remove_legacy_commands = true

  -- Wildignore (used by Neovim's native file browsing)
  vim.opt.wildignore = common_ignores

  -- Telescope configuration
  require("telescope").setup {
    defaults = {
      file_ignore_patterns = telescope_ignores
    }
  }

  -- Configure other plugins that might need ignore patterns
  -- For example, if you're using nvim-tree:
  -- require'nvim-tree'.setup {
  --   filters = {
  --     custom = common_ignores
  --   }
  -- }
end

return M
