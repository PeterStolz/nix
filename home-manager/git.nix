{ config, lib, ... }:

{
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
      user.name = "Peter Stolz";
      user.email = "50801264+PeterStolz@users.noreply.github.com";
      user.signingkey = "1D68343249781AD9";
      gpg.program = "gpg";
      push.autoSetupRemote = true;
      commit.gpgsign = config.local.signCommits;
      core.editor = "nvim";
      core.autocrlf = "input";
      init.defaultBranch = "main";
      safe.directory = [
        "/etc/nixos"
        "/Volumes/truenas-big/phuc/detesia"
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
