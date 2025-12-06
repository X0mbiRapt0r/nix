{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    cmatrix
    curl
    git
    htop
    neofetch
    neovim
  ];
}