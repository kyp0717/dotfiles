# Sub-Agents Guide for Dotfiles Configuration

This guide demonstrates how to create specialized sub-agents for specific configuration tasks, using Neovim Rust configuration as an example.

## Concept Overview

Sub-agents are specialized task runners that handle specific aspects of your dotfiles configuration. They:
- Focus on a single domain (e.g., Rust development, Python setup, terminal config)
- Are self-contained and reusable
- Can be composed together for complex setups
- Provide consistent interfaces

## Example: Neovim Rust Configuration Sub-Agent

### 1. Directory Structure

```
nvim-rust/
├── .config/
│   └── nvim/
│       ├── init.lua
│       ├── lua/
│       │   ├── config/
│       │   │   ├── rust.lua         # Rust-specific settings
│       │   │   ├── lsp.lua          # LSP configurations
│       │   │   └── keymaps.lua      # Rust-specific keymaps
│       │   └── plugins/
│       │       ├── rust-tools.lua   # Rust development plugins
│       │       └── debugging.lua    # DAP configuration
│       └── after/
│           └── ftplugin/
│               └── rust.lua         # Rust filetype settings
└── setup.sh                         # Sub-agent entry point
```

### 2. Sub-Agent Script Template

Create `nvim-rust/setup.sh`:

```bash
#!/bin/bash
# Neovim Rust Configuration Sub-Agent

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_ROOT="$(dirname "$SCRIPT_DIR")"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for required tools
    command -v nvim >/dev/null 2>&1 || missing_deps+=("neovim")
    command -v cargo >/dev/null 2>&1 || missing_deps+=("rust/cargo")
    command -v stow >/dev/null 2>&1 || missing_deps+=("stow")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install missing dependencies first"
        return 1
    fi
    
    log_info "All dependencies satisfied"
    return 0
}

# Install Rust development tools
install_rust_tools() {
    log_info "Installing Rust development tools..."
    
    # Install rust-analyzer
    if ! command -v rust-analyzer >/dev/null 2>&1; then
        log_info "Installing rust-analyzer..."
        curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
        chmod +x ~/.local/bin/rust-analyzer
    fi
    
    # Install additional Rust tools
    cargo install --quiet cargo-watch 2>/dev/null || log_warn "cargo-watch already installed"
    cargo install --quiet cargo-edit 2>/dev/null || log_warn "cargo-edit already installed"
    cargo install --quiet cargo-expand 2>/dev/null || log_warn "cargo-expand already installed"
}

# Deploy configuration
deploy_config() {
    log_info "Deploying Neovim Rust configuration..."
    
    cd "$DOTFILES_ROOT"
    
    # Remove any existing nvim config if requested
    if [ "$1" == "--force" ]; then
        log_warn "Force mode: removing existing configuration"
        stow -D nvim-rust/ 2>/dev/null || true
    fi
    
    # Deploy with stow
    if stow nvim-rust/; then
        log_info "Configuration deployed successfully"
    else
        log_error "Failed to deploy configuration"
        log_info "Try running with --force to overwrite existing config"
        return 1
    fi
}

# Post-install setup
post_install() {
    log_info "Running post-install setup..."
    
    # Install plugins
    log_info "Installing Neovim plugins..."
    nvim --headless "+Lazy! sync" +qa
    
    # Generate helptags
    nvim --headless "+helptags ALL" +qa
    
    log_info "Post-install complete"
}

# Main execution
main() {
    echo "==================================="
    echo "Neovim Rust Configuration Sub-Agent"
    echo "==================================="
    echo
    
    # Parse arguments
    local force_mode=false
    if [ "$1" == "--force" ]; then
        force_mode=true
    fi
    
    # Run setup steps
    check_dependencies || exit 1
    install_rust_tools
    deploy_config $1 || exit 1
    post_install
    
    echo
    log_info "Setup complete! 🚀"
    log_info "Start Neovim and run :checkhealth to verify installation"
}

# Run main function
main "$@"
```

### 3. Configuration Module Example

Create `nvim-rust/.config/nvim/lua/config/rust.lua`:

```lua
-- Rust-specific configuration module
local M = {}

-- Rust development settings
M.setup = function()
    -- Configure rust-analyzer settings
    local rust_analyzer_settings = {
        ["rust-analyzer"] = {
            cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
            },
            checkOnSave = {
                command = "clippy",
                extraArgs = { "--all", "--", "-W", "clippy::all" },
            },
            procMacro = {
                enable = true,
                attributes = {
                    enable = true,
                },
            },
            diagnostics = {
                enable = true,
                experimental = {
                    enable = true,
                },
            },
        },
    }
    
    -- Return settings for use in LSP config
    return rust_analyzer_settings
end

-- Rust-specific keymaps
M.setup_keymaps = function()
    local keymap = vim.keymap.set
    local opts = { buffer = true, silent = true }
    
    -- Rust-specific mappings
    keymap("n", "<leader>rr", ":RustRun<CR>", opts)
    keymap("n", "<leader>rd", ":RustDebuggables<CR>", opts)
    keymap("n", "<leader>rt", ":RustTest<CR>", opts)
    keymap("n", "<leader>re", ":RustExpandMacro<CR>", opts)
    keymap("n", "<leader>rc", ":RustOpenCargo<CR>", opts)
    keymap("n", "<leader>rp", ":RustParentModule<CR>", opts)
end

return M
```

## Creating Your Own Sub-Agents

### Template Structure

1. **Entry Script** (`setup.sh`):
   - Dependency checking
   - Tool installation
   - Configuration deployment
   - Post-install tasks

2. **Configuration Modules**:
   - Language-specific settings
   - Plugin configurations
   - Keybindings
   - Auto-commands

3. **Documentation** (`README.md`):
   - What the configuration provides
   - Dependencies
   - Usage instructions
   - Customization options

### Best Practices

1. **Idempotency**: Sub-agents should be safe to run multiple times
2. **Dependency Management**: Check and report missing dependencies
3. **Force Mode**: Provide option to overwrite existing configs
4. **Logging**: Use consistent, colored output for better UX
5. **Error Handling**: Fail gracefully with helpful messages
6. **Modularity**: Keep configurations modular and composable

### Example Sub-Agents Ideas

1. **Python Development** (`nvim-python/`):
   - Pyright/Pylsp configuration
   - Virtual environment integration
   - Jupyter notebook support
   - Testing integration

2. **Web Development** (`nvim-web/`):
   - TypeScript/JavaScript LSP
   - Prettier formatting
   - ESLint integration
   - Tailwind CSS support

3. **DevOps** (`nvim-devops/`):
   - Terraform LSP
   - Docker integration
   - Kubernetes support
   - YAML/JSON schemas

4. **Terminal Enhancement** (`terminal/`):
   - Tmux configuration
   - Zellij setup
   - Terminal multiplexer integration

### Composing Sub-Agents

Create a master setup script that combines multiple sub-agents:

```bash
#!/bin/bash
# Master setup script

./nvim-rust/setup.sh
./nvim-python/setup.sh
./terminal/setup.sh
./shell/setup.sh
```

## Integration with Claude

When working with Claude on these configurations:

1. **Provide Context**: Include the sub-agent concept in CLAUDE.md
2. **Consistent Structure**: Follow the same directory patterns
3. **Clear Intent**: Name sub-agents descriptively
4. **Document Dependencies**: List all required tools clearly

This modular approach makes it easy to:
- Add new configurations incrementally
- Share specific setups with others
- Test configurations in isolation
- Maintain different setups for different machines