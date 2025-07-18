#!/bin/bash
sudo apt install -y gnome-tweaks curl 
sudo apt install -y pkg-config libssl-dev build-essential
sudo apt install -y lua5.4 carapace-bin xclip wl-clipboard zoxide

if ! command -v cargo &>/dev/null; then
    echo "Cargo is not installed. Installing now."
    curl https://sh.rustup.rs -sSf | sh
fi

cargo install ripgrep eza bat


## intall atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

