{ pkgs, ... }:

{
  settings = {
    user.name = "Peter Stolz";
    user.email = "50801264+PeterStolz@users.noreply.github.com";
    user.signingkey = "1D68343249781AD9";
    gpg.program = "gpg";
    push.autoSetupRemote = true;
    commit.gpgsign = true;
    core.editor = "nvim";
    core.autocrlf = "input";
    init.defaultBranch = "main";
    safe.directory = "/etc/nixos";
    stash.showPatch = true;
    pull.rebase = true;
    alias = {
      graph = "log --all --decorate --oneline --graph";
    };
  };
  enable = true;
  lfs.enable = true;
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
}
