{
  description = "JHL-HK's NixOS Configuration";

  #
  inputs = {
    # Official Packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with
      # the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ...}: {
    nixosConfigurations.ap-tokyo-desktop = nixpkgs.lib.nixosSystem {
      modules = [
        # import Configuration nixos
        ./configuration.nix

        # 将 home-manager 配置为 nixos 的一个 module
        # 这样在 nixos-rebuild switch 时，home-manager 配置也会被自动部署
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # 这里的 ryan 也得替换成你的用户名
          # 这里的 import 函数在前面 Nix 语法中介绍过了，不再赘述
          home-manager.users.jhl = import ./home.nix;

          # 使用 home-manager.extraSpecialArgs 自定义传递给 ./home.nix 的参数
          # 取消注释下面这一行，就可以在 home.nix 中使用 flake 的所有 inputs 参数了
          # home-manager.extraSpecialArgs = inputs;
        }
      ];
    };
  };
}
