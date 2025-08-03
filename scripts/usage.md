# Scripts Usage Guide

This directory contains installation and setup scripts for various development tools and configurations.

## setup-local-bin.sh

**Purpose:** Ensures that `~/.local/bin` is added to your PATH so that user-installed executables (like `claude`) are accessible from anywhere.

**What it does:**
1. Creates `~/.local/bin` directory if it doesn't exist
2. Deploys shell configuration files using GNU Stow
3. Adds `~/.local/bin` to PATH in both login and non-login shells

**Usage:**
```bash
./setup-local-bin.sh
```

**After running:**
- Apply changes immediately: `source ~/.profile` or `source ~/.bashrc`
- Or log out and log back in for changes to take effect
- Place executables in `~/.local/bin/` and they'll be available system-wide

**To remove:**
```bash
stow -D shell/  # From the dotfiles directory
```

## Tool Installation Scripts

### claude.sh
Installs the Claude CLI tool.
```bash
./claude.sh
```

### neovim.sh
Installs Neovim from the unstable PPA (latest features).
```bash
./neovim.sh
```

### starship.sh
Installs the Starship cross-shell prompt.
```bash
./starship.sh
```

### wezterm.sh
Installs the WezTerm terminal emulator.
```bash
./wezterm.sh
```

### get-nerdfont.sh
Downloads and installs Nerd Fonts for terminal icons.
```bash
./get-nerdfont.sh
```

## Typical Setup Flow

For a new Ubuntu machine:
```bash
# 1. Clone the dotfiles repository
git clone <your-dotfiles-repo> ~/dotfiles
cd ~/dotfiles

# 2. Set up local bin directory for user executables
./scripts/setup-local-bin.sh
source ~/.profile

# 3. Install desired tools
./scripts/neovim.sh
./scripts/starship.sh
./scripts/claude.sh

# 4. Deploy configurations with Stow
stow nvim-rust/
stow starship/
stow zed/
```

## Notes
- Most scripts require `sudo` privileges for package installation
- The `setup-local-bin.sh` script uses Stow, so make sure GNU Stow is installed
- Scripts are designed for Ubuntu/Debian-based systems