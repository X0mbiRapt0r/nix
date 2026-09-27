{
  # Keep private work identity outside the repository on every platform. The
  # runtime string is expanded by Git; Nix never reads or stores its contents.
  programs.git.includes = [ { path = "~/.config/git/work.inc"; } ];
}
