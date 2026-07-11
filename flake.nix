{
  description = "Irish's unified NixOS + macOS flake"; # Shown by `nix flake metadata`.

  inputs = {
    darwin = {
      inputs.nixpkgs.follows = "nixpkgs"; # Keep nix-darwin on this flake's nixpkgs.
      url = "github:nix-darwin/nix-darwin/master"; # macOS system configuration module.
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs"; # Keep Home Manager on this flake's nixpkgs.
      url = "github:nix-community/home-manager/master"; # User-level dotfiles and app settings.
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew"; # Declarative Homebrew bootstrap for macOS.
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
      self,
      darwin,
      home-manager,
      nix-homebrew,
      nixpkgs,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      forSystem =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true; # Required for unfree packages on Darwin when pkgs is passed explicitly.
        };

      mkHomeManagerModule = platformModule: {
        home-manager = {
          backupFileExtension = "before-hm"; # Back up unmanaged files as `name.before-hm` on every host.
          useGlobalPkgs = true; # Reuse the system pkgs set instead of importing nixpkgs again.
          useUserPackages = true; # Install HM packages into the user's profile.
          users.irish.imports = [
            ./home/irish/home_common.nix # Shared shell, Git, and helper-command config.
            platformModule # Platform-only Home Manager config.
          ];
        };
      };

      nixHomebrewModule = {
        nix-homebrew = {
          enable = true; # Install Homebrew under the default prefix.
          enableRosetta = true; # Also install the Intel prefix for Rosetta-only casks/formulas.
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
            (mkHomeManagerModule ./home/irish/home_darwin.nix)

            nix-homebrew.darwinModules.nix-homebrew # Installs/manages the Homebrew prefix declaratively.
            nixHomebrewModule
          ];
        };
    in
    {
      checks = forAllSystems (
        system:
        let
          pkgs = forSystem system;
        in
        {
          formatting = pkgs.runCommand "check-nix-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
            nixfmt --check \
              ${self}/flake.nix \
              ${self}/home/irish/*.nix \
              ${self}/hosts/*/configuration.nix \
              ${self}/hosts/*/host_*.nix \
              ${self}/modules/*.nix
            touch $out
          '';
          shellcheck = pkgs.runCommand "check-shell-scripts" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
            shellcheck ${self}/scripts/*
            touch $out
          '';
        }
      );
      darwinConfigurations.Irish-MBP = mkDarwinConfiguration ./hosts/Irish-MBP/host_darwin.nix;
      darwinConfigurations.QTM-Irish-MBA = mkDarwinConfiguration ./hosts/QTM-Irish-MBA/host_darwin.nix;
      formatter = forAllSystems (system: (forSystem system).nixfmt);

      nixosConfigurations.XR-PC = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit nixpkgs; }; # Passed to modules that need the original flake input.
        system = "x86_64-linux"; # AMD64 NixOS gaming PC.

        modules = [
          ./modules/modules_common.nix # Shared packages and Nix settings.
          ./hosts/XR-PC/configuration.nix # Host policy: desktop, gaming, users, services.
          ./hosts/XR-PC/hardware-configuration.nix # Generated hardware mounts, boot modules, and CPU hints.

          home-manager.nixosModules.home-manager # Embed Home Manager in the NixOS switch.
          (mkHomeManagerModule ./home/irish/home_linux.nix)
        ];
      };
    };
}
