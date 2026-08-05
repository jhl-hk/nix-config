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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Private repo. Its cleartext half -- identity, topology, service data --
    # is fed into hostSpec by hosts/common/core/default.nix; its encrypted
    # half is secrets/*.yaml, decrypted by sops-nix at activation time.
    nix-secrets = {
      url = "git+ssh://git@github.com/jhl-hk/nix-secrets.git?ref=main&shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-darwin,
    darwin,
    home-manager,
    ...
  }: let
    inherit (self) outputs;

    # Attach lib.custom.
    #
    # Each platform must be extended separately: nix-darwin compares the
    # module system's lib.trivial.release against its own version, so feeding
    # it the unstable nixpkgs.lib makes Darwin hosts abort with
    # "nix-darwin 26.05 with Nixpkgs 26.11".
    #
    # This path only covers the **system scope**. The home-manager scope goes
    # through the customLib layer in overlays -- see the comment there;
    # passing lib via extraSpecialArgs would clobber lib.hm.
    mkLib = base:
      base.extend (
        self': _super': {
          custom = import ./lib {lib = self';};
        }
      );

    lib = mkLib nixpkgs.lib;
    darwinLib = mkLib nixpkgs-darwin.lib;

    forAllSystems = lib.genAttrs [
      "aarch64-darwin"
      "x86_64-linux"
    ];

    # Host auto-discovery: every **subdirectory** of hosts/<platform>/ is a
    # machine. Only directories count, so placeholder files like .gitkeep are
    # never mistaken for a host.
    hostsIn = dir:
      if builtins.pathExists dir
      then lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir))
      else [];

    mkDarwinHost = hostName:
      darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs outputs;
          lib = darwinLib;
          isDarwin = true;
        };
        modules = [
          # core must come before the host. Definition order affects how
          # listOf options merge -- environment.systemPath relies on this
          # ordering to land between the nix paths and /usr/bin
          # (see hosts/common/core/darwin.nix).
          ./hosts/common/core
          ./hosts/darwin/${hostName}

          home-manager.darwinModules.home-manager
        ];
      };

    mkNixosHost = hostName:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs outputs lib;
          isDarwin = false;
        };
        modules = [
          ./hosts/common/core
          ./hosts/nixos/${hostName}

          home-manager.nixosModules.home-manager
        ];
      };
  in {
    overlays = import ./overlays {inherit inputs;};

    darwinConfigurations = lib.genAttrs (hostsIn ./hosts/darwin) mkDarwinHost;

    # Empty for now. Drop a directory in hosts/nixos/<Name>/ and it appears.
    nixosConfigurations = lib.genAttrs (hostsIn ./hosts/nixos) mkNixosHost;

    # pkgs/common/<name>/package.nix -> nix build .#packages.<system>.<name>
    # Same directory scan as the additions layer in overlays.
    packages = forAllSystems (
      system:
        nixpkgs.lib.packagesFromDirectoryRecursive {
          inherit (nixpkgs.legacyPackages.${system}) callPackage;
          directory = ./pkgs/common;
        }
    );

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    devShells = forAllSystems (
      system: {
        default = import ./shell.nix {pkgs = nixpkgs.legacyPackages.${system};};
      }
    );

    # `nix flake check` ignores darwinConfigurations by default. Hanging them
    # here makes `just check` actually build every machine instead of only
    # type-checking it. The gate to pass before pushing.
    checks = forAllSystems (
      system:
        lib.optionalAttrs (system == "aarch64-darwin") (
          lib.mapAttrs' (
            name: cfg: lib.nameValuePair "darwin-${name}" cfg.system
          )
          self.darwinConfigurations
        )
    );
  };
}
