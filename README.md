# nix

Personal machine config.

- **`home-manager/`** — the user environment: fish + starship, neovim, git, CLI
  tooling, and (on machines with a display) firefox/chromium/vscode/kitty.
  `home.nix` is the entrypoint and imports the rest.
- **`configuration.nix`** — NixOS system config for the `nixos` desktop. Expects a
  machine-local `hardware-configuration.nix`, which is deliberately not in the repo.
- **`networking/`** — port-forwarding notes.

All option names: <https://nix-community.github.io/home-manager/options.xhtml>

## Install

Every case ends the same way: the repo cloned to `~/nix`, with
`~/.config/home-manager` symlinked at `home-manager/`.

### macOS

```sh
bash home-manager/install-mac.sh
```

Determinate installer → pin nixpkgs to `nixpkgs-26.05-darwin` → home-manager
`release-26.05` channel → install. Also installs Docker Desktop.

### Linux, with root

Same shape, but pin the `nixos-` branch instead of the darwin one:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install linux --no-confirm --init systemd
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

nix registry add nixpkgs github:NixOS/nixpkgs/nixos-26.05
git clone https://github.com/PeterStolz/nix.git ~/nix
mkdir -p ~/.config && ln -sfn ~/nix/home-manager ~/.config/home-manager

nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

The first install refuses to clobber an existing `~/.bashrc` / `~/.profile` and
has no `-b backup` flag — move them aside first.

### Linux, no root

```sh
bash home-manager/non-root-install.sh
```

nix-portable under bwrap, into `~/.local/bin`. Slower and more fragile than the
above; only worth it when there is genuinely no sudo.

### NixOS

`configuration.nix` imports `<home-manager/nixos>`, so the system rebuild applies
the user environment too — no separate `home-manager switch`.

## Per-machine switches

Two escape hatches, both read from the environment at eval time:

| Variable | Option | Effect |
| --- | --- | --- |
| `HM_HEADLESS=1` | `local.headless` | Skip everything needing a display — browsers, vscode, kitty, tor-browser. |
| `HM_NO_SIGN=1` | `local.signCommits` | Turn off `commit.gpgsign`, for boxes with no secret GPG key. Without it every commit there fails outright. |

```sh
printf 'HM_HEADLESS=1\nHM_NO_SIGN=1\n' | sudo tee -a /etc/environment
```

`/etc/environment` rather than a shell rc file, because home-manager owns
`~/.bashrc`. They are read with `builtins.getEnv`, so they must be in the
environment for *every* `home-manager switch`, not just the first.

Use these instead of editing a machine's checkout — that is the drift the
Updating section warns about.

## Updating

```sh
cd ~/nix && git pull && home-manager switch -b backup
```

Fix things in the repo and pull, rather than editing a machine's checkout — a
local edit blocks `git pull --ff-only` and drifts silently.

## Gotchas

- **home-manager and nixpkgs must be on the same release.** Mismatches surface as
  confusing option errors deep in unrelated modules (e.g. `release-25.11` against
  nixpkgs 26.05 fails on the neovim plugin submodule).
- **`<nixpkgs>` resolves through the flake registry**, not just `nix-path`. The
  Determinate installer redirects it in both places, and a *user* registry entry
  beats the global one. Verify with `nix-instantiate --find-file nixpkgs` —
  `nix config show nix-path` will happily report an override that isn't winning.
- Anything darwin-only (`targets.darwin.*`) needs `lib.mkIf pkgs.stdenv.isDarwin`;
  those modules assert on other platforms rather than no-op'ing.
