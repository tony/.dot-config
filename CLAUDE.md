# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles configuration repository for setting up and managing a developer's personal computing environment. It contains shell configurations, editor settings, and various tool configurations designed to work across multiple machines. The repository uses both a traditional Makefile approach and a modern Python 3.12+ automation script (dot.py).

## Common Commands

### Testing and Linting
```bash
# Run all tests and quality checks for dot.py
uv run ruff check . --fix
uv run ruff format .
uv run mypy
uv run pytest test_dot.py --cov -v

# Traditional shell script linting
make lint                # Run shellcheck on shell scripts
make fmt                 # Format shell scripts using beautysh
```

### Installation and Setup
```bash
# Using Makefile (traditional approach)
make install             # Symlink dotfiles to home directory
make debian_packages     # Install system packages on Debian/Ubuntu
make npm_packages        # Install global npm packages
make pip_packages        # Install Python packages
make cargo_packages      # Install Rust packages

# Using dot.py (modern approach)
./dot.py install         # Install dotfiles symlinks
./dot.py provision       # Install all provisioners and enhancements
./dot.py provision --type provisioner  # Install only core provisioners
./dot.py debian-packages # Install Debian packages
./dot.py --dry-run install # Preview changes
```

### Diagnostic and Utility Commands
```bash
# dot.py specific commands
./dot.py check           # Quick check of symlink status
./dot.py doctor          # Comprehensive system diagnostics with recommendations
./dot.py status          # Show provisioning status
./dot.py cleanup         # Remove unwanted files from home
./dot.py shell --zsh     # Generate complete shell init
./dot.py shell --zsh --stage early  # Generate only early stage (fast)
```

### Maintenance
```bash
# Update git submodules (.vim, .tmux, .tmuxp, config/base16-shell)
git submodule update --init --recursive
```

## Architecture and Structure

### Two Management Systems
1. **Makefile**: Traditional approach with targets for various installation tasks
2. **dot.py**: Modern Python 3.12+ script with:
   - Foundation → Provisioners → Package Managers → Enhancements architecture
   - Staged shell initialization (early/main/late) for 90% faster startup
   - Pattern matching, strict typing, async TaskGroup support
   - Priority-based dependencies (0-9, lower runs first)

### Directory Structure
- **Shell Configurations**: `.zshrc`, `.zshenv`, `config/fish/config.fish`
- **Version Management**: Uses mise (formerly rtx) for managing Python, Node.js, Go, Java, Elixir, Erlang
- **Application Configs**: 
  - `/config/`: starship prompt, sheldon plugin manager, kitty terminal, neovim, sway, gitui
  - `/.vim/`: Vim configuration (git submodule)
  - `/.tmux/`: Tmux configuration (git submodule)  
  - `/.shell/`: Shared shell functions and scripts
  - `/.ssh/`: SSH client configuration

### Key Configuration Files
- **dot.toml**: Modern dotfiles configuration with symlink mappings and package groups
- **pyproject.toml**: Python project configuration with uv for dependency management
- **.tool-versions**: mise/asdf version specifications for multiple language runtimes

### Testing Infrastructure
- Uses pytest with async support, coverage, and mock capabilities
- Python 3.11+ required (targets 3.12 with mypy)
- Ruff for linting and formatting
- Test file: `test_dot.py`

### Important Conventions
- Shell scripts should be compatible across Bash, Zsh, and Fish where applicable
- Uses uv as the Python package manager (not pip directly)
- Git submodules are used for .vim, .tmux, .tmuxp, and config/base16-shell
- VSCode/Cursor terminal detection provides minimal shell configuration in those environments
- Telemetry is disabled for various tools (Claude Code, Gatsby, Next.js)