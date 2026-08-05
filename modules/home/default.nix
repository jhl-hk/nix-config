{lib, ...}:
# Auto-import every sibling .nix file and subdirectory (except this
# default.nix itself). Dropping a file in here is all it takes -- there is
# nowhere to register it.
{
  imports = lib.custom.scanPaths ./.;
}
