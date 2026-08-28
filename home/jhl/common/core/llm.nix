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

  llm.providers.JianyueLab = {
    apiUrl = "https://llm.jianyuelab.net/v1";
    models = builtins.fromJSON (builtins.readFile ./llm/models.json);

    # Pinned rather than left to the option default. That default is "the first
    # entry of the sorted list", which is a fact about the alphabet, not a
    # choice -- it silently moved from codex-auto-review to deepseek-v4-flash
    # the moment the gateway retired a model. Naming it here makes every
    # consumer (pi, opencode, Zed's default_model / commit_message_model /
    # edit_predictions) agree, and makes a change to it a diff.
    defaultModel = "deepseek-v4-flash";

    # The name contains capitals, so the default will not do. Zed computes
    #   format!("{}_API_KEY", id).to_case(Case::UpperSnake)
    # and convert_case cuts at the e->L lower-to-upper boundary, giving
    # JIANYUE_LAB rather than JIANYUELAB.
    # See the file header of modules/home/llm.nix for how to verify this.
    envVar = "JIANYUE_LAB_API_KEY";
  };

  # The second gateway. Same shape, different host and credential -- and a
  # different key name, so llm/api_key and llm_api/api_key are two separate
  # sops secrets, declared together in
  # hosts/common/optional/darwin/llm.nix.
  #
  # models-api.json starts as [] and stays that way until `just llm-models`
  # can reach the endpoint. That is deliberate: the module treats an empty
  # list as "skip this provider entirely", so a machine that has never
  # refreshed it generates no half-configured provider for Zed or opencode
  # rather than one pointing at zero models.
  llm.providers.JianyueLabAPI = {
    apiUrl = "https://llm-api.jianyuelab.net/v1";
    models = builtins.fromJSON (builtins.readFile ./llm/models-api.json);

    # Set explicitly for the reason the file header spells out: Zed derives
    # this name itself and convert_case splits at lower->upper boundaries, so
    # a name with capitals never matches the plain-toUpper default.
    envVar = "JIANYUELAB_API_KEY";

    # Its own secret; see the option's description in modules/home/llm.nix.
    apiKeyFile = "/run/secrets/llm_api/api_key";
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
