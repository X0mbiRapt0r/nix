{ pkgs, nixpkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop # System monitor.
    cmatrix # Terminal toy.
    curl # HTTP client and download helper.
    fastfetch # System info summary.
    fd # Fast `find` replacement.
    git # Version control.
    jq # JSON query tool.
    lsd # Modern `ls` replacement used by shell aliases.
    neovim # Main terminal editor.
    ripgrep # Fast text search.
    rsync # File sync/copy tool.
    tmux # Terminal multiplexer.
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono # Nerd Font glyphs for terminals and editors.
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ]; # Enable modern Nix CLI and flakes on each host.
  nix.gc = {
    automatic = true; # Let each platform's scheduler run garbage collection.
  };
  nix.optimise.automatic = true; # Deduplicate identical store paths on the platform scheduler.
  nix.registry.nixpkgs.flake = nixpkgs; # Make `nixpkgs#pkg` resolve to this flake's pinned nixpkgs.
}
