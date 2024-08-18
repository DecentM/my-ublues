#!/bin/sh

set -euo

dnf install -y \
    gcc gcc-c++ glib glib-devel glibc glibc-devel glib2 \
    glib2-devel libusb nss-devel pixman pixman-devel \
    libX11 libX11-devel libXv libXv-devel gtk-doc libgusb \
    libgusb-devel gobject-introspection gobject-introspection-devel \
    ninja-build git libgudev-devel cairo-devel meson gdb valgrind

mkdir fingerprint && cd fingerprint

git clone https://gitlab.freedesktop.org/3v1n0/libfprint.git && cd libfprint
git checkout tags/v1.94.1+tod1

# https://gitlab.freedesktop.org/3v1n0/libfprint/-/merge_requests/1/diffs?commit_id=485b0060a7899f24c6ce0a354d46193b251d9422
sed -i "s/        source_dir: 'tod-drivers',//" tests/meson.build

meson builddir && cd builddir
meson compile && meson install

# Overwrite the system libfprint with our version
cp libfprint/libfprint-2.so.2.0.0 /usr/lib64/
cp libfprint/tod/libfprint-2-tod.so /usr/lib64/
cp libfprint/tod/libfprint-2-tod.so.1 /usr/lib64/

cd ../..

wget http://dell.archive.canonical.com/updates/pool/public/libf/libfprint-2-tod1-goodix/libfprint-2-tod1-goodix_0.0.4-0ubuntu1somerville1.tar.gz
tar -xvf libfprint-2-tod1-goodix_0.0.4-0ubuntu1somerville1.tar.gz

# Move the libfprint driver to where we think it should go
mkdir -p \
    /usr/lib/libfprint-2/tod-1/ \
    /usr/local/lib64/libfprint-2/tod-1/ \
    /var/lib/fprint/goodix

cp libfprint-2-tod1-goodix/usr/lib/x86_64-linux-gnu/libfprint-2/tod-1/libfprint-tod-goodix-53xc-0.0.4.so /usr/lib/libfprint-2/tod-1/
ln -s /usr/lib/libfprint-2/tod-1/libfprint-tod-goodix-53xc-0.0.4.so /usr/local/lib64/libfprint-2/tod-1/libfprint-tod-goodix-53xc-0.0.4.so
chmod 755 /usr/lib/libfprint-2/tod-1/libfprint-tod-goodix-53xc-0.0.4.so
cp libfprint-2-tod1-goodix/lib/udev/rules.d/60-libfprint-2-tod1-goodix.rules /lib/udev/rules.d/

cat libfprint-2-tod1-goodix/debian/modaliases >>"/lib/modules/$(uname -r)/modules.alias"
