# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles configuration repository for setting up and managing a developer's personal computing environment. It contains shell configurations, editor settings, and various tool configurations designed to work across multiple machines.

## Common Commands

### Installation and Setup
```bash
make install              # Symlink dotfiles to home directory
make debian_packages      # Install system packages on Debian/Ubuntu
make npm_packages        # Install global npm packages
make pip_packages        # Install Python packages
make cargo_packages      # Install Rust packages
```

### Development and Maintenance
```bash
make lint                # Run shellcheck on shell scripts
make fmt                 # Format shell scripts using beautysh
make update              # Update submodules
make check_dead_symlinks # Check for broken symlinks
```

### Python Automation Script (dot.py)
```bash
# Run all tests and checks for dot.py
uv run ruff check . --fix; uv run ruff format .; uv run mypy; uv run py.test test_dot.py --cov -v

# Use dot.py instead of Makefile
./dot.py install         # Install dotfiles symlinks
./dot.py debian-packages # Install Debian packages
./dot.py --dry-run install # Preview changes

# Diagnostic commands
./dot.py check           # Quick check of symlink status
./dot.py doctor          # Comprehensive system diagnostics with recommendations
```

### Key Makefile Targets
- Language-specific package installation: `pip_packages`, `npm_packages`, `yarn_packages`, `cargo_packages`, `gem_packages`, `go_packages`
- System setup: `debian_packages`, `debian_build_packages`
- Utility targets: `update`, `check_dead_symlinks`, various symlink targets for specific configs

## Architecture and Structure

### Core Configuration Files
- **Shell Configurations**: `.zshrc`, `.zshenv`, `.config/fish/config.fish` - Shell startup and environment settings
- **Makefile**: Central build system for installation, linting, and package management
- **Version Management**: Uses mise (formerly rtx) for managing multiple language runtimes

### Directory Structure
- `/config/`: Application-specific configurations (starship prompt, sheldon plugin manager, kitty terminal, neovim)
- `/.shell/`: Shared shell functions and scripts used across different shells
- `/.vim/`: Vim configuration and plugins
- `/.tmux/`: Tmux configuration with custom theme and bindings
- `/.ssh/`: SSH client configuration

### Key Design Patterns
1. **Symlink-based deployment**: Uses `make install` to create symlinks from the repo to the home directory
2. **Multi-shell support**: Configurations work across Zsh, Fish, and Bash
3. **Tool version management**: Centralized through mise for Python, Node.js, Go, Java, Elixir, Erlang
4. **Package management abstraction**: Makefile provides unified interface for different package managers

### Important Conventions
- Shell scripts should be compatible with both Bash and Zsh where possible
- Use shellcheck for linting shell scripts (`make lint`)
- Telemetry is disabled for various tools (Claude Code, Gatsby, Next.js) in shell configurations
- VSCode/Cursor terminal detection exists to provide minimal shell configuration in those environments