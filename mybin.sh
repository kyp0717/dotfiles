#!/bin/bash
if ! command -v cargo &>/dev/null; then
    echo "Cargo is not installed. Installing now."
    curl https://sh.rustup.rs -sSf | sh
fi

cargo install ripgrep eza
