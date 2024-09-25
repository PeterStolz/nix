{ pkgs, ... }:

{
  enable = true;
  enableUpdateCheck = false;
  enableExtensionUpdateCheck = false;
  extensions = with pkgs.vscode-extensions; [
    ms-azuretools.vscode-docker
    hashicorp.terraform
    vscodevim.vim
    jnoortheen.nix-ide
    ms-python.python
    ms-python.debugpy
    ms-python.vscode-pylance
  ];
  userSettings = {
    "explorer.confirmDragAndDrop"= false;
    "telemetry.telemetryLevel" = "off";
    "settingsSync.keybindingsPerPlatform" = false;
    "editor.lineNumbers" = "relative";
    workbench = {
      "iconTheme" = "vscode-icons";
      "colorTheme" = "Default Dark Modern";
    };
  };
  # sadly not all vscode-extensions work with vscodium
  #package = pkgs.vscodium;
}
