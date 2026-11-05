{
  config,
  lib,
  pkgs,
  ...
}:
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
#  Merged into ~/.omp/agent/mcp.json by name: omp also writes that file
#  (`/mcp add`), so it is not linked from the store.
#
#############################################################
let
  version = "1.0.3";

  servers.blender = {
    type = "stdio";
    command = "${pkgs.uv}/bin/uvx";
    args = [
      "--from"
      "git+https://projects.blender.org/lab/blender_mcp.git@v${version}#subdirectory=mcp"
      "blender-mcp"
    ];
  };

  mcpJsonPath = "${config.home.homeDirectory}/.omp/agent/mcp.json";

  merge = pkgs.writeText "merge-omp-mcp.py" ''
    import json, os, sys, tempfile

    path, servers = sys.argv[1], json.loads(sys.argv[2])
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        data = {}
    data["mcpServers"] = {**data.get("mcpServers", {}), **servers}

    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".mcp.json.")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, path)
  '';
in {
  home.activation.ompBlenderMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -v DRY_RUN ]]; then
      echo "blender-mcp.nix: would merge MCP servers into ${mcpJsonPath}"
    elif ! ${pkgs.python3}/bin/python3 -I ${merge} \
      ${lib.escapeShellArg mcpJsonPath} \
      ${lib.escapeShellArg (builtins.toJSON servers)}; then
      echo "blender-mcp.nix: MCP merge failed, left ${mcpJsonPath} untouched" >&2
    fi
  '';
}
