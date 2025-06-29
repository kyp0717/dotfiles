#!/bin/bash
if ! command -v cargo &>/dev/null; then
    echo "Cargo is not installed. Installing now."
    curl https://sh.rustup.rs -sSf | sh
fi

cargo install ripgrep eza bat
sudo apt install lua5.4 opam carapace-bin xclip wl-clipboard atuin zoxide

## install nerdfont
## ensure that ~/.local/bin is in your path
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash

## intall atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

## ocaml setup
opam init -y
opam install ocaml-lsp-server odoc ocamlformat utop
