{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    cmatrix
    curl
    fastfetch
    git
    lsd
    neofetch
    neovim
    rsync
    tmux
  ];

  fonts.packages = with pkgs; [ nerdfonts ];
}