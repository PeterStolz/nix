{ pkgs, ... }:

{
  enable = true;
  profiles.default = {
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
      ms-python.flake8
      matangover.mypy
      oderwat.indent-rainbow
      redhat.ansible
      redhat.vscode-yaml
      tamasfe.even-better-toml
      tim-koehler.helm-intellisense
      vscodevim.vim
      christian-kohler.path-intellisense
    ];
    userSettings = {
      ##################################
      ## Generic Editor Configuration ##
      ##################################
      "editor.wrappingColumn" = 0;
      "editor.lineNumbers" = "relative";
      "editor.formatOnSave" = true;
      "editor.codeActionsOnSave" = {
        "source.fixAll.eslint" = "explicit";
        "source.organizeImports" = "explicit";
      };
      "explorer.confirmDelete" = false;
      "explorer.confirmDragAndDrop" = false;
      "workbench.iconTheme" = "file-icons";
      "workbench.colorTheme" = "Gruvbox Dark Medium";
      "redhat.telemetry.enabled" = false;
      "telemetry.telemetryLevel" = "off";
      "settingsSync.keybindingsPerPlatform" = false;

      #######################################
      ## Terminal and File System Settings ##
      #######################################
      "terminal.integrated.defaultProfile.osx" = "fish";
      "search.ripgrep.maxThreads" = 1;

      # (Optional) File and directory exclusions — useful for remote setups
      # "files.exclude" = {
      #   "**/data/" = true;
      #   "**/dataset/" = true;
      # };
      # "files.watcherExclude" = {
      #   "**" = true;
      # };
      # "files.watcherInclude" = [
      #   "src/"
      #   "app/"
      #   "charts/"
      #   "scripts/"
      #   "tests/"
      #   "source/"
      # ];

      ####################
      ## Tooling Config ##
      ####################

      "git.openRepositoryInParentFolders" = "always";

      ###########################################
      ## YAML Configuration and Schema Mapping ##
      ###########################################

      "[yaml]" = {
        "editor.formatOnSave" = false;
      };

      # Associate Kubernetes schema with Helm template files
      "yaml.schemas" = {
        "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.22.4-standalone-strict/all.json" =
          [
            "**/templates/*.yaml"
            "**/templates/*.yml"
          ];
      };

      #######################################
      ## JavaScript/TypeScript Preferences ##
      #######################################

      "javascript.updateImportsOnFileMove.enabled" = "always";
      "eslint.validate" = [ "javascript" ];

      ################################
      ##  Python-Specific Settings  ##
      ################################

      # Set Black as the default formatter for Python
      "[python]" = {
        "editor.defaultFormatter" = "ms-python.black-formatter";
      };

      # Pass custom args to Black formatter (e.g. using pyproject.toml)
      "black-formatter.args" = [
        "--config"
        "\${workspaceFolder}/pyproject.toml"
      ];

      # Use isort with Black profile
      "isort.args" = [
        "--profile"
        "black"
      ];

      "pylint.args" = [ "--disable=C0116,C0114,C0301" ];

      "flake8.args" = [ "--ignore=E501,E203,E731,E402" ];
      "flake8.ignorePatterns" = [
        "**/site-packages/**/*.py"
        ".vscode/*.py"
        ".git"
        "__pycache__"
      ];

      "python.analysis.typeCheckingMode" = "standard";

      # Enable strict typing evaluations and hints
      "python.analysis.typeEvaluation.deprecateTypingAliases" = true;
      "python.analysis.typeEvaluation.disableBytesTypePromotions" = true;
      "python.analysis.typeEvaluation.enableReachabilityAnalysis" = true;

      # Enable Python inlay hints for better DX
      "python.analysis.inlayHints.functionReturnTypes" = true;
      "python.analysis.inlayHints.callArgumentNames" = "all";
      "python.analysis.inlayHints.pytestParameters" = true;
    };
    # sadly not all vscode-extensions work with vscodium
    #package = pkgs.vscodium;
  };
}
