#!/bin/bash
set -x

# Attach GPU devices to host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-reattach pci_0000_07_00_0
virsh nodedev-reattach pci_0000_07_00_1

# Unload vfio module
modprobe -r vfio_iommu_type1
modprobe -r vfio-pci
modprobe -r vfio

# Rebind framebuffer to host
echo "efi-framebuffer.0" >/sys/bus/platform/drivers/efi-framebuffer/bind

# Reload unloaded GPU drivers
if [ -d /tmp/libvirt-hooks ]; then
    while read -r module; do
        if [ -n "$module" ]; then
            modprobe "$module"
        fi
    done < /tmp/libvirt-hooks/unloaded-modules.txt

    rm -rf /tmp/libvirt-hooks
fi

sleep 2

# Restart Display Manager
systemctl start graphical.target
