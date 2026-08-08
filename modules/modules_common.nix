{ nixpkgs, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    # Disabled after a build failure; retry after a future nixpkgs update.
    caligula
    cmatrix
    curl
    fastfetch
    fd
    gh
    git
    jq
    lsd # Modern `ls` replacement used by shell aliases.
    ripgrep
    rsync
    tmux
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nix = {
    gc = {
      automatic = true; # Let each platform's native scheduler run garbage collection.
      options = "--delete-older-than 30d"; # Keep recent generations available for rollback.
    };
    optimise.automatic = true; # Deduplicate identical store paths on the platform scheduler.
    registry.nixpkgs.flake = nixpkgs; # Make `nixpkgs#pkg` resolve to this flake's pinned nixpkgs.
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ]; # Enable modern Nix CLI and flakes on each host.
  };
}
