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
    ''
    + (
      if pkgs.stdenv.isDarwin then
        ''
          set -gx MAMBA_EXE "/Users/$INITIAL_USER/.nix-profile/bin/micromamba"
          set -gx MAMBA_ROOT_PREFIX "/Users/$INITIAL_USER/micromamba"
        ''
      else
        ''
          set -gx MAMBA_EXE "/home/$INITIAL_USER/.nix-profile/bin/micromamba"
          set -gx MAMBA_ROOT_PREFIX "/home/$INITIAL_USER/micromamba"
        ''
    )
    + ''
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
    rm_small_imgs = {
      description = "Delete images ≤256 px in either dimension";
      body = ''
            # Accept an optional directory argument; default to "."
            set dir "."
            if test (count $argv) -ge 1
                set dir $argv[1]
            end

            # Find images (case-insensitive) and check their dimensions
            for img in (find $dir -type f \( -iname "*.webp" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \))
                set dims (ffprobe -v error -pattern_type none \
                                     -select_streams v:0 \
                                     -show_entries stream=width,height \
                                     -of default=nokey=1:noprint_wrappers=1 \
                                     -i "$img" 2>/dev/null)
                set width  $dims[1]
                set height $dims[2]

                # Skip files ffprobe couldn’t parse
                if test -z "$width" -o -z "$height"
                    continue
                end

                if test $width  -le 256 -o $height -le 256
                    echo "Deleting $img"
                    rm -- "$img"
                end
            end
      '';
    };

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
