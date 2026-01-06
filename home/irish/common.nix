{ config, pkgs, ... }:

{
  home.username = "irish";

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

    # Environment variables (better than inline export)
    sessionVariables = {
      EDITOR = "nvim";
    };

    # Aliases (better than inline alias)
    shellAliases = {
      gs = "git status";
      gacp = "git add . && git commit -m 'quick update' && git push origin main";
      ll = "ls -lah";
    };

    # Prompt: put prompt config in initExtra (or use starship)
    initExtra = ''
      PROMPT='%n@%m:%1~ > '
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

  home.stateVersion = "24.05";
}