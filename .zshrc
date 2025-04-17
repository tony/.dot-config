###############################################################################
# Environment Variables & Constants
###############################################################################

# mise
export MISE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
export MISE_DATA_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
# Don't set this as a TOML config file
# export MISE_GLOBAL_CONFIG_FILE="${HOME}/.tool-versions"
export MISE_CARGO_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-cargo-crates"
export MISE_PYTHON_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-python-packages"
export MISE_NODE_DEFAULT_PACKAGES_FILE="${ZDOTDIR}/.default-npm-packages"
export MISE_ASDF_COMPAT=true

export VITEST_REPORTER=dot
