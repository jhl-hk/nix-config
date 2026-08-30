{
  config,
  lib,
  hostSpec,
  ...
}:
#############################################################
#
#  LLM provider instances + API key injection
#
#  The options themselves live in modules/home/llm.nix, which documents the
#  overall design. This file does three things: declare the provider, get the
#  key into the terminal, and get the key into GUI apps.
#
#  -- Why the model list is generated ------------------------------------
#
#  llm/models.json is produced by `just llm-models` hitting /v1/models.
#  It is not fetched from within nix because flake evaluation has no network
#  (and that endpoint needs a key anyway -- a bare GET returns 401, verified).
#  Generating a file and readFile-ing it keeps the list declarative: in git,
#  diffable, revertable, and refreshed with one command.
#
#  Refreshing it is automatic: rebuild-pre runs llm-models on every switch, in
#  its non-fatal wrapper, so an offline machine still rebuilds against the
#  committed list. Run `just llm-models` by hand to see the current list, or to
#  find out *why* it is not refreshing -- standalone it is strict and prints
#  the failure.
#
#  -- Why the key is injected twice, on macOS ----------------------------
#
#  An export in zsh only reaches processes started from a terminal. When Zed is
#  launched from the Dock or Spotlight its parent is launchd, no shell is
#  involved, and it never sees that variable. On macOS, launchctl setenv is the
#  only way to make an environment variable visible to GUI processes.
#
#  The cost, stated plainly: setenv is **login-session global**, so every GUI
#  process in that session can read this key. If that is unacceptable, disable
#  the agent and type the key into Zed once so it lands in the Keychain.
#
#  -- and why Linux only gets the terminal half --------------------------
#
#  The launchd block is gated on isDarwin. Without the gate it would still be
#  harmless -- home-manager defaults launchd.enable to isDarwin, so no plist is
#  ever written -- but "inert because of somebody else's default" is not a
#  thing to rely on, and it reads as though GUI injection works everywhere.
#
#  There is a Linux equivalent if it is ever wanted: home-manager already
#  writes ~/.config/environment.d/10-home-manager.conf, which systemd's user
#  manager imports into the graphical session. It is not used here because it
#  takes literal values -- it cannot shell out to read a file the way the
#  launchd agent does -- so putting the key there would mean writing it into
#  the nix store, which is exactly what modules/home/llm.nix refuses to do.
#
#  Moot on the standalone home-manager lane regardless: it has no system scope
#  and therefore no sops, so apiKeyFile never exists and even the zsh export
#  below skips itself. That lane is empty today -- jhlsArchLinux was its only
#  machine and has been retired.
#
#############################################################
let
  cfg = config.llm;

  # Only providers with a refreshed model list need the key injected
  active = lib.filterAttrs (_: p: p.models != []) cfg.providers;

  # Shell fragment that reads the key. The file may not have landed yet
  # (sops's launchd daemon rebuilds /run/secrets only after boot), so an
  # unreadable file is skipped silently rather than setting the variable to an
  # empty string -- an empty key would make Zed think it is configured.
  # Falls back to the module-level path, so the original provider keeps
  # working unchanged while the second one names its own secret.
  keyFileOf = p:
    if p.apiKeyFile != null
    then p.apiKeyFile
    else cfg.apiKeyFile;

  exportLine = p: ''
    [ -r ${keyFileOf p} ] && export ${p.envVar}="$(cat ${keyFileOf p})"
  '';
in {
  llm.defaultProvider = "JianyueLab";

  # One provider, not two. Zed, opencode and pi each render a single
  # api_url/baseURL per provider and none of them has a fallback field, so a
  # second provider would be a second thing to pick from a menu, not a
  # failover. The choice is made at refresh time instead: `just llm-models`
  # probes both gateways and writes the first one that answered into
  # llm/active.json, along with its key path and its own model list.
  #
  # Preference is llm.jianyuelab.net, falling back to llm-api.jianyuelab.net.
  # It follows that the two lists are not interchangeable -- llm-api serves
  # Ornith-1.5-35B-A3B and deepseek-v4-flash, llm does not -- which is why the
  # models come out of the same file as the URL rather than from a fixed path.
  #
  # Not request-time failover: a gateway that dies after a rebuild stays
  # selected until the next `just llm-models`. Real failover would have to
  # live in front of both hosts, not in three editor configs.
  llm.providers.JianyueLab = let
    active = builtins.fromJSON (builtins.readFile ./llm/active.json);
  in {
    inherit (active) apiUrl models apiKeyFile;

    # Pinned rather than left to the option default, which is "the first entry
    # of the sorted list" -- a fact about the alphabet, not a choice. It moved
    # on its own once already when the gateway retired a model.
    defaultModel = "gpt-5.6-sol";

    # The name contains capitals, so the default will not do. Zed computes
    #   format!("{}_API_KEY", id).to_case(Case::UpperSnake)
    # and convert_case cuts at the e->L boundary, giving JIANYUE_LAB rather
    # than JIANYUELAB. See the header of modules/home/llm.nix.
    envVar = "JIANYUE_LAB_API_KEY";
  };

  # Terminal: this is the path for opencode and for zed started from a shell
  programs.zsh.initContent = lib.mkIf (active != {}) (
    lib.concatStrings (lib.mapAttrsToList (_: exportLine) active)
  );

  # GUI: this is the path when Zed is launched from the Dock. macOS only --
  # see the header for the Linux situation.
  launchd.agents = lib.optionalAttrs hostSpec.isDarwin (lib.mapAttrs' (name: p:
    lib.nameValuePair "llm-env-${name}" {
      enable = true;
      config = {
        RunAtLoad = true;
        ProcessType = "Background";
        # At boot there is no guarantee whether sops's launchd daemon or this
        # agent runs first, so poll for a while before giving up rather than
        # exiting on the first unreadable read.
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''
            for _ in $(seq 1 30); do
              if [ -r ${keyFileOf p} ]; then
                /bin/launchctl setenv ${p.envVar} "$(cat ${keyFileOf p})"
                exit 0
              fi
              sleep 2
            done
            exit 0
          ''
        ];
      };
    })
  active);
}
