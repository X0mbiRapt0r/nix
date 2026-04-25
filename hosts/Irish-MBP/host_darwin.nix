{ ... }:

{
  homebrew = {
    casks = [
      "audacity" # Audio editor.
      "calibre" # Ebook manager.
      "codex-app" # Codex desktop app.
      "discord" # Chat/voice app.
      "godot" # Game engine.
      "porting-kit" # Windows game/app wrapper for macOS.
      "steam" # Steam client.
      "stremio" # Media streaming app.
      "transmission" # BitTorrent client.
    ];
  };

  networking.hostName = "Irish-MBP"; # Local network hostname for this Mac.
}
