{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    cmatrix
    curl
    git
    neofetch
    neovim
    rsync
    tmux
  ];
}