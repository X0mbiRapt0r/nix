#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/bootstrap-macos.sh Irish-MBP
#   ./scripts/bootstrap-macos.sh QTM-Irish-MBA
#
# Optional second arg: repo dir (defaults to ~/Documents/github.com/X0mbiRapt0r/nix)

HOST="${1:-Irish-MBP}"
REPO_DIR="${2:-$HOME/Documents/github.com/X0mbiRapt0r/nix}"
REPO_URL="https://github.com/X0mbiRapt0r/nix.git"

echo ">>> Bootstrapping host: $HOST"
echo ">>> Target repo dir: $REPO_DIR"

##############################################
# 1. Install Nix (if not already installed)
##############################################

if ! command -v nix >/dev/null 2>&1; then
  echo ">>> Nix not found, installing..."
  curl -L https://nixos.org/nix/install | sh
  # Load Nix for current shell (installer usually tells you this too)
  if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1090
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
else
  echo ">>> Nix already installed."
fi

##############################################
# 2. Enable flakes + nix-command globally
##############################################

echo ">>> Enabling flakes + nix-command in /etc/nix/nix.conf"
sudo mkdir -p /etc/nix
if ! grep -q "experimental-features = nix-command flakes" /etc/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
fi
sudo nix-daemon --restart 2>/dev/null || true

##############################################
# 3. Prepare /etc files for nix-darwin (fresh Macs)
##############################################

# On a truly fresh macOS, these may not exist; if they do, we move them
# out of the way so nix-darwin can own them.
for f in /etc/bashrc /etc/zshrc; do
  if [ -f "$f" ] && [ ! -f "$f.before-nix-darwin" ]; then
    echo ">>> Backing up $f -> $f.before-nix-darwin"
    sudo mv "$f" "$f.before-nix-darwin"
  fi
done

if [ -f /etc/nix/nix.conf ] && [ ! -f /etc/nix/nix.conf.before-nix-darwin ]; then
  # We already appended experimental-features above; this backup step is
  # mainly to mirror what we did manually the first time.
  echo ">>> Backing up /etc/nix/nix.conf -> /etc/nix/nix.conf.before-nix-darwin"
  sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
  echo "experimental-features = nix-command flakes" | sudo tee /etc/nix/nix.conf >/dev/null
fi

##############################################
# 4. Clone or update your flake repo
##############################################

if [ -d "$REPO_DIR/.git" ]; then
  echo ">>> Repo already exists at $REPO_DIR, pulling latest..."
  git -C "$REPO_DIR" pull --ff-only || true
else
  echo ">>> Cloning $REPO_URL into $REPO_DIR"
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"

##############################################
# 5. First-time nix-darwin switch via flake
##############################################

echo ">>> Running nix-darwin switch for host: $HOST"

# Use NIX_CONFIG once in case nix.conf wasn’t fully in place yet.
sudo NIX_CONFIG="experimental-features = nix-command flakes" \
  nix run nix-darwin -- switch --flake ".#$HOST"

echo ">>> Done! You can now use:"
echo "    sudo darwin-rebuild switch --flake .#$HOST"
echo "from $REPO_DIR for future changes."