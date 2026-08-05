{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  YubiKey authentication for sudo, falling back to Touch ID
#
#  The auth chain in /etc/pam.d/sudo_local (top to bottom, first success wins):
#
#    auth sufficient pam_u2f.so ...   touch the YubiKey, if one is plugged in
#    auth sufficient pam_tid.so       otherwise use the fingerprint reader
#    (below that, the stock pam_opendirectory from /etc/pam.d/sudo asks for a
#     password)
#
#  All three layers are sufficient, so **you cannot lock yourself out**: if
#  pam_u2f.so fails to load, or /run/secrets has not landed yet, or the current
#  user has no entry in the authfile -- each case just makes this one line fail,
#  PAM continues down the stack, and the password always backstops.
#
#  -- Two implementation traps -------------------------------------------
#
#  1) Do not write environment.etc."pam.d/sudo_local".text yourself (which is
#     what the upstream config does). nix-darwin's security/pam.nix already
#     defines that file, and ships an activation script that injects
#     `auth include sudo_local` into /etc/pam.d/sudo (macOS 13 has no automatic
#     include). Just mkBefore a line into
#     security.pam.services.sudo_local.text: that option is types.lines, and
#     mkBefore (500) sorts ahead of nix-darwin's own pam_tid.so line
#     (default order 1000), which is exactly the ordering we want.
#
#  2) Module arguments containing spaces need **double quotes**, not brackets.
#     `[cue_prompt=Touch YubiKey]` is Linux-PAM syntax; macOS uses OpenPAM,
#     whose openpam_readword() understands shell-style " ' \ quoting.
#     With brackets, pam_u2f receives fragments like `[cue_prompt=Touch` and
#     `YubiKey]` as unknown arguments and the prompt silently does nothing.
#
#  -- Registering a key takes three steps --------------------------------
#  1) Plug in the YubiKey and generate the mapping line (it will ask for a
#     touch):
#
#       nix shell nixpkgs#pam_u2f -c \
#         pamu2fcfg -u jhl -o pam://jhl.hk -i pam://jhl.hk
#
#     -o/-i must match the origin/appId options below **exactly**, otherwise
#     the credential computed at registration and at authentication time will
#     not agree and it will never verify.
#     Output looks like:  jhl:<keyHandle>,<pubKey>,es256,+presence
#
#  2) Write it into nix-secrets (only you can do this step):
#
#       just sops-edit shared
#
#     Contents (mind the block indentation after |; the value itself must have
#     no leading spaces):
#
#       yubikey:
#           u2f_keys: |
#               jhl:<keyHandle>,<pubKey>,es256,+presence
#
#     A backup key goes **on the same line**, separated by a colon -- a newline
#     would be parsed as a different user:
#       generate the second one with `pamu2fcfg -n -o ... -i ...`
#       (-n = omit the username prefix)
#
#     Then cd ../nix-secrets && git add -A && git commit && git push
#     and back here run `just update-nix-secrets`
#
#  3) Turn it on in the machine's hosts/darwin/<Host>/default.nix:
#       darwinYubikey.enable = true;
#     just rebuild, then confirm the ciphertext actually landed:
#       just check-sops        # expect a green check on /run/secrets/yubikey/u2f_keys
#     Then try `sudo -k && sudo true` in a fresh terminal.
#
#  If it does not verify, set darwinYubikey.debug = true, rebuild, and run sudo
#  again -- pam_u2f prints its reasoning straight to the terminal.
#
#############################################################
let
  cfg = config.darwinYubikey;
  sopsFile = "${inputs.nix-secrets}/secrets/shared.yaml";
in {
  options.darwinYubikey = {
    enable = lib.mkEnableOption "YubiKey authentication for sudo (falls back to Touch ID)";

    sopsKey = lib.mkOption {
      type = lib.types.str;
      default = "yubikey/u2f_keys";
      description = ''
        Key path in shared.yaml holding the pam_u2f mapping table. After
        decryption it lands at /run/secrets/<this value>, which pam_u2f reads
        as root.
      '';
    };

    origin = lib.mkOption {
      type = lib.types.str;
      default = "pam://${config.hostSpec.domain}";
      description = ''
        The FIDO2 relying party. Defaults to hostSpec.domain rather than
        pamu2fcfg's own pam://<hostname>, so one mapping table works across
        several machines. Changing it means re-running pamu2fcfg to register
        again.
      '';
    };

    appId = lib.mkOption {
      type = lib.types.str;
      default = cfg.origin;
      defaultText = lib.literalExpression "config.darwinYubikey.origin";
      description = "U2F appId. Keep it equal to origin unless you have a specific reason not to.";
    };

    cuePrompt = lib.mkOption {
      type = lib.types.str;
      default = "Touch YubiKey for sudo";
      description = "Prompt printed to the terminal while waiting for a touch. Without it pam_u2f only says \"Please touch the device.\"";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Turn on pam_u2f's debug output, printed straight to the terminal
        running sudo (pam_u2f's debug_file defaults to stderr). Only enable
        this while diagnosing a registration problem.

        Do not casually add debug_file=/var/log/pam_u2f.log -- for security
        reasons pam_u2f **will not create** that file, and if it does not
        exist nothing is logged at all, which looks like debug simply not
        working. To log to a file you must touch it into existence first.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Without this assertion, when nix-secrets has no secrets/shared.yaml yet,
    # sops-nix blows up inside builtins.hashFile with an opaque "file not
    # found". Better to say something actionable here.
    assertions = [
      {
        assertion = builtins.pathExists sopsFile;
        message = ''
          darwinYubikey is enabled, but nix-secrets has no
          secrets/shared.yaml yet.

          First register the key (plug in the YubiKey; it will ask for a touch):
            nix shell nixpkgs#pam_u2f -c \
              pamu2fcfg -u ${config.hostSpec.username} -o ${cfg.origin} -i ${cfg.appId}

          Put the output into the ciphertext:
            just sops-edit shared
              yubikey:
                  u2f_keys: |
                      <the whole line from the previous step>

          Then cd ../nix-secrets && git add -A && git commit && git push
          and back here run `just update-nix-secrets`, then `just rebuild`.

          If you are not ready yet, turn off darwinYubikey.enable in
          hosts/darwin/<Host>/default.nix and sudo falls back to plain
          Touch ID.
        '';
      }
    ];

    # owner/group/mode are all sops-nix darwin defaults (root:staff 0400).
    # They are spelled out because *who reads this* is the key premise of the
    # module: sudo's PAM stack runs as root, so there is no need for
    # openasuser and no need to put the mapping table in the user's home.
    sops.secrets.${cfg.sopsKey} = {
      inherit sopsFile;
      owner = "root";
      mode = "0400";
    };

    security.pam.services.sudo_local.text = let
      args =
        [
          "authfile=${config.sops.secrets.${cfg.sopsKey}.path}"
          "origin=${cfg.origin}"
          "appid=${cfg.appId}"
          "cue"
          "\"cue_prompt=${cfg.cuePrompt}\""
        ]
        ++ lib.optional cfg.debug "debug";
    in
      # Deliberately no nouserok -- that would let a user with no authfile
      # entry straight through.
      # No trailing newline: types.lines adds "\n" when merging, and writing
      # one here would leave a blank line between the two auth lines.
      lib.mkBefore "auth       sufficient     ${pkgs.pam_u2f}/lib/security/pam_u2f.so ${lib.concatStringsSep " " args}";

    # pamu2fcfg, needed when rotating keys or adding a backup.
    environment.systemPackages = [pkgs.pam_u2f];
  };
}
