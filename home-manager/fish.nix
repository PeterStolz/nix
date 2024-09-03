{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  home-manager.users.${username} = {
    programs.fish = {
      enable = true;
      interactiveShellInit = ''
        starship init fish | source
        set fish_greeting # Disable greeting
        set -x CUDA_PATH ${pkgs.cudatoolkit}
      '';
      shellAliases = {
        vim = "nvim";
        hm = "home-manager";
      };
      functions = {
        pythonEnv = {
          body = ''
            if set -q argv[2]
              set argv $argv[2..-1]
            end

            for el in $argv
              set ppkgs $ppkgs "python"$pythonVersion"Packages.$el"
            end

            nix-shell -p $ppkgs
          '';
        };
      };
    };
  };
}
