{ nixpkgs, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop
    caligula
    cmatrix
    curl
    fastfetch
    # fetch
    fd
    gh
    git
    hyfetch
    jq
    lsd # Modern `ls` replacement used by shell aliases.
    nerdfetch
    powershell # Cross-platform shell and scripting runtime.
    python3
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

  programs.zsh.enable = true; # Register zsh as an available shell on every host.
}
