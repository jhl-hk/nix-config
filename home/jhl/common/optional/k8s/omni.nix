{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  Omni / Kubernetes client for a standalone home-manager machine
#
#  Home-manager counterpart of modules/hosts/darwin/omni (read its header
#  for the file formats and why both files are read-only). Same secrets,
#  same target paths:
#
#    omni/omniconfig  ->  ~/.talos/omni/config
#    omni/kubeconfig  ->  ~/.kube/config
#
#  Configuration only: kubectl, omnictl and kubelogin (int128, provides
#  kubectl-oidc_login for the kubeconfig's exec auth) come from pacman/AUR.
#
#############################################################
let
  home = config.home.homeDirectory;
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
  omniConfigKey = "omni/omniconfig";
  kubeConfigKey = "omni/kubeconfig";
  hasKey = key: builtins.pathExists sopsFile && lib.hasInfix "${baseNameOf key}:" (builtins.readFile sopsFile);
in {
  assertions = [
    {
      assertion = hasKey omniConfigKey && hasKey kubeConfigKey;
      message = ''
        home/jhl/common/optional/k8s/omni.nix is imported, but
        secrets/shared.yaml has no ${omniConfigKey} / ${kubeConfigKey} yet.
        See the header of modules/hosts/darwin/omni/default.nix.
      '';
    }
  ];

  sops.secrets.${omniConfigKey} = {
    mode = "0400";
    path = "${home}/.talos/omni/config";
  };
  sops.secrets.${kubeConfigKey} = {
    mode = "0400";
    path = "${home}/.kube/config";
  };

  # Parents of the symlinks, plus ~/.talos/keys where omnictl writes its PGP
  # key on first login. Created as the user, so ownership is already right.
  home.activation.omniDirs = lib.hm.dag.entryBefore ["writeBoundary"] ''
    run install -d -m 0700 ${home}/.talos/omni ${home}/.kube ${home}/.talos/keys
  '';
}
