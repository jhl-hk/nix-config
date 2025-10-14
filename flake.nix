{
  description = "JHL's Nix Configuration";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    darwin,
    home-manager,
    ...
  }: let
    inherit (self) outputs;

    # Helper function to create Darwin systems
    mkDarwin = {
      hostname,
      system ? "aarch64-darwin",
      username,
      modules ? []
    }: darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs outputs hostname username;
      };
      modules = [
        # Core configurations
        ./hosts/common/core
        ./hosts/common/darwin

        # Host-specific configuration
        ./hosts/darwin/${hostname}

        # User configuration
        ./users/${username}

        # Home Manager integration
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs outputs hostname username; };
            users.${username} = import ./home/${username};
          };
        }
      ] ++ modules;
    };

    # Helper function to create NixOS systems
    mkNixOS = {
      hostname,
      system ? "x86_64-linux",
      username,
      modules ? []
    }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs outputs hostname username;
      };
      modules = [
        # Core configurations
        ./hosts/common/core

        # Host-specific configuration
        ./hosts/nixos/${hostname}

        # User configuration
        ./users/${username}

        # Home Manager integration
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs outputs hostname username; };
            users.${username} = import ./home/${username};
          };
        }
      ] ++ modules;
    };

  in {
    # Darwin configurations
    darwinConfigurations = {
      # MacBook Air
      jhlsMacBookAir = mkDarwin {
        hostname = "jhlsMacBookAir";
        system = "aarch64-darwin";
        username = "jhl";
      };

      # Add more Darwin hosts here following the same pattern:
      # anotherMac = mkDarwin {
      #   hostname = "anotherMac";
      #   system = "aarch64-darwin";  # or "x86_64-darwin" for Intel
      #   username = "username";
      # };
    };

    # NixOS configurations (for future use)
    nixosConfigurations = {
      # Example NixOS host (uncomment when needed):
      # nixos-desktop = mkNixOS {
      #   hostname = "nixos-desktop";
      #   system = "x86_64-linux";
      #   username = "jhl";
      # };
    };

    # Formatter for nix files
    formatter = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ] (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
