{ ... }:

{
  homebrew = {
    casks = [
      "calibre" # Ebook manager.
      "discord" # Chat/voice app.
      "godot" # Game engine.
      "steam" # Steam client.
      "stremio" # Media streaming app.
      "transmission" # BitTorrent client.
    ];
  };

  networking = {
    computerName = "Irish-MBP"; # User-visible macOS computer name.
    hostName = "Irish-MBP"; # Local network hostname for this Mac.
    localHostName = "Irish-MBP"; # Bonjour/local hostname used by macOS sharing services.
  };
}
