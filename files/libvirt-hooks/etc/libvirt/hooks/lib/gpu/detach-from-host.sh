#!/bin/bash
set -x

# Stop display manager
systemctl isolate multi-user.target

sleep 2

# Unbind EFI Framebuffer
echo efi-framebuffer.0 >/sys/bus/platform/drivers/efi-framebuffer/unbind

if [ -d /tmp/libvirt-hooks ]; then
    rm -rf /tmp/libvirt-hooks
fi

mkdir -p /tmp/libvirt-hooks

{
    lsmod | cut -d ' ' -f1 | grep nvidia
    lsmod | cut -d ' ' -f1 | grep amdgpu
    lsmod | cut -d ' ' -f1 | grep nouveau
} >>/tmp/libvirt-hooks/unloaded-modules.txt

# Unload GPU drivers from the file
while read -r module; do
    if [ -n "$module" ]; then
        modprobe -r "$module"
    fi
done < /tmp/libvirt-hooks/unloaded-modules.txt

# Detach GPU devices from host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-detach pci_0000_07_00_0
virsh nodedev-detach pci_0000_07_00_1

# Load vfio module
modprobe vfio
modprobe vfio-pci
modprobe vfio_iommu_type1
