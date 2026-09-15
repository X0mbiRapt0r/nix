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
    hostName = "QTM-Irish-NUC"; # Local network hostname and flake host name.
  };

  nixpkgs.config.allowUnfreePredicate = package: lib.getName package == "claude-code";

  xombiraptor.services = {
    cloudflareTunnel = {
      enable = true;
      tokenFile = "/home/irish/Documents/Code/nix/.private/services/QTM-Irish-NUC/cloudflared-token";
    };

    ntfy = {
      # The private environment file overrides this local fallback with NTFY_BASE_URL.
      baseUrl = "http://127.0.0.1:2586";
      enable = true;
      environmentFile = "/home/irish/Documents/Code/nix/.private/services/QTM-Irish-NUC/ntfy.env";
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
