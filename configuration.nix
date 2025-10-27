# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # IMPORTS
  # ============================================================================

  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # ============================================================================
  # NETWORKING
  # ============================================================================

  networking = {
    hostName = "ap-tokyo-desktop";
    networkmanager.enable = true;

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # Firewall configuration
    # firewall.allowedTCPPorts = [ ... ];
    # firewall.allowedUDPPorts = [ ... ];
    # firewall.enable = false;
  };

  # ============================================================================
  # LOCALIZATION & INTERNATIONALIZATION
  # ============================================================================

  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };

    # Chinese and Japanese input method support
    inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-chinese-addons
        fcitx5-rime
        fcitx5-gtk
      ];
    };
  };

  # ============================================================================
  # DESKTOP ENVIRONMENT
  # ============================================================================

  services.xserver = {
    enable = true;

    # Keyboard layout
    xkb = {
      layout = "us";
      variant = "";
    };

    # Touchpad support (enabled by default in most desktop managers)
    # libinput.enable = true;
  };

  # Display Manager and Desktop Environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ============================================================================
  # HARDWARE CONFIGURATION
  # ============================================================================

  # Printing
  services.printing.enable = true;

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Audio - PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Uncomment to enable JACK support
    # jack.enable = true;
  };

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================

  users.users.jhl = {
    isNormalUser = true;
    description = "Jianyue Hugo Liang";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
      # thunderbird
    ];
  };

  # ============================================================================
  # SYSTEM PACKAGES & PROGRAMS
  # ============================================================================

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "corefonts" ];
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    git
  ];

  # Programs
  programs = {
    firefox.enable = true;

    bash.shellInit = ''
      if [ -z "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
      fi
    '';

    ssh.startAgent = true;

    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    # SUID wrappers configuration
    # mtr.enable = true;
    # gnupg.agent = {
    #   enable = true;
    #   enableSSHSupport = true;
    # };
  };

  # Home Manager
  home-manager.backupFileExtension = "backup";

  # ============================================================================
  # FONTS CONFIGURATION
  # ============================================================================

  fonts.packages = with pkgs; [
    # Base fonts
    noto-fonts
    liberation_ttf
    dejavu_fonts
    corefonts
    source-code-pro

    # CJK fonts
    wqy_zenhei
    wqy_microhei
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif

    # Source Han fonts
    source-han-sans
    source-han-serif
    source-han-mono

    # OSFCC recommended open source CJK fonts
    sarasa-gothic    # 更纱黑体
    hanazono         # 花园明朝体
    ipafont          # IPA 字体
    ipaexfont        # IPA Ex 字体
    migu             # Migu 字体 (基于 M+ 和 IPA)
    migmix           # MigMix 字体
    lxgw-neoxihei    # 霞鹜新晰黑 (基于 IPAex Gothic)
  ];

  # ============================================================================
  # SYSTEM SERVICES & POWER MANAGEMENT
  # ============================================================================

  # Disable sleep and hibernation
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # OpenSSH daemon
  # services.openssh.enable = true;

  # ============================================================================
  # CUSTOM SCRIPTS & ACTIVATION
  # ============================================================================

  # OnlyOffice font fix - copy fonts to local directory
  system.userActivationScripts.copy-fonts-local-share = {
    text = ''
      rm -rf ~/.local/share/fonts
      mkdir -p ~/.local/share/fonts

      # Copy core fonts
      cp ${pkgs.corefonts}/share/fonts/truetype/* ~/.local/share/fonts/ 2>/dev/null || true

      # Copy Chinese fonts
      find ${pkgs.wqy_zenhei}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.wqy_microhei}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true

      # Copy Source Han fonts
      find ${pkgs.source-han-sans}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.source-han-serif}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.source-han-mono}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true

      # Copy Noto fonts
      find ${pkgs.noto-fonts-cjk-sans}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.noto-fonts-cjk-serif}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true

      # Copy OSFCC recommended fonts
      find ${pkgs.sarasa-gothic}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.hanazono}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.ipafont}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.ipaexfont}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.migu}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.migmix}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
      find ${pkgs.lxgw-neoxihei}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true

      chmod 755 ~/.local/share/fonts
      chmod 644 ~/.local/share/fonts/* 2>/dev/null || true
      fc-cache -fv ~/.local/share/fonts/
    '';
  };

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================

  # This value determines the NixOS release from which the default settings
  # for stateful data were taken. Don't change this after initial install.
  # Read the documentation before changing: man configuration.nix
  system.stateVersion = "25.05"; # Did you read the comment?
}
