# Dotfiles

A comprehensive dotfiles repository for setting up a modern development environment on Ubuntu/Debian systems using GNU Stow for configuration management.

## Features

This repository includes configurations for:

- **Neovim** - Three configurations available, with `nvim-rust/` as the recommended setup
- **Nushell** - Modern shell with custom themes and modules
- **WezTerm** - GPU-accelerated terminal emulator with Nushell integration
- **Zed** - High-performance code editor with custom themes
- **Starship** - Cross-shell prompt with bracketed segments style
- **Shell** - Modular bash configuration with `.bashrc.d/` and `.profile.d/`

## Quick Start

### Prerequisites

- Ubuntu/Debian-based Linux distribution
- Git
- GNU Stow (`sudo apt install stow`)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Set up local bin directory:**
   ```bash
   ./scripts/setup-local-bin.sh
   source ~/.bashrc
   ```

3. **Install desired tools:**
   ```bash
   # Core tools
   ./scripts/neovim.sh      # Installs Neovim (unstable)
   ./scripts/starship.sh    # Installs Starship prompt
   ./scripts/wezterm.sh     # Installs WezTerm terminal
   
   # Optional tools
   ./scripts/claude.sh      # Installs Claude CLI
   ./scripts/get-nerdfont.sh # Downloads Nerd Fonts
   ```

4. **Deploy configurations using Stow:**
   ```bash
   # Deploy individual configurations
   stow nvim-rust/    # Neovim configuration
   stow nushell/      # Nushell shell
   stow wezterm/      # WezTerm terminal
   stow zed/          # Zed editor
   stow starship/     # Starship prompt
   stow shell/        # Bash configuration
   
   # Or deploy multiple at once
   stow nvim-rust/ nushell/ wezterm/ starship/ shell/
   ```

5. **Restart your terminal or source configurations:**
   ```bash
   source ~/.bashrc
   ```

## Repository Structure

```
dotfiles/
├── nvim-rust/        # Recommended Neovim config (Kickstart-based)
├── nvim/            # Alternative Neovim config
├── nvim-mod/        # Another Neovim variant
├── nushell/         # Nushell configuration
├── wezterm/         # WezTerm terminal config
├── zed/             # Zed editor settings
├── starship/        # Starship prompt configs
├── shell/           # Bash/shell configurations
├── scripts/         # Installation scripts
└── prps/            # Project documentation
```

## Configuration Details

### Neovim (`nvim-rust/`)
- Based on Kickstart.nvim with modular plugin organization
- LSP support for multiple languages (Rust, Python, TypeScript, etc.)
- Telescope fuzzy finder, Treesitter syntax highlighting
- Rust development tools via rustaceanvim
- Oil.nvim file explorer, Flash.nvim navigation

### Nushell
- Custom dark/light themes
- Conda integration
- Vi-style keybindings
- Custom completions and aliases

### WezTerm
- JetBrains Mono Nerd Font
- Catppuccin color scheme
- Nushell as default shell
- Custom key bindings and tab bar configuration

### Starship
- Multiple configuration options available
- Bracketed segments style
- Git-aware prompt with language version display

## Stow Commands Reference

```bash
# Deploy a configuration
stow <package>/

# Remove a configuration
stow -D <package>/

# Restow (update symlinks)
stow -R <package>/

# Simulate (dry run)
stow -n <package>/

# Verbose output
stow -v <package>/
```

## Project Documentation

- **`prps/project.md`** - Detailed project structure and philosophy
- **`prps/tasks.md`** - Current development tasks and TODO items
- **`CLAUDE.md`** - AI assistant guidelines for repository development

## Troubleshooting

### Stow Conflicts
If you encounter conflicts when stowing:
```bash
# Check what would be stowed
stow -n -v <package>/

# Force restow (careful with existing files)
stow -R <package>/
```

### Missing Dependencies
Ensure all required tools are installed:
```bash
# Check if tool is installed
which neovim
which starship
which wezterm
```

### Path Issues
Make sure `~/.local/bin` is in your PATH:
```bash
echo $PATH | grep -q "$HOME/.local/bin" && echo "Path is set" || echo "Path not set"
```

## Contributing

This is a personal dotfiles repository, but suggestions and improvements are welcome. Please ensure any changes follow the existing structure and work with GNU Stow.

## License

This repository is provided as-is for personal use. Feel free to fork and modify for your own needs.