# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Source global definitions if available
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Source all files in ~/.bashrc.d if directory exists
if [ -d "$HOME/.bashrc.d" ]; then
    for file in "$HOME/.bashrc.d"/*.sh; do
        if [ -r "$file" ]; then
            . "$file"
        fi
    done
    unset file
fi