#!/bin/bash
set -x

# Stop display manager
systemctl isolate multi-user.target

sleep 2

# Unbind VTconsoles: might not be needed
#echo 0 >/sys/class/vtconsole/vtcon0/bind
#echo 0 >/sys/class/vtconsole/vtcon1/bind

# Unbind EFI Framebuffer
echo efi-framebuffer.0 >/sys/bus/platform/drivers/efi-framebuffer/unbind

# Unload NVIDIA kernel modules
# modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia

# Unload AMD kernel module
# modprobe -r amdgpu

modprobe -r nouveau

# Detach GPU devices from host
# Use your GPU and HDMI Audio PCI host device
virsh nodedev-detach pci_0000_07_00_0
virsh nodedev-detach pci_0000_07_00_1

# Load vfio module
modprobe vfio
modprobe vfio-pci
modprobe vfio_iommu_type1
