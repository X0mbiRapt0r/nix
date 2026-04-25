{ ... }:

{
  homebrew = {
    casks = [
      "powershell" # Microsoft PowerShell app/runtime.
      "windows-app" # Microsoft Windows App for remote desktops/cloud PCs.
    ];
  };

  networking.hostName = "QTM-Irish-MBA"; # Local network hostname for this Mac.
}
