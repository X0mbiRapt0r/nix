{ ... }:

{
  home = {
    sessionPath = [ "$HOME/go/bin" ]; # Add Go-installed binaries to PATH.
    stateVersion = "26.05"; # Home Manager compatibility baseline; change only after a deliberate migration.
    username = "irish"; # Account name managed by Home Manager.
  };

  programs = {
    git = {
      enable = true; # Generate ~/.gitconfig.
      settings = {
        init.defaultBranch = "main"; # New repos start on main.
        pull.rebase = true; # Rebase local commits when pulling.
        user = {
          email = "11319449+X0mbiRapt0r@users.noreply.github.com"; # GitHub noreply commit email.
          name = "X0mbiRapt0r"; # Commit author name.
        };
      };
    };

    zsh = {
      autosuggestion.enable = true; # Suggest commands from history as you type.
      enable = true; # Manage ~/.zshrc with Home Manager.
      enableCompletion = true; # Enable shell completions.

      initContent = ''
        PROMPT='%n@%m:%1~ > '
      '';

      shellAliases = {
        gacp = "git add . && git commit -m 'quick update' && git push origin main"; # Quick personal commit/push helper.
        gs = "git status"; # Short git status.
        ll = "lsd -lah"; # Long listing with hidden files.
        ls = "lsd"; # Use lsd for basic listings.
        lt = "lsd --tree"; # Tree-style listing.
        nrs = "command nix-switch"; # Build and activate this host's flake configuration.
      };

      syntaxHighlighting.enable = true; # Highlight commands while typing.
    };
  };
}
