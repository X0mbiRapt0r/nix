{ config, lib, ... }:

let
  qtmCloudDevPath = "${config.home.homeDirectory}/Library/Mobile Documents/com~apple~CloudDocs/Documents/github.com/QTM-Cloud-Dev";
in
{
  home = {
    activation.createQtmCloudDevDirectory =
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        run mkdir -p $VERBOSE_ARG ${lib.escapeShellArg qtmCloudDevPath}
      '';

    file."Library/CloudStorage/OneDrive-QuantusTechnologyManagement(Pty)Ltd/Documents/github.com/QTM-Cloud-Dev".source =
      config.lib.file.mkOutOfStoreSymlink qtmCloudDevPath; # Keep the checkout in iCloud while exposing it in OneDrive.
  };
}
