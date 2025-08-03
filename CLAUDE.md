# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository designed to create a consistent Linux development environment across multiple computers. The repository uses GNU Stow for symlink management, allowing quick replication of any configuration on a new machine with a simple command like `stow nvim/`. Each tool's configuration is organized in its own directory following Stow's conventions.

## Directory Structure

Each directory follows GNU Stow conventions, with subdirectories matching the target structure from the user's home directory:

- `nvim/`, `nvim-mod/`, `nvim-rust/` - Different Neovim configurations, with `nvim-rust/` being a Kickstart-based modular setup
- `nushell/` - Nu shell configuration
- `starship/` - Starship prompt configuration
- `wezterm/` - WezTerm terminal emulator configuration  
- `zed/` - Zed editor settings
- `scripts/` - Installation and setup scripts for various tools (not stow-managed)

## Common Commands

### Setting up configurations with Stow
Use GNU Stow to create symlinks from this repository to your home directory:
```bash
# Deploy a single configuration
stow nvim-rust/    # Symlinks nvim-rust config to ~/.config/nvim/
stow starship/     # Symlinks starship config  
stow zed/          # Symlinks zed config
stow wezterm/      # Symlinks wezterm config

# Deploy multiple configurations at once
stow nvim-rust/ starship/ zed/ wezterm/

# Remove a configuration
stow -D nvim-rust/

# Restow (useful after adding new files)
stow -R nvim-rust/
```

### Installing tools
The repository includes installation scripts in the `scripts/` directory:
```bash
./scripts/neovim.sh    # Install Neovim from unstable PPA
./scripts/starship.sh  # Install Starship prompt
./scripts/wezterm.sh   # Install WezTerm
```

## Working with Neovim configurations

The `nvim-rust/` directory contains a modular Kickstart-based configuration. Key aspects:
- Main configuration entry point: `nvim-rust/.config/nvim/init.lua`
- Plugin configurations: `nvim-rust/.config/nvim/lua/kickstart/plugins/`
- Custom plugins: `nvim-rust/.config/nvim/lua/custom/plugins/`
- Uses Lazy.nvim for plugin management
- Includes Rust development support via rustaceanvim

When modifying Neovim configs:
- Run `:Lazy` to manage plugins
- Check `:checkhealth` after changes
- The configuration includes LSP, treesitter, telescope, and various development tools

## Configuration Philosophy

This repository follows a modular approach where:
- Each tool's configuration is self-contained in a Stow-compatible directory structure
- GNU Stow manages symlinks, making it easy to deploy/remove configurations
- Installation scripts are provided for initial tool setup
- Configurations are optimized for consistent development workflows across machines
- Multiple Neovim configurations allow testing different setups without conflicts
- The repository serves as both backup and deployment mechanism for development environments