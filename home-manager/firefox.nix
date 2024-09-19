{
  pkgs,
  ...
}:
let
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
in
{
  package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
    extraPolicies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";

      # ---- EXTENSIONS ----
      ExtensionSettings = {
        "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
        # uBlock Origin:
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        # Privacy Badger:
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          installation_mode = "force_installed";
        };
        # 1Password:
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };
      };

      # ---- PREFERENCES ----
      # Set preferences shared by all profiles.
      Preferences = {
        "browser.contentblocking.category" = {
          Value = "strict";
          Status = "locked";
        };
        "extensions.pocket.enabled" = lock-false;
        "extensions.screenshots.disabled" = lock-true;
        "browser.topsites.contile.enabled" = lock-false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
      };
    };
  };

  # ---- PROFILES ----
  # Switch profiles via about:profiles page.
  # For options that are available in Home-Manager see
  # https://nix-community.github.io/home-manager/options.html#opt-programs.firefox.profiles
  profiles = {
    profile_0 = {
      # choose a profile name; directory is /home/<user>/.mozilla/firefox/profile_0
      id = 0; # 0 is the default profile; see also option "isDefault"
      name = "profile_0"; # name as listed in about:profiles
      isDefault = true; # can be omitted; true if profile ID is 0
      settings = {
        # specify profile-specific preferences here; check about:config for options
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.startup.homepage" = "https://nixos.org";
        "browser.newtabpage.pinned" = [
          {
            title = "NixOS";
            url = "https://nixos.org";
          }
        ];
        # add preferences for profile_0 here...
      };
    };
    profile_1 = {
      id = 1;
      name = "profile_1";
      isDefault = false;
      settings = {
        "browser.newtabpage.activity-stream.feeds.section.highlights" = true;
        "browser.startup.homepage" = "https://ecosia.org";
        # add preferences for profile_1 here...
      };
    };
    # add profiles here...
  };
}
