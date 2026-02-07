{ ... }:

{
  homebrew = {
    casks = [
      "powershell"
      "windows-app"
    ];
    # Mac App Store apps via `mas`
    # NOTE: keys = human-readable app name
    #       values = numeric App Store ID (from `mas list` / `mas search`)
    # masApps = {
      # "Numbers"            = 409203825;
      # "Pages"              = 409201541;
    #};
  };

  networking.hostName = "QTM-Irish-MBA";
}
