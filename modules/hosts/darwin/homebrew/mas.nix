{
  config,
  lib,
  pkgs,
  ...
}:
#############################################################
#
#  Mac App Store apps -- installed outside brew bundle
#
#  The declaration surface stays darwinHomebrew.masApps (see ./default.nix);
#  this file is what actually installs them, and nix-darwin's own
#  `homebrew.masApps` is left empty on purpose. Two reasons:
#
#  1. Version detection. Nix evaluates purely, so the Brewfile is fixed
#     before anything can look at `sw_vers`. mas cannot install on a macOS
#     seed build, and which machine is on one changes without any commit
#     here -- so the decision has to happen at activation time, not eval
#     time. This replaces the hand-set `darwinHomebrew.macosBeta` flag,
#     which was one more thing to remember after every OS update.
#
#  2. mas failures used to abort the whole Brewfile. `brew bundle install`
#     is `result || exit(1)` (bundle/subcommand/install.rb) with the
#     cleanup step *after* that line, and Homebrew's mas installer ignores
#     `--no-upgrade` and runs `mas upgrade` on every already-installed app
#     (bundle/extensions/mac_app_store.rb). One App Store app that will not
#     upgrade therefore silently disabled `onActivation.cleanup = "zap"`
#     for taps, brews and casks alike -- undeclared casks survived switch
#     after switch. Nothing in this file can take brew bundle down with it.
#
#  What this gives up: brew bundle no longer sees the mas entries, so zap
#  cleanup does not uninstall App Store apps that are no longer declared.
#  mas is now install-only -- the guarantee is "everything declared is
#  present", not "nothing else is". Removing an entry from masApps means
#  dragging the app to the Trash by hand.
#
#  Install-only is also why `mas upgrade` is absent: upgrading on every
#  switch is what broke above, and an App Store update needs the App Store
#  (or a deliberate `mas upgrade`), not a system rebuild.
#
#############################################################
let
  cfg = config.darwinHomebrew;
  inherit (config.hostSpec) username;

  # Apple's build numbers separate release from seed by the shape of the
  # trailing number: a release is 2-3 digits (27.0 shipped as 26A428), a
  # seed is 4 digits starting at 5 plus a letter (26A5388g). The
  # SoftwareUpdate CatalogURL is *not* a usable signal -- it says the
  # machine is enrolled in the seed programme, not that it booted a seed,
  # and jhlsMacBookPro is enrolled while running release software.
  seedBuildPattern = "^[0-9]+[A-Z][5-9][0-9]{3}[a-z]?$";

  # mas needs the user's App Store session; as root it sees no account.
  # Same sudo shape nix-darwin uses for `brew bundle`.
  asUser = "sudo --user=${username} --set-home ${lib.getExe pkgs.mas}";

  installOne = name: id: ''
    if ! grep -qx '${toString id}' <<<"$masInstalledIds"; then
      echo >&2 "  installing ${name} (${toString id})"
      ${asUser} install ${toString id} >&2 \
        || echo >&2 "  warning: ${name} (${toString id}) did not install -- is an Apple ID signed in, and is the app in its purchase history?"
    fi
  '';
in {
  config = lib.mkIf (cfg.enable && cfg.masApps != {}) {
    system.activationScripts.postActivation.text = ''
      # Mac App Store apps (modules/hosts/darwin/homebrew/mas.nix)
      masBuild=$(/usr/bin/sw_vers -buildVersion)
      if [[ "$masBuild" =~ ${seedBuildPattern} ]]; then
        echo >&2 "mas: skipping ${toString (builtins.length (builtins.attrNames cfg.masApps))} App Store apps -- macOS $masBuild is a seed build"
      else
        echo >&2 "mas: checking App Store apps..."

        # `mas list` prints "<id>  <name>  (<version>)". A missing Apple ID
        # session is not an error here -- it yields an empty list, every app
        # looks absent, and each install below warns for itself.
        masInstalledIds=$(${asUser} list 2>/dev/null | awk '{print $1}') || masInstalledIds=""

        ${lib.concatStrings (lib.mapAttrsToList installOne cfg.masApps)}
      fi
    '';
  };
}
