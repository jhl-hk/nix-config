{pkgs, ...}:
#############################################################
#
#  开发 shell -- `nix develop`
#
#  装的是「操作这个仓库」需要的工具，不是系统包。
#  sops / age 特意放这里而不是 hosts/，这样不用为了改一次
#  secret 就把它们装进每台机器。
#
#############################################################
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    just
    alejandra # formatter，和 flake 的 formatter 输出一致
    deadnix # 找没用到的绑定

    sops
    age
    ssh-to-age

    jq
    yq-go
    gum # 交互式脚本用
  ];

  shellHook = ''
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
      printf '\033[33m⚠ 没有找到 %s\033[0m\n' "$SOPS_AGE_KEY_FILE"
      printf '  sops 解密和 activation 都需要它。生成方法：\n'
      printf '    mkdir -p ~/.config/sops/age && age-keygen -o "$SOPS_AGE_KEY_FILE"\n\n'
    fi
    just --list
  '';
}
