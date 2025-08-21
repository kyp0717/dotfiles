# Snapshot file
# Unset all aliases to avoid conflicts with functions
unalias -a 2>/dev/null || true
shopt -s expand_aliases
# Check for rg availability
if ! command -v rg >/dev/null 2>&1; then
  alias rg='/home/kelp/.local/share/claude/versions/1.0.83 --ripgrep'
fi
export PATH=/home/kelp/.local/bin\:/home/kelp/miniconda3/bin\:/home/kelp/.cargo/bin\:/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/usr/games\:/usr/local/games\:/snap/bin\:/snap/bin
