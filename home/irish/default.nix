{ config, pkgs, ... }:

{
  # Adjust these two if your macOS user isn't literally "irish"
  home.username = "irish";
  home.homeDirectory = "/Users/irish";

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    initExtra = ''
      export EDITOR=nvim
      alias gs="git status"
      alias ll="ls -lah"
    '';
  };

  programs.git = {
    enable = true;
    userName = "X0mbiRapt0r";
    userEmail = "02gold.dogsled@icloud.com";  # change this
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    jq
  ];

  home.stateVersion = "24.05";
}
