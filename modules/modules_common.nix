{ nixpkgs, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop # System monitor.
    # caligula # Terminal disk-imaging tool.
    cmatrix # Terminal toy.
    curl # HTTP client and download helper.
    fastfetch # System info summary.
    fd # Fast `find` replacement.
    gh
    git # Version control.
    jq # JSON query tool.
    lsd # Modern `ls` replacement used by shell aliases.
    ripgrep # Fast text search.
    rsync # File sync/copy tool.
    tmux # Terminal multiplexer.
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Nerd Font glyphs for terminals and editors.
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
