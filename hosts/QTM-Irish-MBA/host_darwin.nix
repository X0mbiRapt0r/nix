{ ... }:

{
  home-manager.users.irish = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false; # Keep OpenSSH defaults outside the work-host entry.
      package = null; # Use Apple's SSH client for native Keychain support.
      settings."qtm-nuc QTM-Irish-NUC qtm-irish-nuc.local" = {
        AddKeysToAgent = "yes";
        ForwardAgent = false; # Remote processes do not need access to the Mac's agent.
        HostName = "qtm-irish-nuc.local";
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/id_ed25519"; # Runtime path only; never import the private key into Nix.
        IgnoreUnknown = "UseKeychain"; # Also allow clients without Apple's Keychain extension.
        ServerAliveInterval = 60;
        UseKeychain = true;
        User = "irish";
      };
    };
  };

  homebrew.casks = [
    "claude"
    "docker-desktop" # Docker Desktop for Mac.
    "obsidian"
    "stillcolor" # Disable temporal dithering on supported Apple Silicon displays.
    "windows-app" # Microsoft Windows App for remote desktops/cloud PCs.
    "wireshark-app" # Network protocol analyser.
  ];

  networking = {
    computerName = "QTM-Irish-MBA"; # User-visible macOS computer name.
    hostName = "QTM-Irish-MBA"; # Local network hostname for this Mac.
    localHostName = "QTM-Irish-MBA"; # Bonjour/local hostname used by macOS sharing services.
  };
}
