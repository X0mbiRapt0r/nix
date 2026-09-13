{ pkgs, ... }:

let
  # Work machines keep the same private file relative to their platform's Nix
  # checkout. The path is a runtime string; Nix never reads or stores its contents.
  workIdentityPath =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "~/Library/Mobile Documents/com~apple~CloudDocs/Documents/Code/nix/.private/git/work.inc"
    else
      "~/Documents/Code/nix/.private/git/work.inc";
in
{
  programs.git.includes = [ { path = workIdentityPath; } ];
}
