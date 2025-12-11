{ config, pkgs, ... }:

{
  # Adjust these two if your macOS user isn't literally "irish"
  home.username = "irish";
  home.homeDirectory = "/Users/irish";

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ];
    AppleLocale = "en_ZA";
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "X0mbiRapt0r";
      user.email = "11319449+X0mbiRapt0r@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      export EDITOR=nvim
      # Shorter prompt: user@host:~/path >
      # %~ = nice, shortened path (uses ~ for $HOME and collapses middle)
      PROMPT='%n@%m:%1~ > '
      alias gs="git status"
      alias gacp="git add . && git commit -m 'quick update' && git push"
      alias ll="ls -lah"
    '';
  };

  home.sessionVariables = {
    PATH = "$PATH:$HOME/go/bin";
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
  ];

  home.file.".local/bin/nix-auto-rebuild.sh" = {
    text = ''
      #!/usr/bin/env bash
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

  home.stateVersion = "24.05";
}
