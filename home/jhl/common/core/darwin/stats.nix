{...}:
#############################################################
#
#  Stats (exelban/stats) Configuration
#
#  Stats 本体由 Homebrew cask 安装（见 hosts/common/darwin/apps.nix）。
#  它没有配置文件，所有设置都在 `eu.exelban.Stats` 这个 user defaults
#  域里，所以用 home-manager 的 targets.darwin.defaults 写。
#  底层是 `defaults import`，是合并语义（实测过：import 之前就有的键
#  不会被冲掉），所以下面「有意不同步」的运行时状态会原样保留。
#
#  注意：Stats 在退出时会把内存里的设置整个写回。switch 之前先退出
#  Stats，否则新写进去的值会被运行中的进程覆盖掉。
#
#  有意不同步的键（机器状态 / 硬件相关，不是偏好设置）：
#    remote_id, remote_tokens_migrated_to_keychain  — 每台机器的身份
#    runAtLoginInitialized, setupProcess            — 首次运行标记
#    support_*, updater_*, version                  — 运行时时间戳
#    NSWindow Frame / NSToolbar Configuration       — 窗口几何，跟分辨率走
#    NSStatusItem Preferred Position *              — 菜单栏像素位置
#    Network_usageReset_next                        — 会自动往后滚的时间戳
#    fan_0_*, fan_1_*                               — 风扇状态，Air 上根本没有
#
#############################################################
{
  targets.darwin.defaults."eu.exelban.Stats" = {
    # ---- 应用级 ----
    LaunchAtLoginNext = true;
    telemetry = false;
    "update-interval" = "Silent";

    # ---- 模块开关 ----
    CPU_state = false;
    GPU_state = false;
    Disk_state = false;
    Battery_state = false;
    RAM_state = true;
    Sensors_state = true;
    # Network 在本机没有显式的 state 键（即用的是默认值 = 开），
    # 这里写死，免得换台机器时依赖 Stats 的默认值
    Network_state = true;

    # ---- RAM ----
    RAM_widget = "pie_chart";
    RAM_pie_chart_label = false;
    RAM_pie_chart_monochrome = false;
    # 设置界面里各 widget 的排序
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
    # 下面的传感器 key 是按机型走的（TW0P 等在别的 Mac 上可能不存在，
    # 那种情况下这些键会被 Stats 忽略，不会出问题）
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
