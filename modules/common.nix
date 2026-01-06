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
    nerdfonts
    rsync
    tmux
  ];
}