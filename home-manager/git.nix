{ pkgs, ... }:

{
  enable = true;
  userName = "Peter Stolz";
  userEmail = "50801264+PeterStolz@users.noreply.github.com";
  lfs.enable = true;
  aliases = {
    graph = "log --all --decorate --oneline --graph";
  };
  extraConfig = {
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
  };
}
