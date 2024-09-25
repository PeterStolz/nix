{ pkgs, ... }:

{
  enable = true;
  interactiveShellInit = ''
    starship init fish | source
    set fish_greeting # Disable greeting
    set -x CUDA_PATH ${pkgs.cudatoolkit}
  '';
  shellAliases = {
    vim = "nvim";
    hm = "home-manager";
    k = "kubectl";
    tf = "tofu";
    ls = "ls --hyperlink=auto --color=auto";
    dive = "docker run -ti --rm  -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive";
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
}
