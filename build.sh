#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"
export RELEASE

mkdir -p "/tmp/build-${RELEASE}"
cd "/tmp/build-${RELEASE}"

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

cp -a /tmp/dotfiles /var/opt/

# add gcloud-cli repo
tee -a /etc/yum.repos.d/google-cloud-sdk.repo <<EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

rpm-ostree override remove \
    fish plasma-wallpapers-dynamic-builder-fish-completion \
    ptyxis devpod lxc lxd-agent lxd p7zip podman-compose podman-tui podmansh

# this installs a package from fedora repos
rpm-ostree install \
    screen tlp \
    libxcrypt-compat google-cloud-cli

systemctl enable docker.socket docker.service

# Install AudioRelay
# mkdir audiorelay
# cd audiorelay

# wget https://dl.audiorelay.net/setups/linux/audiorelay-0.27.5.tar.gz -O audiorelay.tar.gz
# tar -xzf audiorelay.tar.gz
# rm -f audiorelay.tar.gz

# cd -

# mv audiorelay /usr/share/
# ln -s /usr/share/audiorelay/bin/AudioRelay /usr/bin/AudioRelay

# flatpak uninstall -y \
#     io.github.flattool.Warehouse \
#     org.fedoraproject.MediaWriter \
#     org.gnome.DejaDup \
#     org.gnome.world.PikaBackup \
#     org.kde.haruna \
#     org.kde.kclock \
#     org.kde.kweather \
#     org.mozilla.Thunderbird

# flatpak install -y \
#     com.anydesk.Anydesk \
#     com.bitwarden.desktop \
#     com.slack.Slack \
#     com.stremio.Stremio \
#     dev.vencord.Vesktop \
#     ee.ria.DigiDoc4 \
#     io.dbeaver.DBeaverCommunity \
#     io.github.slgobinath.SafeEyes \
#     net.cozic.joplin_desktop \
#     one.ablaze.Floorp \
#     org.kde.konsole \
#     org.signal.Signal \
#     us.zoom.Zoom
