# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ap-tokyo-desktop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jhl = {
    isNormalUser = true;
    description = "Jianyue Hugo Liang";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "corefonts" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nix.settings.experimental-features = ["nix-command" "flakes"];
  environment.systemPackages = with pkgs; [
    git
  ];

  # Fonts configuration
  fonts = {
    packages = with pkgs; [
      # 已有字体
      wqy_zenhei
      wqy_microhei
      source-han-sans
      source-han-serif
      source-han-mono
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts
      liberation_ttf
      dejavu_fonts
      corefonts
      source-code-pro
      
      # OSFCC 推荐的开源中文字体
      sarasa-gothic        # 更纱黑体
      hanazono            # 花园明朝体
      ipafont             # IPA 字体
      ipaexfont           # IPA Ex 字体
      migu                # Migu 字体 (基于 M+ 和 IPA)
      migmix              # MigMix 字体
      
      # 其他相关字体
      lxgw-neoxihei       # 霞鹜新晰黑 (基于 IPAex Gothic)
    ];
  };

  # Chinese and Japanese Keyboard support
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-chinese-addons
      fcitx5-rime
      fcitx5-gtk
    ];
  };

  programs.bash = {
    shellInit = ''
      if [ -z "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
      fi
    '';
  };

  programs.ssh.startAgent = true;

  # Home Manager
  home-manager.backupFileExtension = "backup";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # OnlyOffice font fix - copy fonts to local directory
  system.userActivationScripts = {
    copy-fonts-local-share = {
      text = ''
        rm -rf ~/.local/share/fonts
        mkdir -p ~/.local/share/fonts

        # 复制核心字体
        cp ${pkgs.corefonts}/share/fonts/truetype/* ~/.local/share/fonts/ 2>/dev/null || true

        # 复制中文字体
        find ${pkgs.wqy_zenhei}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
        find ${pkgs.wqy_microhei}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true

        # 复制思源字体
        find ${pkgs.source-han-sans}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
        find ${pkgs.source-han-serif}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
        find ${pkgs.source-han-mono}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true

        # 复制 Noto 字体
        find ${pkgs.noto-fonts-cjk-sans}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true
        find ${pkgs.noto-fonts-cjk-serif}/share/fonts -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp {} ~/.local/share/fonts/ \; 2>/dev/null || true

        # 复制 OSFCC 推荐的开源字体
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
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
