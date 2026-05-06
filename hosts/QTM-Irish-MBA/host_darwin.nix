{ ... }:

{
  homebrew = {
    casks = [
      "docker-desktop" # Docker Desktop for Mac.
      "powershell" # Microsoft PowerShell app/runtime.
      "windows-app" # Microsoft Windows App for remote desktops/cloud PCs.
    ];
  };

  networking.hostName = "QTM-Irish-MBA"; # Local network hostname for this Mac.
  networking.computerName = "QTM-Irish-MBA";
  networking.localHostName = "QTM-Irish-MBA";
}
