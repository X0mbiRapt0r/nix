{ ... }:

let
  mkSshHost = hostName: {
    AddKeysToAgent = "yes";
    ForwardAgent = false; # Remote processes do not need access to the Mac's agent.
    HostName = hostName;
    IdentitiesOnly = true;
    IdentityFile = "~/.ssh/id_ed25519"; # Runtime path only; never import the private key into Nix.
    IgnoreUnknown = "UseKeychain"; # Also allow clients without Apple's Keychain extension.
    ServerAliveInterval = 60;
    UseKeychain = true;
    User = "irish";
  };
in
{
  home-manager.users.irish.programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # Keep OpenSSH defaults outside the managed personal-host entries.
    package = null; # Use Apple's SSH client for native Keychain support.
    settings = {
      "irish-pc Irish-PC irish-pc.local" = mkSshHost "irish-pc.local";
      "mbp-2013 Irish-MBP-2013 irish-mbp-2013.local" = mkSshHost "irish-mbp-2013.local";
      "xr-nas XR-NAS xr-nas.local" = mkSshHost "xr-nas.local";
    };
  };

  homebrew = {
    casks = [
      "chatgpt"
      "audacity"
      "calibre"
      "discord"
      "freecad"
      "godot"
      "steam"
      "stremio"
      "transmission"
    ];
  };

  networking = {
    computerName = "Irish-MBP"; # User-visible macOS computer name.
    hostName = "Irish-MBP"; # Local network hostname for this Mac.
    localHostName = "Irish-MBP"; # Bonjour/local hostname used by macOS sharing services.
  };
}
