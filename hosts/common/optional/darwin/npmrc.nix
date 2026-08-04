{
  config,
  inputs,
  ...
}:
#############################################################
#
#  ~/.npmrc -- @jianyuelab 私有 GitHub Packages
#
#  第一个真实的 secret 消费者，用来把 sops 管道验通。
#
#  用 sops.templates 而不是直接 sops.secrets.<x>.path：
#  token 只是 .npmrc 这个格式里的一个子串，templates 会在 activation
#  时把 placeholder 替换掉再落盘，secrets.path 只能给出裸值。
#
#  ⚠️ path 落地的是一个**软链** -> /run/secrets/rendered/npmrc，
#     不是就地写的文件（实测确认）。三个后果：
#       - 读没问题，npm 会跟软链；owner/mode 作用在目标上（0600 jhl）
#       - /run 是易失的，重启后靠 launchd daemon 重建；重建完成前
#         这是一条悬空软链
#       - **不要再用 `npm login` / `npm config set`** —— 那会写穿软链，
#         改动落进 /run/secrets/rendered/，下次 activation 直接被冲掉。
#         token 要改就改 shared.yaml。
#
#  ── 打开它需要三步 ────────────────────────────────────────
#  1) 在 nix-secrets 里创建密文（这一步只能你自己做）：
#
#       cd ../nix-secrets
#       nix shell nixpkgs#sops nixpkgs#age
#       export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
#       sops secrets/shared.yaml
#
#     内容：
#
#       npm:
#           jianyuelab_token: ghp_xxxxxxxxxxxx
#
#     然后 git add/commit/push，回 nix-config 跑 just update-nix-secrets
#
#  2) 在需要的机器的 hosts/darwin/<Host>/default.nix 里加进 imports：
#       "hosts/common/optional/darwin/npmrc.nix"
#
#  3) just rebuild，然后**手工确认**解密真的成功了：
#       grep -q '^//npm.pkg.github.com/:_authToken=ghp' ~/.npmrc && echo OK
#     （Darwin 上 sops 失败不会报错，只会留下没替换的文件）
#
#############################################################
let
  user = config.hostSpec.username;
in {
  sops.secrets."npm/jianyuelab_token" = {
    sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
    owner = user;
    mode = "0400";
  };

  sops.templates."npmrc" = {
    content = ''
      @jianyuelab:registry=https://npm.pkg.github.com
      //npm.pkg.github.com/:_authToken=${config.sops.placeholder."npm/jianyuelab_token"}
    '';
    owner = user;
    mode = "0600";
    path = "${config.hostSpec.home}/.npmrc";
  };
}
