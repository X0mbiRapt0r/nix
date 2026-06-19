{ ... }:

{
  # home-manager.users.irish.imports = [
  #   ./home_darwin.nix # Host-specific user files and activation tasks.
  # ];

  homebrew = {
    brews = [
      "powershell" # Microsoft Azure CLI tool.
    ];
    casks = [
      "docker-desktop" # Docker Desktop for Mac.
      "windows-app" # Microsoft Windows App for remote desktops/cloud PCs.
      "wireshark-app"
    ];
  };

  networking = {
    computerName = "QTM-Irish-MBA"; # User-visible macOS computer name.
    hostName = "QTM-Irish-MBA"; # Local network hostname for this Mac.
    localHostName = "QTM-Irish-MBA"; # Bonjour/local hostname used by macOS sharing services.
  };
}
