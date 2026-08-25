{ lib, pkgs, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest; # Preserve the kernel choice made during installation.
    loader = {
      efi.canTouchEfiVariables = true; # Allow NixOS to update UEFI boot entries.
      systemd-boot.enable = true; # Use systemd-boot on the NUC's EFI system partition.
    };
  };

  environment.systemPackages = with pkgs; [
    claude-code # Anthropic's headless CLI coding agent.
  ];

  # Apply the private work identity only below the dedicated work-repository root.
  home-manager.users.irish.programs.git.includes = [
    {
      condition = "gitdir/i:~/Documents/github.com/RudolphIrish/**";
      path = "~/Documents/github.com/X0mbiRapt0r/nix/hosts/QTM-Irish-NUC/.gitconfig-qtm.inc";
    }
  ];

  networking = {
    firewall.allowedTCPPorts = [ 2586 ]; # Expose ntfy only to networks that can already reach the NUC.
    hostName = "QTM-Irish-NUC"; # Local network hostname and flake host name.
  };

  nixpkgs.config.allowUnfreePredicate = package: lib.getName package == "claude-code";

  services = {
    avahi = {
      enable = true; # Advertise the NUC as qtm-irish-nuc.local on the local network.
      publish = {
        addresses = true;
        enable = true;
      };
    };

    ntfy-sh = {
      enable = true;
      settings = {
        auth-default-access = "deny-all"; # Require an explicitly provisioned account for every topic.
        base-url = "http://qtm-irish-nuc.local:2586";
        listen-http = ":2586"; # Listen on the LAN; the firewall limits access to reachable networks.
        upstream-base-url = "https://ntfy.sh"; # Relay content-free poll requests for timely iOS delivery.
      };
    };
  };

  system.stateVersion = "26.05"; # Fresh-install compatibility baseline; do not bump casually.

  users.users.irish.linger = true; # Start user services at boot without an insecure console auto-login.
}
