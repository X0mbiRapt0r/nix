{
  lib,
  pkgs,
  sshPublicKeys,
  ...
}:

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

  # Linux has no native Keychain helper, so route GitHub authentication through
  # gh while the private include owns only the work commit identity.
  home-manager.users.irish.programs.git.settings.credential."https://github.com".helper = [
    ""
    "!gh auth git-credential"
  ];

  networking = {
    firewall.allowedTCPPorts = [ 2586 ]; # Expose ntfy only to networks that can already reach the NUC.
    hostName = "QTM-Irish-NUC"; # Local network hostname and flake host name.
  };

  nixpkgs.config.allowUnfreePredicate = package: lib.getName package == "claude-code";

  services = {
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

  users.users.irish = {
    linger = true; # Start user services at boot without an insecure console auto-login.
    openssh.authorizedKeys.keys = [
      sshPublicKeys.qtmIrishMba # QTM-Irish-MBA owns the private key; only its public half is deployed here.
    ];
  };
}
