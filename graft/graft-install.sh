#!/bin/bash
# Install graft — placeholder scaffold, fill in the real source/URL below.
#
# TODO: confirm which "graft" this is and how it distributes:
#   - GitHub release tarball?   -> model after scripts/neovim.install.sh
#   - cargo install <crate>?    (rust toolchain already present)
#   - npm install -g <pkg>?     (node already present)
#   - go install <pkg>@latest?  (needs golang)
#
# Usage: graft/graft-install.sh
set -euo pipefail

echo "ERROR: graft-install.sh is a scaffold — the install steps are not filled in yet." >&2
echo "" >&2
echo "Once you confirm which 'graft' to install, update this script. Candidates:" >&2
echo "  - https://github.com/The-Graft-Project/Graft  (Docker Compose -> cloud deploys)" >&2
echo "  - https://github.com/ms-henglu/graft        (Terraform module patcher)" >&2
echo "  - https://github.com/JacobMGEvans/git-graft (git hook for commit messages)" >&2
exit 1
