{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.mlxLm;
  homeDir = config.home.homeDirectory;
in
{
  options.local.mlxLm = {
    enable = lib.mkEnableOption "a loopback-only MLX-LM inference service";

    executable = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/qwen-runtime-bench/.venv/bin/mlx_lm.server";
      description = "Absolute path to the mlx_lm.server executable.";
    };

    modelDirectory = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/qwen-runtime-bench/models";
      description = "Working directory containing the model directory.";
    };

    model = lib.mkOption {
      type = lib.types.str;
      description = "Model directory name relative to modelDirectory.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 18082;
      description = "Loopback port for the OpenAI-compatible API.";
    };

    maxTokens = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8192;
      description = "Default maximum completion token count.";
    };
  };

  config = lib.mkIf (pkgs.stdenv.isDarwin && cfg.enable) {
    launchd.agents.mlx-lm = {
      enable = true;
      config = {
        ProgramArguments = [
          cfg.executable
          "--model"
          cfg.model
          "--host"
          "127.0.0.1"
          "--port"
          (toString cfg.port)
          "--max-tokens"
          (toString cfg.maxTokens)
          "--decode-concurrency"
          "1"
          "--prompt-concurrency"
          "1"
          "--prompt-cache-size"
          "4"
          "--log-level"
          "INFO"
        ];
        WorkingDirectory = cfg.modelDirectory;
        EnvironmentVariables = {
          HOME = homeDir;
          HF_HUB_OFFLINE = "1";
        };
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Interactive";
        ThrottleInterval = 10;
        StandardOutPath = "${homeDir}/Library/Logs/mlx-lm.log";
        StandardErrorPath = "${homeDir}/Library/Logs/mlx-lm.error.log";
      };
    };
  };
}
