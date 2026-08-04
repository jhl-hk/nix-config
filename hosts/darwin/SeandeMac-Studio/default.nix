{...}:
#############################################################
#
#  SeandeMac-Studio -- Mac Studio (Taizhou)
#
#############################################################
{
  hostSpec = {
    hostName = "SeandeMac-Studio";
    isMobile = false;
  };

  # macOS 27.0 (26A5388g)，在 27seed 目录里。
  # seed 版本上 mas 装不动，所以 masApps 会被整个跳过。
  # `just check-beta` 可以确认这台机器现在是哪种。
  darwinHomebrew.macosBeta = true;
}
