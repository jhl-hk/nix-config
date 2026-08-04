{
  config,
  inputs,
  ...
}:
#############################################################
#
#  sops 管道自检 -- 一次性的,验完就删
#
#  同时覆盖两条不同的代码路径：
#    sops.secrets.<x>   裸密文,落到 /run/secrets/<name>
#    sops.templates.<x> 占位符替换,渲染成完整文件
#  npmrc 那种用的是后者,所以两条都要过。
#
#  ── 用法 ─────────────────────────────────────────────────
#  1) 在 nix-secrets 里写入 canary（只有你能做）：
#
#       cd ../nix-secrets
#       nix shell nixpkgs#sops nixpkgs#age
#       export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
#       sops secrets/shared.yaml
#
#     内容（值随便改，只要下面 expect 对得上）：
#
#       canary:
#           value: sops-pipeline-ok
#
#     然后 git add/commit/push
#
#  2) 在某台机器的 hosts/darwin/<Host>/default.nix 的 imports 里加：
#       "hosts/common/optional/darwin/sops-canary.nix"
#
#  3) just rebuild，再跑 just verify-sops
#
#  4) 验完把 import 删掉、把 canary 从 shared.yaml 里删掉、
#     删掉本文件。别把自检留在生产配置里。
#
#############################################################
let
  user = config.hostSpec.username;
in {
  # 路径一：裸密文
  sops.secrets."canary/value" = {
    sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
    owner = user;
    mode = "0400";
  };

  # 路径二：占位符替换。这条才是 npmrc / netrc / env 文件真正走的路。
  sops.templates."sops-canary" = {
    content = ''
      canary=${config.sops.placeholder."canary/value"}
    '';
    owner = user;
    mode = "0600";
    path = "${config.hostSpec.home}/.sops-canary";
  };
}
