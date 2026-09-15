{ config, lib, ... }:

let
  cfg = config.xombiraptor.services.ntfy;
in
{
  options.xombiraptor.services.ntfy = {
    baseUrl = lib.mkOption {
      type = lib.types.str;
      description = ''
        Public ntfy URL stored in the generated configuration. A host-local
        NTFY_BASE_URL in environmentFile may override it for private domains.
      '';
    };

    enable = lib.mkEnableOption "the private ntfy notification server";

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = ''
        Root-readable systemd environment file for the stable Web Push keys,
        administrator email address, and any private runtime overrides.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.ntfy-sh = {
      enable = true;
      environmentFile = cfg.environmentFile;
      settings = {
        auth-default-access = "deny-all"; # Internet-facing topics require an authenticated user or token.
        base-url = cfg.baseUrl;
        behind-proxy = true; # Trust Cloudflare's forwarded client address for per-visitor rate limits.
        enable-login = true; # Allow authenticated use of the browser client.
        listen-http = "127.0.0.1:2586"; # Only the co-located Cloudflare connector may reach ntfy directly.
        upstream-base-url = "https://ntfy.sh"; # Relay content-free poll requests for timely native iOS delivery.
        web-push-file = "/var/lib/ntfy-sh/webpush.db"; # Preserve desktop browser subscriptions across restarts.
      };
    };
  };
}
