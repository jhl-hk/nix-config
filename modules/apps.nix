# Documents
# https://daiderd.com/nix-darwin/manual/index.html

{pkgs, ...}: {
  # Nix Official Packages
  # https://discourse.nixos.org/t/darwin-again/29331
  environment.systemPackages = with pkgs; [
    starship  # Modern shell prompt
  ];

  # Homebrew Packages
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
    };

    taps = [
      "tw93/tap"
    ];

    # Packages - brew install
    brews = [
      "tw93/tap/mole" # Disk Cleaner
      "neofetch" # System Info
      "openssh"
    ];

    # GUI Apps - brew install --cask
    casks = [
      "stats" # System Status Monitor
    ];
  };
}
