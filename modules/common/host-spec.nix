{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  hostSpec -- the data bus
#
#  The repo's single cross-platform data channel. All three scopes
#  (NixOS / nix-darwin / home-manager) import this file, so the same data
#  reads the same everywhere.
#
#  Who writes to it:
#    hosts/common/core/default.nix  -- identity and topology, inherited from inputs.nix-secrets
#    hosts/<platform>/<host>/       -- hostName and this machine's switches
#
#  Who reads it: every module, always through config.hostSpec.<x>.
#  Module code must **never** reference inputs.nix-secrets directly -- that
#  indirection is exactly what makes secrets swappable, auditable, or
#  stubbable in one place.
#
#############################################################
let
  inherit (lib) mkOption types;

  # Shorthand for boolean switches, to skip the repetitive mkOption boilerplate.
  mkBoolOpt = default: description:
    mkOption {
      inherit default description;
      type = types.bool;
    };
in {
  options.hostSpec = mkOption {
    description = "This machine's identity, topology, and capability flags.";
    type = types.submodule {
      # Escape hatch: undeclared string keys are accepted too. Every option
      # declared explicitly below keeps its own stricter type; freeform only
      # catches the undeclared ones.
      freeformType = types.attrsOf types.str;

      options = {
        # ---- Identity ----
        username = mkOption {
          type = types.str;
          description = "Primary username. Drives users.users.<u>, home-manager.users.<u>, and the default for home.";
        };

        hostName = mkOption {
          type = types.str;
          description = "This machine's hostname. Also the index key into networkInfo.hosts.<hostName>.";
        };

        handle = mkOption {
          type = types.str;
          description = "Online handle (GitHub username and the like), used in ssh comments and dotfile templates.";
        };

        userFullName = mkOption {
          type = types.str;
          description = "Real name, used for git, GPG uids, and mail From headers.";
        };

        domain = mkOption {
          type = types.str;
          description = "Primary domain, used to build FQDNs.";
        };

        email = mkOption {
          type = types.attrsOf types.str;
          description = "Set of email addresses. Keys are defined by personal.nix in nix-secrets (user / gitHub / notifier ...).";
        };

        home = mkOption {
          type = types.str;
          default =
            if pkgs.stdenv.isLinux
            then "/home/${config.hostSpec.username}"
            else "/Users/${config.hostSpec.username}";
          description = "User home directory. The default is evaluated lazily inside the submodule, so using pkgs.stdenv here is safe.";
        };

        sshAllowedSigners = mkOption {
          type = types.listOf types.str;
          default = [];
          description = ''
            Contents of ~/.ssh/allowed_signers, one line per element.
            Used for git ssh signature verification. These are public keys, not
            ciphertext, so they live in the cleartext half of nix-secrets.
          '';
        };

        # ---- Free-form data coming from nix-secrets ----
        # Always treated as an opaque tree; read leaves with `.<key> or { }`
        # as a fallback.
        work = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "Employer-specific config bundle (proxies, CAs, internal registries). Must be non-empty when isWork = true.";
        };

        networking = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "General networking parameters (DNS, search domains, port tables). Overridden by the inherit in core.";
        };

        networkInfo = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = "Per-host network facts, shaped as networkInfo.hosts.<HostName> = { ip4; gateway4; ... }.";
        };

        serviceInfo = mkOption {
          type = types.attrsOf types.anything;
          default = {};
          description = ''
            Per-service endpoint data. Two kinds of key are mixed together:
              global    serviceInfo.<service>            usable from any host
              per-host  serviceInfo.<HostName>.<service> only applies to that machine
            Read them with a three-step fallback: per-host -> global -> empty.
          '';
        };

        persistFolder = mkOption {
          type = types.str;
          default = "";
          description = "Persistence root for impermanence. Only allowed to be empty while impermanence is off (there is an assertion).";
        };

        # ---- Capability flags ----
        isMinimal = mkBoolOpt false "Minimal system (installer / rescue media); skips home-manager.";
        isMobile = mkBoolOpt false "Laptop form factor; drives power management, suspend, backlight.";
        isProduction = mkBoolOpt true "Daily driver (as opposed to an experimental sandbox); used to silence noisy debug services.";
        isServer = mkBoolOpt false "Headless server; used to turn off desktop, login manager, audio.";
        isWork = mkBoolOpt false "Work machine. When true, work must be non-empty (there is an assertion).";
        isDarwin = mkBoolOpt false ''
          This machine is macOS.

          Read this wherever pkgs.stdenv.isDarwin would trigger infinite
          recursion (typically sops, and the platform selection in
          home/<u>/common/core/default.nix).

          Note that flake.nix also passes a separate top-level isDarwin through
          specialArgs. That one is decided by the flake from whichever builder
          was called; it is a different binding from hostSpec.isDarwin here.
          The values should agree, but the sources differ.
        '';
        useYubikey = mkBoolOpt false "Enable YubiKey-related config (pam-u2f, gpg-agent ssh, udev).";
        voiceCoding = mkBoolOpt false "Enable the voice-coding stack (talon / cursorless).";
        isAutoStyled = mkBoolOpt false "Opt into stylix for unified theming.";
        useNeovimTerminal = mkBoolOpt false "Replace terminal launcher bindings with an embedded nvim terminal.";
        useWindowManager = mkBoolOpt true "Enable a window manager. Set false on servers or pure-tty machines.";
        useAtticCache = mkBoolOpt true ''
          Enable the attic binary cache.

          A freshly installed machine stalls on cache fetches until routing
          works, so set this false for the first rebuild and turn it on once
          the network is healthy.
        '';
        hdr = mkBoolOpt false "Enable HDR in the compositor.";
        loadUserAgeKey = mkBoolOpt false "Load a user-scoped age key in addition to the host key.";

        wifi = mkBoolOpt false "This machine has a wireless NIC.";

        # ---- Display ----
        scaling = mkOption {
          type = types.str;
          default = "1";
          description = ''
            Scaling factor, stored as a string (e.g. "1.25") rather than a
            float, so it can be interpolated into config files verbatim without
            re-quoting.
          '';
        };
      };
    };
  };

  config = let
    inherit (config.hostSpec) isWork work persistFolder;

    # The home-manager scope has no `system` namespace; without this guard
    # evaluation fails outright.
    isImpermanent = (config ? "system") && (config.system.impermanence.enable or false);
  in {
    assertions = [
      {
        assertion = !isWork || (isWork && work != {});
        message = "hostSpec.work must be set whenever hostSpec.isWork = true.";
      }
      {
        assertion = !isImpermanent || (isImpermanent && persistFolder != "");
        message = "hostSpec.persistFolder must be set when impermanence is enabled.";
      }
    ];
  };
}
