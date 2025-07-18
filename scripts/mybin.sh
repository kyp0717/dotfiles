#!/bin/bash
sudo apt install -y gnome-tweaks curl 
sudo apt install -y pkg-config libssl-dev build-essential
sudo apt install -y lua5.4 opam carapace-bin xclip wl-clipboard zoxide
sudo apt install -y wezterm

if ! command -v cargo &>/dev/null; then
    echo "Cargo is not installed. Installing now."
    curl https://sh.rustup.rs -sSf | sh
fi

cargo install ripgrep eza bat
cargo install nu --locked
sudo apt install -y lua5.4 opam carapace-bin xclip wl-clipboard atuin zoxide
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo apt update
sudo apt install -y neovim

## install nerdfont
## ensure that ~/.local/bin is in your path
curl -fsSL https://raw.githubusercontent.com/getnf/getnf/main/install.sh | bash

## intall atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

