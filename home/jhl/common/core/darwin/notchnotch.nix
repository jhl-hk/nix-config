{inputs, ...}:
#############################################################
#
#  NotchNotch -- plugins and preferences
#
#  The app is the jianyuelab/tap/notchnotch cask in
#  hosts/common/optional/darwin/desktop.nix. The omp plugin (extension and
#  manifest) is linked by ../../optional/ai/omp.nix, next to the rest of omp.
#
#  Plugins are directories under ~/Library/Application Support/NotchNotch/
#  Plugins/, each with a manifest.json. The app follows symlinks, so store
#  paths work. notchnotch-agents is the signed release zip (flake input);
#  the binary must keep its Developer ID signature, so it is not rebuilt here.
#
#  Preferences live in the co.jianyuelab.NotchNotch defaults domain and are
#  written by targets.darwin.defaults (`defaults import`, merge semantics:
#  keys not listed here are left alone). The app can still change these at
#  runtime from Settings; the next switch writes them back.
#
#  Not synced: language, weather, clipboard and schedule settings, which are
#  chosen in the app.
#
#############################################################
{
  home.file."Library/Application Support/NotchNotch/Plugins/co.jianyuelab.notchnotch.agents".source = "${inputs.notchnotch-agents}";

  targets.darwin.defaults."co.jianyuelab.NotchNotch" = {
    # Local event API on 127.0.0.1:7823 (hook scripts, omp plugin).
    "co.jianyuelab.NotchNotch.httpListenerEnabled" = true;
    # Agent Detection plugin (process scanning).
    "co.jianyuelab.NotchNotch.plugin.co.jianyuelab.notchnotch.agents.enabled" = true;
    # omp plugin (turn ends and conversation titles from the omp extension).
    "co.jianyuelab.NotchNotch.plugin.co.jianyuelab.notchnotch.omp.enabled" = true;
  };
}
