{ ... }:

{
  home = {
    file = {
      ".local/bin/ngc".source = ../../scripts/gc; # Expose Nix garbage collection as `ngc`.
      ".local/bin/nfu".source = ../../scripts/flake-update; # Expose flake updates as `nfu`.
      ".local/bin/nix-switch".source = ../../scripts/switch; # Expose system switching as `nix-switch`.
    };
    sessionPath = [
      "$HOME/.local/bin" # Prefer personal helper commands over language-specific binaries.
      "$HOME/go/bin"
    ];
    username = "irish";
  };

  programs = {
    git = {
      # On Darwin, packaged Git already enables `credential.helper = osxkeychain` at system scope;
      # keep it out of Home Manager because credential helpers are additive.
      enable = true; # Generate $XDG_CONFIG_HOME/git/config.
      ignores = [
        # Keep OS-generated noise global; project and tool artefacts belong in each repo.

        # Linux desktop and filesystem metadata.
        ".directory"
        ".fuse_hidden*"
        ".nfs*"
        ".Trash-*"

        # macOS desktop and filesystem metadata.
        "._*"
        ".AppleDouble"
        ".DS_Store"
        ".localized"
        ".LSOverride"
        ".Spotlight-V100"
        ".Trashes"
        "__MACOSX/"

        # Windows desktop and filesystem metadata.
        "$RECYCLE.BIN/"
        "[Dd]esktop.ini"
        "ehthumbs.db"
        "ehthumbs_vista.db"
        "Thumbs.db"
        "Thumbs.db:encryptable"
      ];
      settings = {
        init.defaultBranch = "main"; # New repos start on main.
        pull.rebase = true; # Rebase local commits when pulling.
        user = {
          email = "11319449+X0mbiRapt0r@users.noreply.github.com";
          name = "X0mbiRapt0r";
        };
      };
    };

    zsh = {
      autosuggestion.enable = true;
      enable = true;
      enableCompletion = true;

      initContent = ''
        PROMPT='%n@%m:%1~ > '
      '';

      shellAliases = {
        # Deliberate one-step publishing helper for this personal repo.
        gacp = "git add . && git commit -m 'quick update' && git push origin main";
        gs = "git status";
        ll = "lsd -lah";
        ls = "lsd";
        lt = "lsd --tree";
        nrs = "command nix-switch"; # Build and activate this host's flake configuration.
      };

      syntaxHighlighting.enable = true;
    };
  };
}
