{...}:
#############################################################
#
#  Stats (exelban/stats) Configuration
#
#  Stats itself is installed by a Homebrew cask (see
#  hosts/common/darwin/apps.nix). It has no config file -- every setting lives
#  in the `eu.exelban.Stats` user defaults domain, so home-manager's
#  targets.darwin.defaults writes them. Underneath that is `defaults import`,
#  which has merge semantics (verified: keys already present before the import
#  are not wiped), so the deliberately-unsynced runtime state below survives.
#
#  Note: Stats writes its whole in-memory settings back on quit. Quit Stats
#  before a switch, or the running process will overwrite the freshly written
#  values.
#
#  Deliberately not synced (machine state / hardware, not preferences):
#    remote_id, remote_tokens_migrated_to_keychain  - per-machine identity
#    runAtLoginInitialized, setupProcess            - first-run markers
#    support_*, updater_*, version                  - runtime timestamps
#    NSWindow Frame / NSToolbar Configuration       - window geometry, follows resolution
#    NSStatusItem Preferred Position *              - menu bar pixel positions
#    Network_usageReset_next                        - a timestamp that rolls forward on its own
#    fan_0_*, fan_1_*                               - fan state, which the Air does not even have
#
#############################################################
{
  targets.darwin.defaults."eu.exelban.Stats" = {
    # ---- Application level ----
    LaunchAtLoginNext = true;
    telemetry = false;
    "update-interval" = "Silent";

    # ---- Module toggles ----
    CPU_state = false;
    GPU_state = false;
    Disk_state = false;
    Battery_state = false;
    RAM_state = true;
    Sensors_state = true;
    # Network has no explicit state key on this machine (i.e. it uses the
    # default = on). Pinned here so another machine does not depend on what
    # Stats happens to default to
    Network_state = true;

    # ---- RAM ----
    RAM_widget = "pie_chart";
    RAM_pie_chart_label = false;
    RAM_pie_chart_monochrome = false;
    # Widget ordering in the settings UI
    RAM_pieChart_position = 0;
    RAM_label_position = 1;
    RAM_lineChart_position = 2;
    RAM_mini_position = 3;
    RAM_barChart_position = 4;
    RAM_memory_position = 5;
    RAM_tachometer_position = 6;
    RAM_text_position = 7;
    RAM_state_position = 8;

    # ---- Sensors ----
    Sensors_widget = "sensors";
    Sensors_fanControl = true;
    Sensors_stack_position = 0;
    Sensors_label_position = 1;
    Sensors_mini_position = 2;
    Sensors_barChart_position = 3;
    # The sensor keys below are model-specific (TW0P and friends may not exist
    # on another Mac; in that case Stats ignores these keys harmlessly)
    Sensors_sensor = "TW0P";
    sensor_TW0P = true;
    sensor_PDTR = true;
    sensor_PPBR = false;

    # ---- Network ----
    Network_ICMPHost = "1.1.1.1";
    Network_interfaceDetails = true;
    Network_processes = 10;
    Network_publicIPRefreshInterval = "hour";
    Network_speed_mode = "twoRows";
    Network_usageReset = "Once per month";
    Network_widgetActivationThresholdState = false;
  };
}
