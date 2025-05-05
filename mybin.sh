#!/bin/bash
if ! command -v cargo &>/dev/null; then
    echo "Cargo is not installed. Aborting."
    curl https://sh.rustup.rs -sSf | sh
fi

cargo install ripgrep
