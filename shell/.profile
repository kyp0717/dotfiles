# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.

# Source all files in ~/.profile.d if directory exists
if [ -d "$HOME/.profile.d" ]; then
    for file in "$HOME/.profile.d"/*.sh; do
        if [ -r "$file" ]; then
            . "$file"
        fi
    done
    unset file
fi

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi