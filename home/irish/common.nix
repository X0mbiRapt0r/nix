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

    sessionVariables = {
      EDITOR = "nvim";
    };

    shellAliases = {
      gacp = "git add . && git commit -m 'quick update' && git push origin main";
      gs = "git status";
      ls = "lsd";
      lt = "lsd --tree";
      ll = "lsd -lah";
    };

    initContent = ''
      PROMPT='%n@%m:%1~ > ' # Clean PROMPT - USER@HOSTNAME:CURRENT_WORKING_DIRECTORY
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