{
  config,
  inputs,
  lib,
  ...
}:
#############################################################
#
#  Omni / Kubernetes client configuration
#
#  Two files, both decrypted from shared.yaml and symlinked into place:
#
#    ~/.talos/omni/config   omnictl's omniconfig
#    ~/.kube/config         kubectl's kubeconfig
#
#  -- First, to be clear: neither file contains credentials ---------------
#
#  The kubeconfig uses exec auth:
#      command: kubectl  args: [oidc-login, get-token, ...]
#  clusters[].cluster holds only a server, no certificate-authority-data, and
#  users[].user holds only exec, no client-certificate-data and no token.
#  The actual token is fetched by kubelogin and cached in
#  ~/.kube/cache/oidc-login/.
#
#  The omniconfig holds only a url and auth.siderov1.identity (an email
#  address). The real credential is a PGP private key, which omnictl keeps in
#  ~/.talos/keys/ (see the directory pre-creation below).
#
#  So encrypting these is **not** about protecting key material -- it is about
#  keeping internal hostnames and identity out of the public nix-config. Same
#  reasoning as hostSpec keeping domain / email in nix-secrets.
#
#  -- The symlinks are read-only, with two consequences ------------------
#
#  1) `omnictl config context|identity|url|add|merge` all write the
#     omniconfig -- they can no longer do so. shared.yaml is the source of
#     truth; change it there. For a genuine one-off, work around it with
#     `omnictl --omniconfig <a writable copy>` or the OMNICONFIG env var.
#
#  2) Same for `kubectl config use-context`. There is only one context here
#     (omni-jyl-tyo, already the current-context), so it never comes up; for
#     multiple clusters later, use `kubectl --context <n>`.
#
#  -- Dependency ---------------------------------------------------------
#
#  The kubeconfig's exec auth requires kubectl-oidc_login on PATH, provided by
#  "kubelogin" in darwinHomebrew.brews (int128/kubelogin, not the Azure formula
#  of the same name). Homebrew runs with cleanup = "zap", so removing that brew
#  from apps.nix uninstalls it and kubectl breaks immediately -- hence the
#  assertion below pinning the dependency.
#
#  -- Filling in the ciphertext ------------------------------------------
#
#    just sops-edit shared
#
#  Both are whole files; paste them verbatim as | block scalars:
#
#    omni:
#        omniconfig: |
#            contexts:
#                default:
#                    url: https://...
#            context: default
#        kubeconfig: |
#            apiVersion: v1
#            kind: Config
#            ...
#
#  Then cd ../nix-secrets && git add -A && git commit && git push,
#  come back and run just update-nix-secrets && just rebuild, then:
#
#    just check-sops          # expect two green checks
#    kubectl config get-contexts
#    omnictl config info
#
#############################################################
let
  cfg = config.darwinOmni;
  user = config.hostSpec.username;
  home = config.hostSpec.home;
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";

  # sops encrypts **values** only; key names stay in cleartext in the YAML, so
  # a text search is enough to tell whether a key has been filled in. This is
  # not a strict structural check (it ignores nesting), but it is enough to
  # move "key not filled in yet" from an opaque activation-time sops error to
  # an actionable message at evaluation time.
  hasKey = key: builtins.pathExists sopsFile && lib.hasInfix "${baseNameOf key}:" (builtins.readFile sopsFile);
in {
  options.darwinOmni = {
    enable = lib.mkEnableOption "Omni / Kubernetes client configuration";

    omniConfigKey = lib.mkOption {
      type = lib.types.str;
      default = "omni/omniconfig";
      description = "Key path of the omniconfig in shared.yaml.";
    };

    kubeConfigKey = lib.mkOption {
      type = lib.types.str;
      default = "omni/kubeconfig";
      description = "Key path of the kubeconfig in shared.yaml.";
    };

    omniConfigPath = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.talos/omni/config";
      description = ''
        Where the omniconfig lands. This is omnictl 1.9's own default --
        **not** ~/.config/omni/config. That XDG path is marked deprecated and
        is only used as a last resort when reading an existing config; newly
        written config never goes there.
      '';
    };

    kubeConfigPath = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.kube/config";
      description = "Where the kubeconfig lands. Using the default path means no more export KUBECONFIG.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = hasKey cfg.omniConfigKey && hasKey cfg.kubeConfigKey;
        message = ''
          darwinOmni is enabled, but secrets/shared.yaml has no
          ${cfg.omniConfigKey} / ${cfg.kubeConfigKey} yet.

            just sops-edit shared

          Paste them in using the structure documented in the header of
          modules/hosts/darwin/omni/default.nix (both as | block scalars, the
          whole file verbatim), then
          cd ../nix-secrets && git add -A && git commit && git push
          and back here run just update-nix-secrets.

          Without this assertion the error would be deferred to activation
          time and thrown by sops-install-secrets, where you cannot tell which
          key is missing.
        '';
      }
      {
        assertion = lib.elem "kubelogin" config.darwinHomebrew.brews;
        message = ''
          darwinOmni requires "kubelogin" to stay in darwinHomebrew.brews.

          The kubeconfig uses exec auth (kubectl oidc-login get-token), and
          without kubectl-oidc_login on PATH kubectl cannot reach the cluster.
          Homebrew runs with cleanup = "zap", so deleting it from apps.nix is
          the same as uninstalling it.
        '';
      }
    ];

    # owner must be the user: kubectl / omnictl run as the user, and
    # sops-nix defaults to owner = root on Darwin, which they could not read.
    sops.secrets.${cfg.omniConfigKey} = {
      inherit sopsFile;
      owner = user;
      mode = "0400";
      path = cfg.omniConfigPath;
    };

    sops.secrets.${cfg.kubeConfigKey} = {
      inherit sopsFile;
      owner = user;
      mode = "0400";
      path = cfg.kubeConfigPath;
    };

    # Pre-create the parent directories.
    #
    # sops-install-secrets does MkdirAll the parents of its symlinks
    # (pkgs/sops-install-secrets/main.go:259), but it does so **as root, with
    # 0777**. ~/.talos/omni does not exist yet, and once root creates it
    # omnictl would be working inside somebody else's directory.
    #
    # ~/.talos/keys is a different matter: that is where omnictl actually
    # stores the PGP private key (the default for --siderov1-keys-dir), and it
    # must be user-writable or the very first login fails. sops does not manage
    # that file, so sops will not create it for us.
    #
    # mkBefore is there to run ahead of sops-nix's own postActivation fragment
    # -- this option is types.lines, and a plain definition would share
    # sops-nix's order and sort by module position, which is not reliable.
    system.activationScripts.postActivation.text = lib.mkBefore ''
      # omni / kube client directories; the owner must be the user
      # (see modules/hosts/darwin/omni)
      install -d -o ${user} -g staff -m 0700 \
        ${builtins.dirOf cfg.omniConfigPath} \
        ${builtins.dirOf cfg.kubeConfigPath} \
        ${home}/.talos/keys
    '';
  };
}
