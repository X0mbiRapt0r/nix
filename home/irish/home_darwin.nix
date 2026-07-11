{ ... }:

{
  home.homeDirectory = "/Users/irish"; # macOS home directory.

  targets.darwin.defaults.NSGlobalDomain = {
    AppleLanguages = [ "en-GB" ]; # Preferred UI language list.
    AppleLocale = "en_ZA"; # Region/locale for dates, numbers, and currency.
  };
}
