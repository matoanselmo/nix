# Public Cloudflare tunnel for StudyQuest: studyquest.scarlettkhun.dev ->
# localhost:8081. The connection is outbound only, so no firewall ports. The
# tunnel and its DNS record were made with `cloudflared tunnel create` and
# `cloudflared tunnel route dns`.
#
# Secret: /etc/nixos/secrets/cloudflared-studyquest.json (root:root, 0400),
# the tunnel's credentials JSON. The service reads it through LoadCredential,
# so it can stay root-only. Keep credentialsFile a string, not a path literal,
# or the secret gets copied into the world-readable Nix store.
{
  services.cloudflared = {
    enable = true;
    tunnels."bbcdfb88-5061-4ef0-916b-1d84f613f58a" = {
      credentialsFile = "/etc/nixos/secrets/cloudflared-studyquest.json";
      ingress."studyquest.scarlettkhun.dev" = "http://localhost:8081";
      default = "http_status:404";
    };
  };
}
