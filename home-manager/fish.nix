{ pkgs, ... }:

{
  enable = true;
  interactiveShellInit =
    ''
      starship init fish | source
      set fish_greeting # Disable greeting
      set -gx GPG_TTY (tty)
      set -gx LD_LIBRARY_PATH $NIX_LD_LIBRARY_PATH

      set -gx INITIAL_USER $USER
      # make vscode auto-activate environments when they are the project interpreter
      alias conda micromamba 
      # >>> mamba initialize >>>
      # !! Contents within this block are managed by 'mamba init' !!
      set -gx MAMBA_EXE "/Users/$INITIAL_USER/.nix-profile/bin/micromamba"
      set -gx MAMBA_ROOT_PREFIX "/Users/$INITIAL_USER/micromamba"
      $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
      # <<< mamba initialize <<<
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
