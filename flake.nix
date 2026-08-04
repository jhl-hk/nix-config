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

    # 私有仓库。身份、拓扑、服务数据的明文半区经
    # hosts/common/core/default.nix 灌进 hostSpec；
    # 加密半区是 secrets/*.yaml，由 sops-nix 在 activation 时解密。
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

    # 把 lib.custom 挂上去。
    #
    # 必须按平台各自 extend：nix-darwin 会拿模块系统的 lib.trivial.release
    # 和自己的版本对比，如果这里统一用 unstable 的 nixpkgs.lib，Darwin 主机
    # 就会报 "nix-darwin 26.05 with Nixpkgs 26.11"。
    #
    # 这条路只覆盖**系统作用域**。home-manager 作用域走 overlays 里的
    # customLib 层 —— 见那里的注释，用 extraSpecialArgs 传 lib 会打掉 lib.hm。
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

    # 主机自动发现：hosts/<platform>/ 下的每个**子目录**就是一台机器。
    # 只认目录，所以 .gitkeep 之类的占位文件不会被当成 host。
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
          # core 必须排在 host 前面。option 的定义顺序会影响 listOf 类型的
          # 合并结果 —— environment.systemPath 就靠这个顺序落在
          # nix 路径和 /usr/bin 中间（见 hosts/common/core/darwin.nix）。
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

    # 现在是空的。往 hosts/nixos/<Name>/ 放一个目录就会自动出现。
    nixosConfigurations = lib.genAttrs (hostsIn ./hosts/nixos) mkNixosHost;

    # pkgs/common/<name>/package.nix -> nix build .#packages.<system>.<name>
    # 和 overlays 的 additions 层用的是同一份目录扫描。
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

    # `nix flake check` 默认不碰 darwinConfigurations，挂在这里 just check
    # 才会真的构建每台机器，而不是只做类型检查。push 之前的关卡。
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
