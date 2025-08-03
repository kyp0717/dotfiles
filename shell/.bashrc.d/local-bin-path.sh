#!/bin/bash
# Ensure ~/.local/bin is in PATH for non-login shells

# Add ~/.local/bin to PATH if it exists and isn't already in PATH
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi