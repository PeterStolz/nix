{ pkgs, ... }:

{
  enable = true;
  enableUpdateCheck = false;
  enableExtensionUpdateCheck = false;
  extensions = with pkgs.vscode-extensions; [
    dbaeumer.vscode-eslint
    file-icons.file-icons
    github.vscode-github-actions
    hashicorp.terraform
    jdinhlife.gruvbox
    jnoortheen.nix-ide
    ms-azuretools.vscode-docker
    ms-kubernetes-tools.vscode-kubernetes-tools
    ms-python.black-formatter
    ms-python.debugpy
    ms-python.isort
    ms-python.python
    ms-python.vscode-pylance
    oderwat.indent-rainbow
    redhat.ansible
    redhat.vscode-yaml
    tamasfe.even-better-toml
    tim-koehler.helm-intellisense
    vscodevim.vim

  ];
  userSettings = {
    "editor.wrappingColumn" = 0;
    "explorer.confirmDelete" = false;
    "javascript.updateImportsOnFileMove.enabled" = "always";
    "[python]" = {
      "editor.defaultFormatter" = "ms-python.black-formatter";
    };
    "[yaml]" = {
      "editor.formatOnSave" = false;
    };
    "black-formatter.args" = [
      "--config"
      "\${workspaceFolder}/pyproject.toml"
    ];
    "isort.args" = [
      "--profile"
      "black"
    ];
    "pylint.args" = [ "--disable=C0116,C0114,C0301" ];
    "flake8.args" = [ "--ignore=E501,E203" ];
    "explorer.confirmDragAndDrop" = false;
    "redhat.telemetry.enabled" = false;
    "telemetry.telemetryLevel" = "off";
    "settingsSync.keybindingsPerPlatform" = false;
    "yaml.schemas" = {
      "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.22.4-standalone-strict/all.json" =
        [
          "**/templates/*.yaml"
          "**/templates/*.yml"
        ];
    };
    "editor.lineNumbers" = "relative";
    "workbench.iconTheme" = "file-icons";
    "workbench.colorTheme" = "Gruvbox Dark Medium";
    "editor.formatOnSave" = true;
    "editor.codeActionsOnSave" = {
      "source.fixAll.eslint" = "explicit";
      "source.organizeImports" = "explicit";
    };
    "eslint.validate" = [ "javascript" ];
  };
  # sadly not all vscode-extensions work with vscodium
  #package = pkgs.vscodium;
}
