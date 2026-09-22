{pkgs, ...}:
#############################################################
#
#  Git config for Homebrew's sandboxed source fetches (macOS)
#
#  Homebrew 7 runs the **download** step of a `:using => :git` formula inside
#  sandbox-exec. That sandbox denies every unix-socket connect and bind except
#  the ones it allowlists by name:
#
#      (deny network-outbound (to unix-socket))
#
#  ../ssh.nix sets ControlMaster auto + ControlPath ~/.ssh/master-%r@%n:%p for
#  Host *, so ssh tries to bind a multiplexing socket and dies before it ever
#  authenticates:
#
#      unix_listener: cannot bind to path /Users/jhl/.ssh/master-git@github.com:22.XXXX:
#      Operation not permitted
#      fatal: Could not read from remote repository.
#
#  The agent itself is fine -- GitDownloadStrategy#allow_fetch_credentials
#  allowlists $SSH_AUTH_SOCK and passes it through -- so the YubiKey keys still
#  sign. Only the control socket is the problem, and it is pure optimisation.
#
#  **The formula URL has to be an ssh:// one for any of that to happen.**
#  Homebrew decides whether to allow ~/.ssh and the agent socket from the
#  formula's literal `url`, in GitDownloadStrategy#ssh?, before git runs. An
#  `insteadOf` rewrite here is too late to flip it and does nothing.
#
#  Scoped by gitdir so ControlMaster survives everywhere else; Homebrew's git
#  cache is the only place it has to be off. Verified that a gitdir include
#  does apply during `git clone` to the destination path, not just to fetches
#  in an existing repo -- the clone is where this first bites.
#
#  /usr/bin/ssh rather than Homebrew's: this has to work while Homebrew is
#  mid-upgrade, and `onActivation.cleanup = "zap"` means /opt/homebrew/bin/ssh
#  is not a path to depend on for the thing that installs Homebrew packages.
#  Agent signing works the same on both -- the YubiKey is the agent's problem,
#  not ssh's.
#
#############################################################
let
  brewFetch = pkgs.writeText "gitconfig-homebrew-fetch" ''
    [core]
    	sshCommand = /usr/bin/ssh -o ControlMaster=no -o ControlPath=none
  '';
in {
  programs.git.includes = [
    {
      condition = "gitdir:~/Library/Caches/Homebrew/";
      path = "${brewFetch}";
    }
  ];
}
