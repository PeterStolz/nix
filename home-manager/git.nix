{ config, lib, ... }:

let
  # builtins.getEnv returns "" for an unset variable, so an unset override
  # falls back rather than blanking the setting.
  envOr =
    var: fallback:
    let
      v = builtins.getEnv var;
    in
    if v == "" then fallback else v;
in
{
  options.local.git = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = envOr "HM_GIT_NAME" "Peter Stolz";
      description = ''
        Commit author name. Override with HM_GIT_NAME on machines used by someone
        else, so their checkout does not have to be edited — see local.headless
        for why that matters.
      '';
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      default = envOr "HM_GIT_EMAIL" "50801264+PeterStolz@users.noreply.github.com";
      description = "Commit author email. Override with HM_GIT_EMAIL.";
    };

    signingKey = lib.mkOption {
      type = lib.types.str;
      default = envOr "HM_GIT_SIGNINGKEY" "1D68343249781AD9";
      description = ''
        GPG key id for signed commits. Override with HM_GIT_SIGNINGKEY. Only
        consulted when local.signCommits is on, so boxes with no key can leave it
        alone and set HM_NO_SIGN=1 instead.
      '';
    };
  };

  options.local.signCommits = lib.mkOption {
    type = lib.types.bool;
    default = builtins.getEnv "HM_NO_SIGN" != "1";
    description = ''
      Set HM_NO_SIGN=1 on boxes that have no secret GPG key (agent VMs, throwaway
      servers) to stop git from signing. With signing on and no key, every commit
      fails outright, so this has to be off there rather than merely best-effort.

      Read with builtins.getEnv, so — like HM_HEADLESS — it must be in the
      environment of *every* `home-manager switch`, not just the first. Put it in
      /etc/environment; home-manager owns ~/.bashrc.
    '';
  };

  config.programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = config.local.git.userName;
      user.email = config.local.git.userEmail;
      user.signingkey = config.local.git.signingKey;
      gpg.program = "gpg";
      push.autoSetupRemote = true;
      commit.gpgsign = config.local.signCommits;
      core.editor = "nvim";
      core.autocrlf = "input";
      init.defaultBranch = "main";
      # Paths that do not exist on a given machine are inert, so the union of
      # every machine's mount points can live here. The truenas entries are the
      # same NFS share (general/misc) under its darwin and linux mount points.
      safe.directory = [
        "/etc/nixos"
        "/Volumes/truenas-big/phuc/detesia"
        "/truenas-big/misc/phuc/detesia"
      ];
      stash.showPatch = true;
      pull.rebase = true;
      alias = {
        graph = "log --all --decorate --oneline --graph";
      };
    };
    ignores = [
      "__pycache__"
      ".pytest_cache"
      ".DS_Store"
      ".vscode"
      ".idea"
      ".ipynb_checkpoints/"
      ".coverage"
      "*.ckpt"
      "charts"
      "mlruns"
      "*.retry"
      ".terraform/"
      "*.tfstate"
      "*.tfstate.*"
      "*.parquet"
      "node_modules"
    ];
  };
}
