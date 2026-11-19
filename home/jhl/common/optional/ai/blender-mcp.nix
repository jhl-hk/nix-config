{pkgs, ...}:
#############################################################
#
#  Blender MCP -- the official Blender Lab server, for omp
#
#  https://projects.blender.org/lab/blender_mcp
#
#  Two halves, talking over TCP 9876:
#    - the "MCP" add-on inside Blender, installed from the Blender Lab
#      extension repo (Blender manages it, not nix);
#    - the stdio server below, which omp launches through uvx.
#
#  Blender comes from hosts/common/optional/darwin/blender.nix -- keep the pair.
#  The add-on needs Preferences > System > Allow Online Access.
#
#  Added to omp.mcpServers, which ./omp.nix merges into ~/.omp/agent/mcp.json;
#  import the two together.
#
#############################################################
let
  version = "1.0.3";
in {
  omp.mcpServers.blender = {
    type = "stdio";
    command = "${pkgs.uv}/bin/uvx";
    args = [
      "--from"
      "git+https://projects.blender.org/lab/blender_mcp.git@v${version}#subdirectory=mcp"
      "blender-mcp"
    ];
  };
}
