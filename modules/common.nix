{ pkgs, nixpkgs, ... }:

{
  nix.registry.nixpkgs.flake = nixpkgs; # Make nixpkgs registry follow this flake input
  
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

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # nerd-fonts.fira-code
    # add more as needed, e.g.:
    # nerd-fonts.iosevka
  ];
}