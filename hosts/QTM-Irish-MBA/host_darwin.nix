{ pkgs, ... }:

{
  home-manager.users.irish = {
    home = {
      file."Library/Application Support/ntfy/client.yml".text = ''
        default-host: http://qtm-irish-nuc.local:2586
      '';
      packages = [ pkgs.ntfy-sh ]; # Install the ntfy publish/subscribe CLI for the work server.
    };

    # Apply the private, iCloud-synced identity only to work repositories.
    programs.git.includes = [
      {
        condition = "gitdir/i:~/Library/CloudStorage/OneDrive-*/Documents/github.com/**";
        path = "~/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/X0mbiRapt0r/nix/hosts/QTM-Irish-MBA/.gitconfig-qtm.inc";
      }
    ];
  };

  homebrew = {
    brews = [
      "powershell" # Cross-platform shell and scripting runtime.
    ];
    casks = [
      "claude"
      "docker-desktop" # Docker Desktop for Mac.
      "stillcolor" # Disable temporal dithering on supported Apple Silicon displays.
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
