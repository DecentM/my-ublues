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

# Load AMD kernel module
#modprobe amdgpu

# Rebind framebuffer to host
echo "efi-framebuffer.0" >/sys/bus/platform/drivers/efi-framebuffer/bind

# Load NVIDIA kernel modules
# modprobe nvidia_drm
# modprobe nvidia_modeset
# modprobe nvidia_uvm
# modprobe nvidia

modprobe nouveau

# Bind VTconsoles: might not be needed
#echo 1 >/sys/class/vtconsole/vtcon0/bind
#echo 1 >/sys/class/vtconsole/vtcon1/bind

sleep 2

# Restart Display Manager
systemctl start graphical.target
