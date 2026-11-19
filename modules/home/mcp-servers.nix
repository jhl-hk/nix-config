{lib, ...}:
#############################################################
#
#  MCP servers
#
#  One list of remote MCP servers. All are streamable-HTTP servers that
#  authenticate through OAuth, so nothing here is secret; omp stores its own
#  token after the first sign-in.
#
#  Consumer: home/jhl/common/optional/ai/omp.nix, which merges them into
#  ~/.omp/agent/mcp.json.
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
