#!/bin/bash
if ! command -v cargo &>/dev/null; then
    echo "Cargo is not installed. Installing now."
    curl https://sh.rustup.rs -sSf | sh
fi

cargo install ripgrep eza

sudo apt install lua5.4 opam carapace-bin

## ensure that ~/.local/bin is in your path
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash

## ocaml setup
opam init -y
opam install ocaml-lsp-server odoc ocamlformat utop
