{
  config,
  lib,
  ...
}:
#############################################################
#
#  jyl-usage -- Claude Code token usage -> llm-web portal
#
#  The plugin itself is user state, not managed here: it is installed with
#  `claude plugin i` and recorded in settings.json, the same unmanaged half
#  claude-code-wakatime lives in (see the header of ./claude.nix).
#
#    claude plugin marketplace add JianyueLab/claude-plugin
#    claude plugin i jyl-usage@jianyuelab-claude
#
#  What *is* managed is its configuration, which is two values: the portal
#  origin and a portal key.
#
#  -- Why this reuses llm/api_key rather than adding a secret --------------
#
#  The plugin POSTs to <origin>/v1/usage/ingest, and that route authenticates
#  with a portal key like every other /v1 route on llm-web. That is the same
#  credential ./llm.nix already feeds to Zed and opencode as
#  JIANYUE_LAB_API_KEY, so a second copy of it in shared.yaml would be two
#  things to rotate instead of one.
#
#  Consequently there is no new sops.secrets block and no new assertion --
#  hosts/common/optional/darwin/llm.nix already declares the ciphertext and
#  already fails at evaluation time when shared.yaml has no llm.api_key.
#  This file only reads config.llm.apiKeyFile, so a rename over there moves
#  this too.
#
#  -- Why baseUrl rides in .zshrc and not home.sessionVariables -----------
#
#  It is not a secret, so sessionVariables is where it belongs on paper, and
#  that is where it started. It does not work here, for a reason worth keeping
#  written down: hm-session-vars.sh opens with
#
#    if [ -n "${__HM_SESS_VARS_SOURCED-}" ]; then return; fi
#
#  so a shell whose ancestor already sourced an **older** generation inherits
#  that sentinel and skips the new file wholesale. The key below comes from
#  .zshrc, which carries no such guard and re-runs in every interactive shell.
#  Split across the two mechanisms, the observed failure is the confusing one:
#  the reporter has a key, has no base URL, and silently sends nothing until
#  the user happens to open a terminal with no shell ancestry.
#
#  Both values now arrive by the same path, in the same shell, or neither
#  does. That is the property that matters -- the plugin needs the pair.
#
#  Note it is the **origin**: the plugin appends /v1/usage/ingest itself, and
#  a trailing /v1 here would be stripped rather than 404ing -- but ./llm.nix's
#  apiUrl, which does end in /v1, is a different kind of value. They are not
#  interchangeable.
#
#  -- Terminal only, deliberately ----------------------------------------
#
#  ./llm.nix injects its key twice, in zsh and through a launchd agent, because
#  Zed gets launched from the Dock. Claude Code is started from a terminal, so
#  the shell export is enough and this avoids a second key in the
#  login-session-global environment that launchctl setenv creates.
#
#  If you ever run the Claude Code desktop app, its hooks will not see this
#  variable. The fallback is the plugin's own config file, which reads
#  {"baseUrl": ..., "apiKey": ...} from ~/.claude/jyl-usage/config.json --
#  render it with sops.templates on the system side, the way npmrc.nix does.
#
#  WARNING: an install with no key is inert and **silent** -- the plugin does
#     nothing at all rather than logging that it is unconfigured. After a
#     rebuild, confirm it actually reports:
#
#       "$CLAUDE_PLUGIN_ROOT/scripts/run" --status
#
#     or /jyl-usage inside Claude Code. It should say "reporting", not
#     "NOT reporting".
#
#############################################################
{
  # The key line has the same shape, and the same reasoning, as the exportLine
  # in ./llm.nix: sops's launchd daemon rebuilds /run/secrets only after boot,
  # so an unreadable file is skipped rather than exporting an empty string. An
  # empty JYL_API_KEY would read as "configured" to the plugin and produce 401s
  # it then spools.
  programs.zsh.initContent = ''
    export JYL_USAGE_BASE_URL="https://llm.jianyuelab.net"
    [ -r ${config.llm.apiKeyFile} ] && export JYL_API_KEY="$(cat ${config.llm.apiKeyFile})"
  '';
}
