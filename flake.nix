{
  description = "Irish's unified NixOS + macOS flake"; # descriptive metadata

  inputs = {
    darwin.url = "github:LnL7/nix-darwin"; # pins the nix-darwin project as input
    darwin.inputs.nixpkgs.follows = "nixpkgs"; # make nix-darwin use the same nixpkgs
    home-manager.url = "github:nix-community/home-manager"; # pins the home-manager project as input
    home-manager.inputs.nixpkgs.follows = "nixpkgs"; # make home-manager use the same nixpkgs
    nix-homebrew.url = "github:zhaofengli/nix-homebrew"; # pins the nix-homebrew project as input
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # use unstable branch for everything
  };

  nixConfig = {
    # auto-optimise-store = true; # enable auto-optimise-store globally
    extra-experimental-features = [ "nix-command" "flakes" ]; # enable nix-command and flakes globally
  };

  outputs = { self, nixpkgs, darwin, home-manager, nix-homebrew, ... }: # export systems
  let
    # helper so we can easily get pkgs for a platform
    forSystem = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {

    darwinConfigurations.Irish-MBP = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = forSystem "aarch64-darwin";
      specialArgs = { inherit self nixpkgs; };
      modules = [
        ./modules/modules_common.nix
        ./modules/modules_darwin.nix
        ./hosts/Irish-MBP/darwin.nix

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = ".before-hm";
          home-manager.users.irish = { ... }: {
            imports = [
              ./home/irish/common.nix
              ./home/irish/macos.nix
            ];
          };
        }
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # Install Homebrew under the default prefix
            enableRosetta = true; # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            user = "irish"; # User owning the Homebrew prefix
            # autoMigrate = true; # Automatically migrate existing Homebrew installations
          };
        }
      ];
    };

    darwinConfigurations.QTM-Irish-MBA = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = forSystem "aarch64-darwin";
      specialArgs = { inherit self nixpkgs; };
      modules = [
        ./modules/modules_common.nix
        ./modules/modules_darwin.nix
        ./hosts/QTM-Irish-MBA/darwin.nix

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = ".before-hm";
          home-manager.users.irish = { ... }: {
            imports = [
              ./home/irish/common.nix
              ./home/irish/macos.nix
            ];
          };
        }
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true; # Install Homebrew under the default prefix
            enableRosetta = true; # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            user = "irish"; # User owning the Homebrew prefix
            # autoMigrate = true; # Automatically migrate existing Homebrew installations
          };
        }
      ];
    };

    nixosConfigurations.XR-PC = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # XR-PC likely
      # pkgs = forSystem "x86_64-linux";
      specialArgs = { inherit self nixpkgs; };

      modules = [
        ./modules/modules_common.nix
        ./hosts/XR-PC/configuration.nix
        ./hosts/XR-PC/hardware-configuration.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.irish = { ... }: {
            imports = [
              ./home/irish/common.nix
              ./home/irish/linux.nix
            ];
          };
        }
      ];
    };
  };
}
