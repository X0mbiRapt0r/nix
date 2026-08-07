{ ... }:

{
  homebrew = {
    casks = [
      "audacity"
      "calibre"
      "discord"
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
