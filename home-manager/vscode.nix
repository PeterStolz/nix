{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  home-manager.users.${username} = {
    programs.vscode = {
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        ms-azuretools.vscode-docker
        hashicorp.terraform
        vscodevim.vim
        ms-python.python
        ms-python.debugpy
        ms-python.vscode-pylance
      ];
      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "settingsSync.keybindingsPerPlatform" = false;
        "editor.lineNumbers" = "relative";
        workbench = {
          "iconTheme" = "vscode-icons";
          "colorTheme" = "Default Dark Modern";
        };
      };
      package = pkgs.vscodium;
    };
  };
}
