{
  description = "Irish's unified NixOS + macOS flake";

  inputs = {
    # Use unstable for everything for now
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }:
  let
    # helper so we can easily get pkgs for a platform
    forSystem = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    # We'll add NixOS hosts here later:
    # nixosConfigurations = { ... };

    darwinConfigurations = {
      # Work Mac
      QTM-Irish-MBA = darwin.lib.darwinSystem {
        system = "aarch64-darwin";  # change to "x86_64-darwin" if Intel
        pkgs = forSystem "aarch64-darwin";

        specialArgs = { inherit self; };

        modules = [
          ./hosts/QTM-Irish-MBA/darwin.nix

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;

            # adjust username if your macOS account name isn't "irish"
            home-manager.users.irish = import ./home/irish/default.nix;
          }
        ];
      };
    };
  };
}
