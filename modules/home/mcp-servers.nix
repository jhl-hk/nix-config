{lib, ...}:
#############################################################
#
#  MCP servers
#
#  One list of remote MCP servers, mapped by each agent tool into its own
#  config format. All are streamable-HTTP servers that authenticate through
#  OAuth, so nothing here is secret; each tool stores its own token after the
#  first sign-in.
#
#  Consumers:
#    home/jhl/common/core/claude.nix               ~/.claude.json
#    home/jhl/common/core/opencode.nix             opencode.json
#    home/jhl/common/optional/ai/codex.nix         ~/.codex/config.toml
#    home/jhl/common/optional/ai/antigravity.nix   ~/.gemini/config/mcp_config.json
#    home/jhl/common/optional/ai/openclaw.nix      ~/.openclaw/openclaw.json
#
#  grok and omp need no entry: both load ~/.claude.json's mcpServers through
#  their Claude-compat layer. harness takes stdio servers only, and pi and llm
#  have no MCP client, so they are not wired.
#
#############################################################
{
  options.mcpServers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.url = lib.mkOption {
        type = lib.types.str;
        description = "Streamable-HTTP endpoint of the server.";
      };
    });
    default = {
      passport-admin.url = "https://passport-api.jianyuelab.net/account/admin/mcp";
      cloudflare-api.url = "https://mcp.cloudflare.com/mcp";
      uptime.url = "https://status.jianyuelab.net/mcp";
      memory.url = "https://memory.jianyuelab.co/mcp";
    };
    description = "Remote MCP servers, keyed by the name each tool shows.";
  };
}
