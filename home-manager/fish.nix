{ pkgs, ... }:

{
  enable = true;
  interactiveShellInit =
    ''
      starship init fish | source
      set fish_greeting # Disable greeting
      set -gx GPG_TTY (tty)
      set -gx LD_LIBRARY_PATH $NIX_LD_LIBRARY_PATH
    ''
    + (
      if pkgs.stdenv.isDarwin then
        ''
          fish_add_path /opt/homebrew/bin
        ''
      else
        ""
    );
  shellAliases = {
    vim = "nvim";
    hm = "home-manager";
    k = "kubectl";
    tf = "tofu";
    ls = "ls --color=auto " + (if !pkgs.stdenv.isDarwin then "--hyperlink=auto " else "");
    dive = "docker run -ti --rm  -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive";
    s = "ssh";
    gs = "git status";
    gc = "git commit";
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
