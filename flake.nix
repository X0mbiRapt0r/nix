{
  description = "Irish's unified NixOS + macOS flake"; # Shown by `nix flake metadata`.

  inputs = {
    brew-src = {
      flake = false; # Homebrew is a source checkout, not a Nix flake.
      url = "github:Homebrew/brew/master"; # Track Homebrew's rolling source; flake.lock records the tested revision.
    };
    darwin = {
      inputs.nixpkgs.follows = "nixpkgs"; # Keep nix-darwin on this flake's nixpkgs.
      url = "github:nix-darwin/nix-darwin/master"; # macOS system configuration module.
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs"; # Keep Home Manager on this flake's nixpkgs.
      url = "github:nix-community/home-manager"; # User-level dotfiles and app settings.
    };
    nix-homebrew = {
      inputs.brew-src.follows = "brew-src"; # Use the explicit Homebrew pin instead of nix-homebrew's default.
      url = "github:zhaofengli/nix-homebrew"; # Declarative Homebrew bootstrap for macOS.
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Rolling package set used by all hosts.
  };

  nixConfig = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ]; # Let this repo work on fresh Nix installs.
  };

  outputs =
    {
      brew-src,
      darwin,
      home-manager,
      nix-homebrew,
      nixpkgs,
      ...
    }:
    let
      brewRevision = brew-src.shortRev or "source"; # Non-flake inputs expose the locked Git revision after `nix flake update`.
      brewPackage = brew-src // {
        name = "brew-${brewRevision}"; # Label the Homebrew package by the locked source revision.
        version = "unstable-${brewRevision}"; # Avoid pretending a rolling source is a fixed upstream release.
      };
      forSystem =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true; # Required for unfree packages on Darwin when pkgs is passed explicitly.
        };

      mkHomeManagerUser =
        platformModule:
        { ... }:
        {
          imports = [
            ./home/irish/home_common.nix # Shared shell/editor/git config.
            platformModule # Platform-only Home Manager config.
          ];
        };

      darwinHomeManagerModule = {
        home-manager = {
          backupFileExtension = "before-hm"; # Back up unmanaged files as `name.before-hm`.
          useGlobalPkgs = true; # Reuse the system pkgs set instead of importing nixpkgs again.
          useUserPackages = true; # Install HM packages into the user's profile.
          users.irish = mkHomeManagerUser ./home/irish/home_darwin.nix;
        };
      };

      nixHomebrewModule = {
        nix-homebrew = {
          enable = true; # Install Homebrew under the default prefix.
          enableRosetta = true; # Also install the Intel prefix for Rosetta-only casks/formulas.
          package = brewPackage; # Use the current Homebrew code instead of nix-homebrew's bundled default.
          user = "irish"; # User that owns the Homebrew prefix.
        };
      };

      mkDarwinConfiguration =
        hostModule:
        darwin.lib.darwinSystem {
          pkgs = forSystem "aarch64-darwin"; # Share one unfree-enabled package set across Darwin modules.
          specialArgs = { inherit nixpkgs; }; # Passed to modules that need the original flake input.
          system = "aarch64-darwin"; # Apple Silicon macOS.
          modules = [
            ./modules/modules_common.nix # Shared packages and Nix settings.
            ./modules/modules_darwin.nix # Shared macOS defaults, Homebrew, and user setup.
            hostModule # Host-specific apps and host naming.

            home-manager.darwinModules.home-manager # Embed Home Manager in the Darwin switch.
            darwinHomeManagerModule

            nix-homebrew.darwinModules.nix-homebrew # Installs/manages the Homebrew prefix declaratively.
            nixHomebrewModule
          ];
        };
    in
    {

      darwinConfigurations.Irish-MBP = mkDarwinConfiguration ./hosts/Irish-MBP/host_darwin.nix;
      darwinConfigurations.QTM-Irish-MBA = mkDarwinConfiguration ./hosts/QTM-Irish-MBA/host_darwin.nix;

      nixosConfigurations.XR-PC = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit nixpkgs; }; # Passed to modules that need the original flake input.
        system = "x86_64-linux"; # AMD64 NixOS gaming PC.

        modules = [
          ./modules/modules_common.nix # Shared packages and Nix settings.
          ./hosts/XR-PC/configuration.nix # Host policy: desktop, gaming, users, services.
          ./hosts/XR-PC/hardware-configuration.nix # Generated hardware mounts, boot modules, and CPU hints.

          home-manager.nixosModules.home-manager # Embed Home Manager in the NixOS switch.
          {
            home-manager = {
              useGlobalPkgs = true; # Reuse the system pkgs set instead of importing nixpkgs again.
              useUserPackages = true; # Install HM packages into the user's profile.
              users.irish = mkHomeManagerUser ./home/irish/home_linux.nix;
            };
          }
        ];
      };
    };
}
