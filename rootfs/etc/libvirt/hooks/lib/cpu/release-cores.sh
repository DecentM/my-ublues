#!/bin/bash

# Host core range numbered from 0 to core count - 1
# You must put all the cores of your host CPU
# Cores not in $cores_for_host are for Guests
# Ex: 8 Cores  -> cores=0-7
# Ex: 16 Cores -> cores=0-15
cores=0-15

systemctl set-property --runtime -- system.slice AllowedCPUs=$cores
systemctl set-property --runtime -- user.slice AllowedCPUs=$cores
systemctl set-property --runtime -- init.slice AllowedCPUs=$cores
