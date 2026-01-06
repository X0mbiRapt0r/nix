{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    cmatrix
    curl
    git
    lsd
    neofetch
    neovim
    rsync
    tmux
  ];
}