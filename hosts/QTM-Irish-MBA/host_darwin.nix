{ ... }:

{
  homebrew = {
    brews = [
      "powershell" # Cross-platform shell and scripting runtime.
    ];
    casks = [
      "docker-desktop" # Docker Desktop for Mac.
      "stillcolor"
      "windows-app" # Microsoft Windows App for remote desktops/cloud PCs.
      "wireshark-app" # Network protocol analyser.
    ];
  };

  networking = {
    computerName = "QTM-Irish-MBA"; # User-visible macOS computer name.
    hostName = "QTM-Irish-MBA"; # Local network hostname for this Mac.
    localHostName = "QTM-Irish-MBA"; # Bonjour/local hostname used by macOS sharing services.
  };
}
