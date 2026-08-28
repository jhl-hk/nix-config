{...}:
#############################################################
#
#  Stay awake on AC
#
#  For a Mac that is administered over ssh: closing the lid or walking away
#  should not take it off the network. jhlsMacBookAir runs the OpenClaw
#  gateway and is reached over Tailscale, so a sleeping laptop reads to
#  everyone else as an outage.
#
#  -- Why pmset and not power.sleep --------------------------------------
#
#  nix-darwin's power.sleep.* is global: setting `computer = "never"` stops
#  idle sleep on battery too, which on a laptop means a flat battery in a bag.
#  Everything here is scoped to `-c` (AC) so battery behaviour keeps macOS's
#  defaults.
#
#  `sleep 0` alone is not enough. It only governs *idle* sleep; closing the
#  lid is a separate path, and the setting that governs it is `disablesleep`,
#  which is **undocumented** -- it appears in `pmset -g custom` output once
#  set but not in pmset(1). Because it is undocumented, whether it honours the
#  `-c` scope or silently applies globally is not something the man page can
#  answer, so the script reads the value back and says what it actually got
#  rather than assuming.
#
#  WARNING: a laptop that cannot sleep with the lid shut will keep running in
#     a closed bag if it is plugged into a battery bank. That is the trade
#     being made deliberately; on battery this changes nothing.
#
#############################################################
{
  system.activationScripts.postActivation.text = ''
    # AC only. `sleep 0` covers idle; `disablesleep 1` covers the lid.
    /usr/bin/pmset -c sleep 0 disablesleep 1

    # disablesleep is undocumented, so verify rather than assume. `pmset -g
    # custom` prints a section per power source; if the flag landed on the
    # battery side too, the scoping did not hold and that is worth knowing
    # before a laptop is left in a bag.
    if /usr/bin/pmset -g custom | awk '/Battery Power/,/AC Power/' \
        | grep -q 'disablesleep *1'; then
      echo "stay-awake.nix: warning -- disablesleep also applied to battery;" >&2
      echo "  macOS ignored the -c scope. Undo with: sudo pmset -a disablesleep 0" >&2
    fi
  '';
}
