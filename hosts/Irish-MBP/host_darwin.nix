{ ... }:

{
  homebrew = {
    casks = [
      "audacity" # Audio editor.
      "calibre" # Ebook manager.
      "discord" # Chat/voice app.
      "godot" # Game engine.
      "steam" # Steam client.
      "stremio" # Media streaming app.
      "transmission" # BitTorrent client.
    ];
  };

  networking.hostName = "Irish-MBP"; # Local network hostname for this Mac.
  networking.computerName = "Irish-MBP";
  networking.localHostName = "Irish-MBP";
}
