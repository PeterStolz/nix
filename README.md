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
# Newer Determinate installers point nix-path straight at nixpkgs-weekly, which
# bypasses the registry pin entirely -- see Gotchas.
mkdir -p ~/.config/nix && echo 'nix-path = nixpkgs=flake:nixpkgs' > ~/.config/nix/nix.conf

git clone https://github.com/PeterStolz/nix.git ~/nix
mkdir -p ~/.config && ln -sfn ~/nix/home-manager ~/.config/home-manager

# home.nix overlays kind from the nixpkgs-unstable channel — 0.32.0 is ahead of
# what 26.05 ships, and the overlay references the channel by name.
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
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
| `HM_GIT_NAME` | `local.git.userName` | Commit author name, for machines used by someone else. |
| `HM_GIT_EMAIL` | `local.git.userEmail` | Commit author email. |
| `HM_GIT_SIGNINGKEY` | `local.git.signingKey` | GPG key id. Only consulted when signing is on. |

The three `HM_GIT_*` ones take a value rather than a flag, and an empty or unset
variable falls back to the default rather than blanking the setting.

```sh
printf 'HM_HEADLESS=1\nHM_NO_SIGN=1\n' | sudo tee -a /etc/environment
```

`/etc/environment` rather than a shell rc file, because home-manager owns
`~/.bashrc`. They are read with `builtins.getEnv`, so they must be in the
environment for *every* `home-manager switch`, not just the first.

Use these instead of editing a machine's checkout — that is the drift the
Updating section warns about.

### Shared machines

`/etc/environment` is system-wide, so the `HM_GIT_*` variables cannot differ
between two people logged into the same box — everyone would commit under one
author. `HM_HEADLESS`/`HM_NO_SIGN` are fine there because they hold the same
value for every user on the machine.

For that case drop an untracked `home-manager/local.nix`. It is imported when
present and gitignored, so `git pull --ff-only` keeps working:

```nix
{
  local.git.userName = "Philipp";
  local.git.userEmail = "philipp@detesia.com";
}
```

Machine-local services can be enabled there as well. For example, the MLX-LM
module runs an OpenAI-compatible inference server on loopback only:

```nix
{
  local.mlxLm = {
    enable = true;
    model = "Qwen3.6-27B-4bit";
  };
}
```

The executable defaults to `~/qwen-runtime-bench/.venv/bin/mlx_lm.server` and
the model directory to `~/qwen-runtime-bench/models`; both are overrideable.

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
- **`<nixpkgs>` only reaches the flake registry if `nix-path` sends it there.**
  The registry pin (`nix registry add nixpkgs ...`) is not enough on its own —
  `nix-path` is consulted first, and only an *indirect* ref like `flake:nixpkgs`
  falls through to the registry. Older Determinate installers wrote exactly that,
  so the pin took; newer ones (3.17) write a concrete flakeref instead:

  ```
  extra-nix-path = nixpkgs=flake:https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/*.tar.gz
  ```

  which pins nothing and silently ignores the registry — you end up on
  `nixpkgs-weekly` (26.11pre-git) while home-manager is on `release-26.05`, i.e.
  the release mismatch above. Fix with a user-level `~/.config/nix/nix.conf`
  (read last, so it overrides `/etc/nix/nix.conf`):

  ```
  nix-path = nixpkgs=flake:nixpkgs
  ```

  Always verify with `nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'`
  rather than `nix config show nix-path`, which happily reports an override that
  isn't winning.
- **`home.nix` overlays `kind` from the `nixpkgs-unstable` channel.** The install
  commands above add it; a machine without it fails at eval, not at switch. The
  overlay only swaps that one package — everything else stays on 26.05. The
  channel drifts, so kind may move past 0.32.0 on future switches; pin the
  channel to a commit (`nix-channel --add
  https://github.com/NixOS/nixpkgs/archive/<rev>.tar.gz nixpkgs-unstable`) to
  freeze it.
- Anything darwin-only (`targets.darwin.*`) needs `lib.mkIf pkgs.stdenv.isDarwin`;
  those modules assert on other platforms rather than no-op'ing.
