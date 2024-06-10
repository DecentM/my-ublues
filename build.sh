#!/bin/bash

set -ouex pipefail

RELEASE="$(rpm -E %fedora)"
export RELEASE

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# add gcloud-cli repo
rpm-ostree install https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64.rpm

# this installs a package from fedora repos
rpm-ostree install \
    screen tailscale \
    libxcrypt-compat google-cloud-cli

systemctl enable docker.socket docker.service

systemctl disable podman.socket kde-baloo.service
systemctl mask podman.socket

flatpak uninstall -y \
    io.github.flattool.Warehouse \
    org.fedoraproject.MediaWriter \
    org.gnome.DejaDup \
    org.gnome.world.PikaBackup \
    org.kde.haruna \
    org.kde.kclock \
    org.kde.kweather \
    org.mozilla.Thunderbird

flatpak install -y \
    com.anydesk.Anydesk \
    com.bitwarden.desktop \
    com.slack.Slack \
    com.stremio.Stremio \
    dev.vencord.Vesktop \
    ee.ria.DigiDoc4 \
    io.dbeaver.DBeaverCommunity \
    io.github.slgobinath.SafeEyes \
    net.cozic.joplin_desktop \
    one.ablaze.Floorp \
    org.kde.konsole \
    org.signal.Signal \
    us.zoom.Zoom

# install nerd fonts
git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git
cd nerd-fonts
./install.sh FiraCode
cd ..
rm -rf nerd-fonts
