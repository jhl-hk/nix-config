{...}:
#############################################################
#
#  OpenUsage (robinebers/openusage) Configuration
#
#  OpenUsage itself is installed by a Homebrew cask (see
#  hosts/common/optional/darwin/desktop.nix). Its settings live in the
#  `com.robinebers.openusage` user defaults domain, written here through
#  targets.darwin.defaults (`defaults import`, merge semantics).
#
#  Deliberately not synced (runtime state, not preferences):
#    PHG*, SU*                                  - PostHog / Sparkle state
#    openusage.icloudSync.deviceID.v1           - per-machine identity
#    openusage.knownProviders.v1                - app-maintained catalog
#    openusage.layout.v1, *.metricOrderByProvider,
#    *.seededDefaults, *.expandedMetrics,
#    *.expandedProviders, *.expandOnEnable      - layout blobs / UI state
#    openusage.providerAccounts.v1              - account bindings
#    openusage.providerSnapshots.v9             - usage cache
#    openusage.shellEnvSnapshot.v2              - captured shell env
#    openusage.panel.height.*                   - panel geometry
#    openusage.onboarding.*                     - first-run markers
#
#############################################################
{
  targets.darwin.defaults."com.robinebers.openusage" = {
    # ---- Providers ----
    "openusage.enabledProviders.v1" = ["grok" "claude" "codex"];
    "openusage.icloudSync.enabled.v1" = true;

    # ---- Menu bar ----
    "openusage.layout.v1.menuBarStyle" = "text";
    "openusage.layout.v1.menuBarPins" = [
      "grok.weekly"
      "claude.weekly"
      "zai.session"
      "copilot.premium"
      "openrouter.credits"
      "cursor.usage"
      "ollama.monthly"
      "codex.weekly"
      "zai.weekly"
      "antigravity.geminiPro"
      "antigravity.geminiWeekly"
      "claude.session"
    ];

    # ---- Display ----
    meterStyle = "used";
    resetDisplayMode = "absolute";
    alwaysShowPacing = true;
    hideUsageWhileScreenSharing = true;
    increaseTransparency = true;
    reduceAnimations = false;
    "openusage.totalSpend.metric" = "tokens";
    "openusage.totalSpend.period" = "Today";

    # ---- Notifications ----
    "openusage.notifications.closeToRunningOut" = true;
    "openusage.notifications.healthyToClose" = true;
    "openusage.notifications.underTenPercent" = true;
  };
}
