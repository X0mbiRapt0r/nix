{ config, pkgs, ... }:

{
  # Adjust these two if your macOS user isn't literally "irish"
  home.username = "irish";
  home.homeDirectory = "/Users/irish";

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

  programs.git = {
    enable = true;
    settings = {
      user.name = "X0mbiRapt0r";
      user.email = "02gold.dogsled@icloud.com";
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
