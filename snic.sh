#!/bin/env bash

# Toggle between client/router mode on selected network interface
# Copyright (C) 2018  Pekka Helenius
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

########################

# Usage:

# chmod +x snic.sh

# and then

# Wired network interface, example:

# snic.sh eth0 router              // Switch eth0 to router mode
# snic.sh eth0 client              // Switch eth0 to client mode

# snic.sh wlan0 router wireless    // Switch wlan0 to router (Wi-Fi hotspot) mode
# snic.sh wlan0 client wireless    // Switch wlan0 to client mode

# snic.sh <interface> <mode> <wireless (optional)>

# <wireless (optional)> should be used only for wireless interfaces!

########################

# This script is for network interfaces which do NOT support
# simultanous Client/Router mode defined in
# https://archlinux.org/index.php/software_access_point

########################

nic=${1}

for niccheck in $(ls /sys/class/net); do
    if [[ ${nic} == ${niccheck} ]]; then
        nicfound=
    fi
done

if [[ ! -v nicfound ]]; then
    echo "No such network interface. Aborting."
    exit 1
fi

########################

if [[ ${2} != "router" ]] && [[ ${2} != "client" ]]; then
    echo "Invalid mode. Use either 'router' or 'client'. Aborting."
    exit 1
fi

########################

# This mode removes dynamically allocated IPv4 address from NIC interface
# After that we allocate a fixed IPv4 address, defined in
# /etc/vnic/vnic-<interface>.conf file.

# After setting up a fixed IPv4 address
# DHCP server is enabled for the NIC interface

# Wired:    Enable Ethernet router mode
# Wireless: Enable Wi-Fi hotspot router mode

# 

if [[ ${2} == "router" ]]; then

    #Do not let NetworkManager interfere our connection on this interface
    sudo nmcli device set ${nic} managed no 2>/dev/null

    sudo systemctl stop snic-dynamic@${nic}
    sudo systemctl restart snic-static@${nic}

    sudo systemctl restart snic-dhcpd4@${nic}

    if [[ ${3} == "wireless" ]]; then
        sudo systemctl restart hostapd
    fi
fi

###############

# This mode removes fixed IPv4 address from NIC interface
# and reserves the interface for dynamic IPv4 retrieved
# from a DHCP server
# Additionally, we stop running DHCP server on the NIC interface

# Wired:    Enable Ethernet client mode
# Wireless: Enable Wlan client mode

if [[ ${2} == "client" ]]; then

    #Let NetworkManager handle our connection on this interface
    sudo nmcli device set ${nic} managed yes 2>/dev/null

    sudo systemctl stop snic-static@${nic}
    sudo systemctl restart snic-dynamic@${nic}

    sudo systemctl stop snic-dhcpd4@${nic}

    if [[ ${3} == "wireless" ]]; then
        sudo systemctl stop hostapd
    fi
fi
