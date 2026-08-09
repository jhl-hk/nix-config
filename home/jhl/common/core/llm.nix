{
  config,
  lib,
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
#  -- Why the key is injected twice --------------------------------------
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
#############################################################
let
  cfg = config.llm;

  # Only providers with a refreshed model list need the key injected
  active = lib.filterAttrs (_: p: p.models != []) cfg.providers;

  # Shell fragment that reads the key. The file may not have landed yet
  # (sops's launchd daemon rebuilds /run/secrets only after boot), so an
  # unreadable file is skipped silently rather than setting the variable to an
  # empty string -- an empty key would make Zed think it is configured.
  exportLine = p: ''
    [ -r ${cfg.apiKeyFile} ] && export ${p.envVar}="$(cat ${cfg.apiKeyFile})"
  '';
in {
  llm.defaultProvider = "JianyueLab";

  llm.providers.JianyueLab = {
    apiUrl = "https://llm.jianyuelab.net/v1";
    models = builtins.fromJSON (builtins.readFile ./llm/models.json);

    # The name contains capitals, so the default will not do. Zed computes
    #   format!("{}_API_KEY", id).to_case(Case::UpperSnake)
    # and convert_case cuts at the e->L lower-to-upper boundary, giving
    # JIANYUE_LAB rather than JIANYUELAB.
    # See the file header of modules/home/llm.nix for how to verify this.
    envVar = "JIANYUE_LAB_API_KEY";
  };

  # Terminal: this is the path for opencode and for zed started from a shell
  programs.zsh.initContent = lib.mkIf (active != {}) (
    lib.concatStrings (lib.mapAttrsToList (_: exportLine) active)
  );

  # GUI: this is the path when Zed is launched from the Dock
  launchd.agents = lib.mapAttrs' (name: p:
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
              if [ -r ${cfg.apiKeyFile} ]; then
                /bin/launchctl setenv ${p.envVar} "$(cat ${cfg.apiKeyFile})"
                exit 0
              fi
              sleep 2
            done
            exit 0
          ''
        ];
      };
    })
  active;
}
