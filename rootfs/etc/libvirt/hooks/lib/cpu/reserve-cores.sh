#!/bin/bash

# Cores reserved for the host machine
# Must include QEMU IO/Emulation cores if configured
# Ex: 1st Core -> reserved=0
# Ex: 1st & 2nt Cores -> reserved=0,1
# Ex: 1st Physical Core (16 Virtual Cores) -> reserved=0,8
reserved=14,15

systemctl set-property --runtime -- system.slice AllowedCPUs=$reserved
systemctl set-property --runtime -- user.slice AllowedCPUs=$reserved
systemctl set-property --runtime -- init.slice AllowedCPUs=$reserved
