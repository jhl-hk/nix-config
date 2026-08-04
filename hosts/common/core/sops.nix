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
#
#  失败可见性：sops-install-secrets 走两条路 ——
#    switch 时  system.activationScripts.postActivation（activate 带 set -e，
#               解密失败会直接中止 switch 并报错，不是静默的）
#    开机时     launchd.daemons.sops-install-secrets（输出进 launchd 日志，
#               终端上看不到）
#  端到端自检见 hosts/common/optional/darwin/sops-canary.nix 和 just verify-sops。
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
