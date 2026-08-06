cd ~
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 
nix-shell -p git --command "git clone https://github.com/PeterStolz/nix.git"
mkdir .config
ln -s $PWD/nix/home-manager $PWD/.config/home-manager
# home-manager and nixpkgs must be on the SAME release. The Determinate installer
# resolves <nixpkgs> via the flake registry (extra-nix-path = nixpkgs=flake:nixpkgs),
# so bumping only the channel leaves nixpkgs behind and eval fails on missing lib
# paths (e.g. lib/services/lib.nix).
nix registry add nixpkgs github:NixOS/nixpkgs/nixpkgs-26.05-darwin
# kind 0.32.0 is ahead of 26.05 — home.nix overlays it from this channel.
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
nix-channel --add https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install


curl -O https://desktop.docker.com/mac/main/arm64/Docker.dmg
sudo hdiutil attach Docker.dmg
sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
sudo hdiutil detach /Volumes/Docker
