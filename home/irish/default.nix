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

      REPO_DIR="$HOME/Library/Mobile\ Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix"
      HOST="$HostName"  # or hardcode, see below

      # Only run once per calendar day
      STAMP="$HOME/.cache/nix-auto-rebuild.last"
      mkdir -p "$(dirname "$STAMP")"
      today="$(date +%F)"

      if [ -f "$STAMP" ] && [ "$(cat "$STAMP")" = "$today" ]; then
        exit 0
      fi

      echo "$today" > "$STAMP"

      cd "$REPO_DIR"

      # Get latest from GitHub (if any)
      git pull --ff-only || exit 0

      # Safer: rebuild only, no flake update
      # sudo -n darwin-rebuild switch --flake ".#$HOST" || true

      # ⚠ Spicy version (uncomment if you REALLY want auto-update):
      nix flake update
      git commit -am "chore: auto flake update $today" || true
      git push origin main || true
      sudo -n darwin-rebuild switch --flake ".#$HOST" || true
    '';
    executable = true;
  };

  home.stateVersion = "24.05";
}
