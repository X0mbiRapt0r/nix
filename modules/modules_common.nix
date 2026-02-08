{ pkgs, nixpkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    cmatrix
    curl
    fastfetch
    fd
    git
    jq
    lsd
    neofetch
    neovim
    ripgrep
    rsync
    tmux
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
  };
  nix.optimise.automatic = true; # Periodic store optimisation (safe replacement for auto-optimise-store on nix-darwin)
  nix.registry.nixpkgs.flake = nixpkgs; # Make nixpkgs registry follow this flake input
}