{ pkgs, nixpkgs, ... }:

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

    fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # nerd-fonts.fira-code
    # add more as needed, e.g.:
    # nerd-fonts.iosevka
  ];

  # nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    # dates = "weekly";
    options = "--delete-older-than 30d";
  };
  # Periodic store optimisation (safe replacement for auto-optimise-store on nix-darwin)
  nix.optimise.automatic = true;
  nix.registry.nixpkgs.flake = nixpkgs; # Make nixpkgs registry follow this flake input
}