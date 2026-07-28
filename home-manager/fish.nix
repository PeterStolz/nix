{ lib, pkgs, ... }:

let
  # Use the nixpkgs micromamba by absolute store path. On Darwin `/opt/homebrew/bin`
  # sits ahead of the nix profile in PATH, so a bare `micromamba` would silently
  # resolve to the Homebrew copy instead.
  mambaExe = "${pkgs.micromamba}/bin/micromamba";
in
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # NOTE: starship is initialised by home-manager's
      # programs.starship.enableFishIntegration (the `TERM != dumb` block), so we
      # do NOT call `starship init fish` again here — doing so spawned starship +
      # an extra psub/mktemp on every prompt.
      set fish_greeting # Disable greeting
      set -gx GPG_TTY (tty)

      # nix-ld only exports this on NixOS; exporting an empty LD_LIBRARY_PATH
      # elsewhere makes the loader search the cwd.
      if set -q NIX_LD_LIBRARY_PATH
          set -gx LD_LIBRARY_PATH $NIX_LD_LIBRARY_PATH
      end

      fish_add_path ~/.cargo/bin
      fish_add_path ~/.opencode/bin
      fish_add_path ~/.local/bin

      # >>> mamba initialize >>>
      # !! Contents within this block are managed by 'mamba init' !!
      set -gx MAMBA_EXE ${mambaExe}
      set -gx MAMBA_ROOT_PREFIX $HOME/micromamba

      # Lazy-load micromamba: the `shell hook` spawns micromamba and does temp-file
      # I/O on every interactive shell. Defer it until the first time micromamba is
      # actually used; the hook then redefines this function with the real one.
      function micromamba --wraps micromamba
          functions --erase micromamba
          $MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source
          micromamba $argv
      end
      # <<< mamba initialize <<<
    ''
    + (
      if pkgs.stdenv.isDarwin then
        ''
          fish_add_path /opt/homebrew/bin
        ''
      else
        ''
          fish_add_path /home/linuxbrew/.linuxbrew/bin
        ''
    );

    shellAliases = {
      vim = "nvim";
      hm = "home-manager";
      k = "kubectl";
      tf = "tofu";
      ls = "ls --color=auto " + lib.optionalString (!pkgs.stdenv.isDarwin) "--hyperlink=auto ";
      dive = "docker run -ti --rm  -v /var/run/docker.sock:/var/run/docker.sock wagoodman/dive";
      s = "ssh";
      gs = "git status";
      gc = "git commit";
      # make vscode auto-activate environments when they are the project interpreter
      conda = "micromamba";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      tailscale = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
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

      rm_non_images = {
        description = "Delete every file whose extension is not in torchvision.datasets.folder.IMG_EXTENSIONS";
        body = ''
          python -c '\
          #!/usr/bin/env python
          """
          clean_images.py — Remove non‑image files from a directory tree.

          Examples
          --------
            # In the current directory, preview what will be removed
            python clean_images.py --dry-run

            # In a given directory, preview and then delete after confirmation
            python clean_images.py /data/photos

            # Delete immediately (no prompt), emitting JSON
            python clean_images.py /data/photos --yes --json > removed.json
          """
          from __future__ import annotations

          import json
          import sys
          from pathlib import Path
          from typing import Optional

          import typer
          # from torchvision.datasets.folder import IMG_EXTENSIONS
          IMG_EXTENSIONS = (".jpg", ".jpeg", ".png", ".ppm", ".bmp", ".pgm", ".tif", ".tiff", ".webp")



          app = typer.Typer(help="Delete every file whose extension is not in torchvision.datasets.folder.IMG_EXTENSIONS.")


          def _is_allowed(path: Path) -> bool:
              return path.suffix.lower() in IMG_EXTENSIONS


          @app.command()
          def clean(
              directory: Optional[Path] = typer.Argument(
                  None,
                  exists=False,               # We’ll validate manually once we know cwd vs. user‑supplied
                  help="Root directory to clean. Defaults to the current working directory.",
              ),
              dry_run: bool = typer.Option(False, help="Only list files that would be removed; do not delete."),
              json_output: bool = typer.Option(False, "--json", help="Emit JSON instead of plain text."),
              yes: bool = typer.Option(
                  False,
                  "--yes",
                  "-y",
                  help="Skip the confirmation prompt and delete immediately (useful for CI/pipelines).",
              ),
          ):
              """
              Recursively delete non‑image files inside *DIRECTORY* (or the current directory if none supplied).
              """
              target_dir = directory or Path.cwd()
              if not target_dir.exists() or not target_dir.is_dir():
                  typer.secho(f"Error: {target_dir} is not a valid directory.", fg="red", err=True)
                  raise typer.Exit(code=2)

              to_remove: list[Path] = [p for p in target_dir.rglob("*") if p.is_file() and not _is_allowed(p)]

              # ---------- Present planned deletions ----------
              if json_output:
                  json.dump({"removed": [str(p.relative_to(target_dir)) for p in to_remove]}, sys.stdout, indent=2)
                  sys.stdout.write("\n")
              else:
                  for p in to_remove:
                      typer.echo(f"would remove: {p.relative_to(target_dir)}")
                  typer.echo(f"\n{len(to_remove)} file(s) would be removed.")

              if dry_run:
                  raise typer.Exit(code=0)

              # ---------- Ask for confirmation ----------
              if not yes:
                  if not typer.confirm("Proceed with deletion?"):
                      typer.echo("Aborted. No files were removed.")
                      raise typer.Exit(code=1)

              # ---------- Delete ----------
              for p in to_remove:
                  p.unlink()

              if not json_output:
                  typer.secho(f"{len(to_remove)} file(s) removed.", fg="green")


          if __name__ == "__main__":
              app()
          '
        '';
      };

      pythonEnv = {
        description = "nix-shell with the given packages from a python<version>Packages set";
        body = ''
          if test (count $argv) -lt 2
              echo "usage: pythonEnv <python-version> <package>..." >&2
              echo "example: pythonEnv 312 numpy pandas" >&2
              return 1
          end

          set -l pythonVersion $argv[1]
          set -l ppkgs
          for el in $argv[2..-1]
              set -a ppkgs "python"$pythonVersion"Packages.$el"
          end

          nix-shell -p $ppkgs
        '';
      };
    };
  };
}
