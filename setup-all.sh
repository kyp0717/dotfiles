#!/bin/bash
# Master setup script - Composes multiple sub-agents

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Dotfiles Master Setup Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Function to run sub-agent if it exists
run_subagent() {
    local agent_path="$1"
    local agent_name="$2"
    
    if [ -f "$agent_path" ]; then
        echo -e "\n${GREEN}Running $agent_name sub-agent...${NC}"
        "$agent_path"
    else
        echo -e "\n${GREEN}Skipping $agent_name (not found)${NC}"
    fi
}

# Setup core shell environment first
run_subagent "$SCRIPT_DIR/scripts/setup-local-bin.sh" "Shell PATH"

# Install tools
echo -e "\n${GREEN}Installing development tools...${NC}"
[ -f "$SCRIPT_DIR/scripts/neovim.sh" ] && "$SCRIPT_DIR/scripts/neovim.sh"
[ -f "$SCRIPT_DIR/scripts/starship.sh" ] && "$SCRIPT_DIR/scripts/starship.sh"

# Setup configurations
run_subagent "$SCRIPT_DIR/nvim-rust/setup.sh" "Neovim Rust"

# Deploy other configurations with stow
echo -e "\n${GREEN}Deploying additional configurations...${NC}"
cd "$SCRIPT_DIR"
stow starship/ 2>/dev/null && echo "  ✓ Starship configuration deployed"
stow zed/ 2>/dev/null && echo "  ✓ Zed configuration deployed"

echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Setup complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo
echo "Remember to:"
echo "  - Source your shell profile: source ~/.profile"
echo "  - Check tool installations: nvim --version, starship --version"
echo "  - Run :checkhealth in Neovim"