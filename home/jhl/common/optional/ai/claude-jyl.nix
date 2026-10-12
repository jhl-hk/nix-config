{
  config,
  lib,
  ...
}:
#############################################################
#
#  Claude Code -- JianyueLab gateway
#
#  Points Claude Code at the gateway's Anthropic Messages endpoint instead of
#  an Anthropic login. Terminal only: the variables are exported from zsh.
#
#  ANTHROPIC_BASE_URL is the origin, not the /v1 base. Claude Code appends
#  /v1/messages itself.
#
#  The gateway serves no claude-* models, so each tier maps to a gateway model.
#  The default model is the Fable tier's.
#
#############################################################
let
  gateway = config.llm.providers.JianyueLab;
  keyFile =
    if gateway.apiKeyFile != null
    then gateway.apiKeyFile
    else config.llm.apiKeyFile;
  origin = lib.removeSuffix "/v1" gateway.apiUrl;

  # Every tier Claude Code knows. An unmapped tier requests a claude-* id the
  # gateway does not serve. _NAME and _DESCRIPTION are what /model shows.
  tiers = {
    FABLE = "gpt-6-astra";
    OPUS = "gpt-6.1-sol";
    SONNET = "gpt-6-sol";
    HAIKU = "gpt-6-terra";
  };
  tierExports = tier: m: ''
    export ANTHROPIC_DEFAULT_${tier}_MODEL="${m}"
    export ANTHROPIC_DEFAULT_${tier}_MODEL_NAME="${m}"
    export ANTHROPIC_DEFAULT_${tier}_MODEL_DESCRIPTION="JianyueLab gateway"
  '';
in {
  # Same guard as llm.nix: no key file, no export, so Claude Code never sees an
  # empty token.
  programs.zsh.initContent = ''
    if [ -r ${keyFile} ]; then
      export ANTHROPIC_BASE_URL="${origin}"
      export ANTHROPIC_AUTH_TOKEN="$(cat ${keyFile})"
      export ANTHROPIC_MODEL="${tiers.OPUS}"
    ${lib.concatStrings (lib.mapAttrsToList tierExports tiers)}fi
  '';
}
