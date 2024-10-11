-- lua/settings/ignore.lua

-- NERDTree Ignore Patterns
vim.g.NERDTreeIgnore = {
    "\\~$", "\\.pyc", "\\.swp$", "\\.git$", "\\.hg", "\\.svn",
    "\\.ropeproject", "\\.o", "\\.bzr", "\\.ipynb_checkpoints$",
    "__pycache__", "\\.egg$", "\\.egg-info$", "\\.tox$", "\\.idea$", "\\.sass-cache",
    "\\.mypy_cache", "\\.ruff_cache", "\\.pytest_cache", "\\.env$", "\\.env[0-9]$",
    "\\.venv$", "\\.venv[0-9]$", "\\.coverage$", "\\.tmp$", "\\.gitkeep$", "\\.vscode$",
    "\\.splinter-screenshots$", "\\.webassets-cache$", "\\.vagrant$", "\\.DS_Store",
    "\\.env-pypy$", "\\.debug.{d,o}$"
}

-- vimfiler Ignore Pattern
vim.g.vimfiler_ignore_pattern = '\\%(\\.ini\\|\\.sys\\|\\.bat\\|\\.BAK\\|\\.DAT\\|\\.pyc\\|\\.egg-info\\)$\\|' ..
    '^\\%(\\.gitkeep\\|\\.coverage\\|\\.webassets-cache\\|\\.vagrant\\)$\\|' ..
    '^\\%(\\.env\\|\\.ebextensions\\|\\.elasticbeanstalk\\|Procfile\\)$\\|' ..
    '^\\%(\\.git\\|\\.tmp\\|__pycache__\\|\\.DS_Store\\|\\.o\\|\\.tox\\|\\.idea\\|\\.ropeproject\\)$'

-- Wildignore Patterns for Tab Completion
vim.opt.wildignore:append {
    "*.o", "*.obj", "*~", "*.pyc", "*.debug.o", "*.debug.d",
    ".env", ".env[0-9]+", ".env-pypy", ".venv", ".venv[0-9]+",
    ".venv-pypy", ".git", ".gitkeep", ".tmp", ".coverage",
    "*DS_Store*", ".sass-cache/**", ".vscode/", ".*_cache/", "__pycache__/**",
    ".webassets-cache/", "vendor/rails/**", "vendor/cache/**",
    "*.gem", "log/**", "tmp/**", ".tox/**", ".idea/**",
    ".vagrant/**", ".coverage/**", "*.egg", "*.egg-info",
    "*.png", "*.jpg", "*.gif", "*.so", "*.swp", "*.zip",
    "*/.Trash/**", "*.pdf", "*.dmg", "*/Library/**", "*/.rbenv/**",
    "*/.nx/**", "*.app"
}

-- Netrw Ignore Patterns
vim.g.netrw_list_hide = [[\.o,\.obj,*\~,\.pyc,\.debug\.d,\.debug\.o,\.env,\.env[0-9].,\.env-pypy,\.venv,\.venv[0-9].,\.venv-pypy,\.git/,\.gitkeep,\.vagrant,\.tmp,\.coverage$,\.DS_Store,__pycache__,\.*_cache/,\.webassets-cache/,\.sass-cache/,\.vscode/,\.splinter-screenshots/,\.ropeproject/,vendor/rails/,vendor/cache/,\.gem,\.ropeproject/,\.coverage/,log/,tmp/,\.tox/,\.idea/,\.egg,\.egg-info,\.png,\.jpg,\.gif,\.so,\.swp,\.zip,/\Trash/,\.pdf,\.dmg,/\Library/,/\.rbenv/,*/\.nx/**,*.app]]

-- Unite Ignore Patterns (if still used)
pcall(function()
  vim.fn['unite#custom#source'](
    'buffer,file,file_rec/async,file_rec,file_mru,file,grep',
    'ignore_pattern',
    table.concat({
      '\\.DS_Store', '\\.tmp/', '\\.git/', '\\.gitkeep', '\\.hg/', '\\.tox',
      '\\.idea', '\\.pyc', '\\.png', '\\.gif', '\\.jpg', '\\.svg', '\\.eot',
      '\\.ttf', '\\.woff', '\\.ico', '\\.o', '__pycache__', '.env', '.env*',
      '.venv', '.venv*', '.vagrant', '_build', 'dist', '*.tar.gz', '*.zip',
      'node_modules', 'bower_components', '.*\\.egg', '*.egg-info', '.*egg-info.*',
      'git5/.*/review/', 'google/obj/', '\\.webassets-cache/', '\\.sass-cache/',
      '\\.vscode/', '\\.coverage/', '\\.m2/', '\\.activator/', '\\.composer/',
      '\\.cache/', '\\.npm/', '\\.node-gyp/', '\\.sbt/', '\\.ivy2/', '\\.local/activator/'
    }, '\\|')
  )
end)
