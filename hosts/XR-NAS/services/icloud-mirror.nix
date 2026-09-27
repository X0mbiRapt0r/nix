{ lib, pkgs, ... }:

let
  settings = {
    configPasswordFile = "/etc/xombiraptor/icloud-rclone-password";
    destination = "/srv/data/icloud";
    maxDeletes = 1000;
    ntfyAuthorizationFile = "/etc/xombiraptor/icloud-ntfy-authorization";
    ntfyBaseUrl = "http://127.0.0.1:2586";
    ntfyTopic = "backups";
    snapshotDirectory = "/srv/data/snapshots/icloud";
    snapshotRetention = 90;
    source = "icloud:";
  };

  authenticate = pkgs.writeShellApplication {
    name = "icloud-authenticate";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.rclone
      pkgs.systemd
    ];
    text = ''
      if [[ -z "''${CREDENTIALS_DIRECTORY:-}" ]]; then
        exec /run/wrappers/bin/sudo systemd-run \
          --collect \
          --property=Environment=HOME=/var/lib/icloud \
          --property=Group=icloud \
          --property=LoadCredential=rclone-config-password:${lib.escapeShellArg settings.configPasswordFile} \
          --property=StateDirectory=icloud \
          --property=User=icloud \
          --property=WorkingDirectory=/var/lib/icloud \
          --pty \
          --unit=icloud-authenticate \
          --wait \
          "$0" "$@"
      fi

      config=/var/lib/icloud/rclone.conf
      password_command="cat $CREDENTIALS_DIRECTORY/rclone-config-password"

      if [[ "''${1:-}" == "initialize" ]]; then
        shift
        if [[ -e "$config" ]]; then
          echo "$config already exists; refusing to replace the configured remote." >&2
          exit 1
        fi

        rclone \
          --config "$config" \
          --password-command "$password_command" \
          config encryption set

        exec rclone \
          --config "$config" \
          --password-command "$password_command" \
          config "$@"
      fi

      exec rclone \
        --config "$config" \
        --password-command "$password_command" \
        "$@"
    '';
  };

  notifyFailure = pkgs.writeShellApplication {
    name = "notify-icloud-mirror-failure";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      curl \
        --data-binary "The daily iCloud Drive mirror failed after retries. Inspect: journalctl -u icloud-mirror.service" \
        --fail-with-body \
        --header @"$CREDENTIALS_DIRECTORY/ntfy-authorization" \
        --header "Priority: high" \
        --header "Tags: warning,cloud" \
        --header "Title: XR-NAS iCloud mirror failed" \
        --show-error \
        --silent \
        ${lib.escapeShellArg "${settings.ntfyBaseUrl}/${settings.ntfyTopic}"}
    '';
  };

  snapshotMirror = pkgs.writeShellApplication {
    name = "snapshot-icloud-mirror";
    runtimeInputs = [
      pkgs.btrfs-progs
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      snapshot_name="before-$(date --utc +%Y%m%dT%H%M%SZ)"

      btrfs subvolume show ${lib.escapeShellArg settings.destination} >/dev/null
      btrfs subvolume snapshot \
        -r \
        ${lib.escapeShellArg settings.destination} \
        ${lib.escapeShellArg settings.snapshotDirectory}/"$snapshot_name"

      mapfile -t snapshots < <(
        find ${lib.escapeShellArg settings.snapshotDirectory} \
          -mindepth 1 \
          -maxdepth 1 \
          -type d \
          -name 'before-*' \
          -printf '%f\n' \
          | sort
      )

      excess=$((''${#snapshots[@]} - ${toString settings.snapshotRetention}))
      for ((index = 0; index < excess; index++)); do
        btrfs subvolume delete \
          ${lib.escapeShellArg settings.snapshotDirectory}/"''${snapshots[$index]}"
      done
    '';
  };

  syncMirror = pkgs.writeShellApplication {
    name = "sync-icloud-mirror";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.rclone
    ];
    text = ''
      exec rclone sync \
        ${lib.escapeShellArg settings.source} \
        ${lib.escapeShellArg settings.destination} \
        --ask-password=false \
        --config /var/lib/icloud/rclone.conf \
        --create-empty-src-dirs \
        --log-level INFO \
        --max-delete ${toString settings.maxDeletes} \
        --password-command "cat $CREDENTIALS_DIRECTORY/rclone-config-password" \
        --retries 3 \
        --retries-sleep 1m \
        --stats 1m \
        --stats-one-line
    '';
  };
in
{
  environment.systemPackages = [ authenticate ];

  systemd = {
    services = {
      icloud-mirror = {
        after = [ "network-online.target" ];
        description = "Mirror iCloud Drive to local Btrfs storage";
        serviceConfig = {
          CapabilityBoundingSet = "";
          ExecStart = lib.getExe syncMirror;
          ExecStartPost = "${lib.getExe' pkgs.coreutils "touch"} /var/lib/icloud/last-mirror-success";
          ExecStartPre = "+${lib.getExe snapshotMirror}";
          Group = "icloud";
          LoadCredential = "rclone-config-password:${settings.configPasswordFile}";
          LockPersonality = true;
          NoNewPrivileges = true;
          PrivateDevices = true;
          PrivateTmp = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHome = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectSystem = "strict";
          ReadWritePaths = [
            settings.destination
            settings.snapshotDirectory
          ];
          StateDirectory = "icloud";
          StateDirectoryMode = "0750";
          TimeoutStartSec = "infinity";
          Type = "oneshot";
          UMask = "0027";
          User = "icloud";
        };
        unitConfig = {
          OnFailure = [ "icloud-mirror-notify.service" ];
          RequiresMountsFor = [
            settings.destination
            settings.snapshotDirectory
          ];
        };
        wants = [ "network-online.target" ];
      };

      icloud-mirror-notify = {
        after = [ "ntfy-sh.service" ];
        description = "Report an iCloud mirror failure through ntfy";
        serviceConfig = {
          DynamicUser = true;
          ExecStart = lib.getExe notifyFailure;
          LoadCredential = "ntfy-authorization:${settings.ntfyAuthorizationFile}";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectHome = true;
          ProtectSystem = "strict";
          Type = "oneshot";
        };
        wants = [ "ntfy-sh.service" ];
      };
    };

    timers.icloud-mirror = {
      description = "Mirror iCloud Drive daily";
      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
        Persistent = true;
        RandomizedDelaySec = "1h";
        Unit = "icloud-mirror.service";
      };
      wantedBy = [ "timers.target" ];
    };

    tmpfiles.rules = [
      "v ${settings.destination} 0750 icloud icloud -" # A subvolume keeps snapshots explicit and cheap.
      "d /srv/data/snapshots 0750 root icloud -" # Keep all service snapshots outside user-facing storage.
      "d ${settings.snapshotDirectory} 0750 root icloud -" # Allow iCloud-group members to read retained history.
    ];
  };

  users = {
    groups.icloud = { };
    users.icloud = {
      description = "iCloud integration service";
      group = "icloud";
      home = "/var/lib/icloud";
      isSystemUser = true;
    };
  };
}
