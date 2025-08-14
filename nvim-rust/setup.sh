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
    
    # Ensure ~/.local/bin exists
    mkdir -p ~/.local/bin
    
    # Install rust-analyzer if not present
    if ! command -v rust-analyzer >/dev/null 2>&1; then
        log_info "Installing rust-analyzer..."
        curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
        chmod +x ~/.local/bin/rust-analyzer
    else
        log_info "rust-analyzer already installed"
    fi
    
    # Install additional Rust tools
    log_info "Installing Cargo extensions..."
    cargo install --quiet cargo-watch 2>/dev/null || log_warn "cargo-watch already installed"
    cargo install --quiet cargo-edit 2>/dev/null || log_warn "cargo-edit already installed"
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
    
    # Install plugins (if Lazy.nvim is present)
    if [ -f ~/.config/nvim/lazy-lock.json ]; then
        log_info "Installing Neovim plugins..."
        nvim --headless "+Lazy! sync" +qa 2>/dev/null || log_warn "Plugin installation requires manual intervention"
    fi
    
    log_info "Post-install complete"
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Neovim Rust Configuration Sub-Agent
Sets up Neovim for Rust development with LSP, debugging, and tools.

OPTIONS:
    --force     Overwrite existing Neovim configuration
    --help      Show this help message

FEATURES:
    - rust-analyzer LSP configuration
    - Rust-specific keybindings
    - Cargo integration
    - Debugging support
    - Code formatting with rustfmt
    - Linting with clippy

DEPENDENCIES:
    - Neovim 0.9+
    - Rust toolchain (cargo, rustc)
    - GNU Stow
EOF
}

# Main execution
main() {
    # Parse arguments
    case "$1" in
        --help)
            show_usage
            exit 0
            ;;
        --force)
            ;;
        "")
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    echo "==================================="
    echo "Neovim Rust Configuration Sub-Agent"
    echo "==================================="
    echo
    
    # Run setup steps
    check_dependencies || exit 1
    install_rust_tools
    deploy_config $1 || exit 1
    post_install
    
    echo
    log_info "Setup complete! 🚀"
    log_info "Start Neovim and run :checkhealth to verify installation"
    log_info "Use <leader>r for Rust-specific commands"
}

# Run main function
main "$@"