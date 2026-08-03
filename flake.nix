{
  description = "JHL's Nix Config";

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
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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

        # Home Manager integration
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            extraSpecialArgs = { inherit inputs outputs hostname username; };
            users.jhl = import ./home;
          };
        }
      ] ++ modules;
    };
  in {
    # Darwin configurations
    darwinConfigurations = {
      # MacBook Pro
      jhlsMacBookPro = mkDarwin {
        hostname = "jhlsMacBookPro";
        system = "aarch64-darwin";
        username = "jhl";
      };

      # MacBook Air
      jhlsMacBookAir = mkDarwin {
        hostname = "jhlsMacBookAir";
        system = "aarch64-darwin";
        username = "jhl";
      };

      # Taizhou
      SeandeMac-Studio = mkDarwin {
        hostname = "SeandeMac-Studio";
        system = "aarch64-darwin";
        username = "jhl";
      };
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
      "aarch64-darwin"
    ] (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
