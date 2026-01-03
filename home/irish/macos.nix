{ config, pkgs, ... }:

{
  home.homeDirectory = "/Users/irish";

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ];
    AppleLocale = "en_ZA";
  };

  home.file.".local/bin/nix-auto-rebuild.sh" = {
    text = ''
      #!/usr/bin/env zsh
      set -euo pipefail

      REPO_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix"
      HOST="$HOSTNAME"  # or hardcode, see below

      LOG="$HOME/.cache/nix-auto-rebuild.log"
      mkdir -p "$(dirname "$LOG")"
      {
        echo "========== $(date) =========="
        echo "Host: $HOST"
        echo "PWD before cd: $(pwd)"

        # Only run once per calendar day
        STAMP="$HOME/.cache/nix-auto-rebuild.last"
        mkdir -p "$(dirname "$STAMP")"
        today="$(date +%F)"

        echo "Stamp path: $STAMP"
        if [ -f "$STAMP" ]; then
          echo "Previous run stamp: $(cat "$STAMP")"
        else
          echo "Stamp file does not exist yet"
        fi

        if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$today" ]; then
          echo "Already ran today, exiting."
          exit 0
        fi

        echo "$today" > "$STAMP"
        echo "Updated stamp, continuing."

        cd "$REPO_DIR"
        echo "Now in repo: $(pwd)"
        echo "Running: git pull --ff-only"
        git pull --ff-only || {
          echo "git pull failed or no fast-forward, exiting."
          exit 0
        }

        echo "Running: sudo -n darwin-rebuild switch --flake .#$HOST"
        sudo -n darwin-rebuild switch --flake ".#$HOST"
        echo "darwin-rebuild finished with exit code $?"

        # If you later enable auto flake update, log that here too.
      } >>"$LOG" 2>&1
    '';
    executable = true;
  };

}