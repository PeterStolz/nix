### Installing on MacOS

cd ~
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 
nix-shell -p git --command "git clone https://github.com/PeterStolz/nix.git"
mkdir .config
ln -s $PWD/nix/home-manager $PWD/.config/home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A switch

