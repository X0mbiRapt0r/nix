{ ... }:

{
  home.username = "irish"; # Account name managed by Home Manager.

  programs.git = {
    enable = true; # Generate ~/.gitconfig.
    settings = {
      user.name = "X0mbiRapt0r"; # Commit author name.
      user.email = "11319449+X0mbiRapt0r@users.noreply.github.com"; # GitHub noreply commit email.
      init.defaultBranch = "main"; # New repos start on main.
      pull.rebase = true; # Rebase local commits when pulling.
    };
  };

  programs.neovim = {
    enable = true; # Install/manage Neovim.
    defaultEditor = true; # Set EDITOR/VISUAL to nvim through HM.
    vimAlias = true; # Make `vim` open Neovim.
  };

  programs.zsh = {
    enable = true; # Manage ~/.zshrc with Home Manager.
    enableCompletion = true; # Enable shell completions.
    autosuggestion.enable = true; # Suggest commands from history as you type.
    syntaxHighlighting.enable = true; # Highlight commands while typing.

    sessionVariables = {
      EDITOR = "nvim"; # Preferred editor for terminal programs.
    };

    shellAliases = {
      gacp = "git add . && git commit -m 'quick update' && git push origin main"; # Quick personal commit/push helper.
      gs = "git status"; # Short git status.
      ll = "lsd -lah"; # Long listing with hidden files.
      ls = "lsd"; # Use lsd for basic listings.
      lt = "lsd --tree"; # Tree-style listing.
    };

    initContent = ''
      PROMPT='%n@%m:%1~ > '
    '';
  };

  home.sessionVariables = {
    PATH = "$PATH:$HOME/go/bin"; # Include Go-installed binaries.
  };

  home.stateVersion = "26.05"; # Home Manager compatibility version; do not bump casually.
}
