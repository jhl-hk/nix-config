{
  config,
  lib,
  ...
}:
#############################################################
#
#  Local DNS
#  dnsmasq on 127.0.0.1. Each key in `addresses` gets an
#  /etc/resolver/<domain> file, so only those names (and their
#  subdomains) go to dnsmasq; everything else uses networking.dns.
#
#  Mapping: hostSpec.networking.localDns in nix-secrets
#  (nix/network.nix).
#
#############################################################
let
  addresses = config.hostSpec.networking.localDns or {};
in {
  services.dnsmasq = lib.mkIf (addresses != {}) {
    enable = true;
    inherit addresses;
  };
}
