{
  config,
  inputs,
  isDarwin,
  ...
}:
#############################################################
#
#  sops-nix
#
#  只做管道，不声明任何 secret。具体的 secret 由各自的消费模块声明
#  （例：hosts/common/optional/darwin/npmrc.nix），这样没用到密文的
#  机器不会因为某个 YAML 键还没填就求值失败。
#
#  解密密钥：~/.config/sops/age/keys.txt。
#  刻意不用 /etc/ssh/ssh_host_ed25519_key —— macOS 上那个文件要开过
#  「远程登录」才会生成，不可靠。activation 以 root 跑，root 读得到
#  用户目录下的文件，所以没问题。
#
#  ⚠️ 这个文件必须在第一次 rebuild **之前**就存在，否则 activation 失败。
#  ⚠️ Darwin 上 sops 解密失败是**静默**的（just check-sops 在 macOS 只
#     检查目录存在与否）。接第一个 secret 时手工验证一次真读到了明文。
#
#############################################################
{
  imports = [
    (
      if isDarwin
      then inputs.sops-nix.darwinModules.sops
      else inputs.sops-nix.nixosModules.sops
    )
  ];

  sops.age.keyFile = "${config.hostSpec.home}/.config/sops/age/keys.txt";
}
