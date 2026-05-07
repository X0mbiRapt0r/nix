{
  description = "Irish's unified NixOS + macOS flake"; # Shown by `nix flake metadata`.

  inputs = {
    darwin.url = "github:nix-darwin/nix-darwin/master"; # macOS system configuration module.
    darwin.inputs.nixpkgs.follows = "nixpkgs"; # Keep nix-darwin on this flake's nixpkgs.
    home-manager.url = "github:nix-community/home-manager"; # User-level dotfiles and app settings.
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # Keep Home Manager on this flake's nixpkgs.
    brew-src.url = "github:Homebrew/brew/5.1.10"; # Pin the Homebrew code that nix-homebrew installs.
    brew-src.flake = false; # Homebrew is a source checkout, not a Nix flake.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew"; # Declarative Homebrew bootstrap for macOS.
    nix-homebrew.inputs.brew-src.follows = "brew-src"; # Use the explicit Homebrew pin instead of nix-homebrew's default.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Rolling package set used by all hosts.
  };

  nixConfig = {
    extra-experimental-features = [ "nix-command" "flakes" ]; # Let this repo work on fresh Nix installs.
  };

  outputs = { nixpkgs, darwin, home-manager, brew-src, nix-homebrew, ... }:
  let
    brewPackage = brew-src // {
      name = "brew-5.1.10"; # Label the pinned Homebrew source used by nix-homebrew.
      version = "5.1.10"; # Report the same Homebrew version that is pinned in brew-src.
    };
    forSystem = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true; # Required for unfree packages on Darwin when pkgs is passed explicitly.
    };
  in
  {

    darwinConfigurations.Irish-MBP = darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # Apple Silicon macOS.
      pkgs = forSystem "aarch64-darwin"; # Share one unfree-enabled package set across Darwin modules.
      specialArgs = { inherit nixpkgs; }; # Passed to modules that need the original flake input.
      modules = [
        ./modules/modules_common.nix # Shared packages and Nix settings.
        ./modules/modules_darwin.nix # Shared macOS defaults, Homebrew, and user setup.
        ./hosts/Irish-MBP/host_darwin.nix # Irish-MBP-specific apps and hostname.

        home-manager.darwinModules.home-manager # Embed Home Manager in the Darwin switch.
        {
          home-manager.useGlobalPkgs = true; # Reuse the system pkgs set instead of importing nixpkgs again.
          home-manager.useUserPackages = true; # Install HM packages into the user's profile.
          home-manager.backupFileExtension = "before-hm"; # Back up unmanaged files as `name.before-hm`.
          home-manager.users.irish = { ... }: {
            imports = [
              ./home/irish/home_common.nix # Shared shell/editor/git config.
              ./home/irish/home_darwin.nix # macOS-only Home Manager config.
            ];
          };
        }
        nix-homebrew.darwinModules.nix-homebrew # Installs/manages the Homebrew prefix declaratively.
        {
          nix-homebrew = {
            enable = true; # Install Homebrew under the default prefix.
            enableRosetta = true; # Also install the Intel prefix for Rosetta-only casks/formulas.
            package = brewPackage; # Use the current Homebrew code instead of nix-homebrew's bundled default.
            user = "irish"; # User that owns the Homebrew prefix.
          };
        }
      ];
    };

    darwinConfigurations.QTM-Irish-MBA = darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # Apple Silicon macOS.
      pkgs = forSystem "aarch64-darwin"; # Share one unfree-enabled package set across Darwin modules.
      specialArgs = { inherit nixpkgs; }; # Passed to modules that need the original flake input.
      modules = [
        ./modules/modules_common.nix # Shared packages and Nix settings.
        ./modules/modules_darwin.nix # Shared macOS defaults, Homebrew, and user setup.
        ./hosts/QTM-Irish-MBA/host_darwin.nix # Work Mac-specific apps and hostname.

        home-manager.darwinModules.home-manager # Embed Home Manager in the Darwin switch.
        {
          home-manager.useGlobalPkgs = true; # Reuse the system pkgs set instead of importing nixpkgs again.
          home-manager.useUserPackages = true; # Install HM packages into the user's profile.
          home-manager.backupFileExtension = "before-hm"; # Back up unmanaged files as `name.before-hm`.
          home-manager.users.irish = { ... }: {
            imports = [
              ./home/irish/home_common.nix # Shared shell/editor/git config.
              ./home/irish/home_darwin.nix # macOS-only Home Manager config.
            ];
          };
        }
        nix-homebrew.darwinModules.nix-homebrew # Installs/manages the Homebrew prefix declaratively.
        {
          nix-homebrew = {
            enable = true; # Install Homebrew under the default prefix.
            enableRosetta = true; # Also install the Intel prefix for Rosetta-only casks/formulas.
            package = brewPackage; # Use the current Homebrew code instead of nix-homebrew's bundled default.
            user = "irish"; # User that owns the Homebrew prefix.
          };
        }
      ];
    };

    nixosConfigurations.XR-PC = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # AMD64 NixOS gaming PC.
      specialArgs = { inherit nixpkgs; }; # Passed to modules that need the original flake input.

      modules = [
        ./modules/modules_common.nix # Shared packages and Nix settings.
        ./hosts/XR-PC/configuration.nix # Host policy: desktop, gaming, users, services.
        ./hosts/XR-PC/hardware-configuration.nix # Generated hardware mounts, boot modules, and CPU hints.

        home-manager.nixosModules.home-manager # Embed Home Manager in the NixOS switch.
        {
          home-manager.useGlobalPkgs = true; # Reuse the system pkgs set instead of importing nixpkgs again.
          home-manager.useUserPackages = true; # Install HM packages into the user's profile.

          home-manager.users.irish = { ... }: {
            imports = [
              ./home/irish/home_common.nix # Shared shell/editor/git config.
              ./home/irish/home_linux.nix # Linux-only Home Manager config.
            ];
          };
        }
      ];
    };
  };
}
