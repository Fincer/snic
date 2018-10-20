# snic - Switch network interface mode

Toggle between client and router mode on network interface (Linux)

Switch network interface (NIC), such as `eth0` or `wlan0`, from default *client mode* to *router mode*. Basically, you can use the selected network interface to act as a router for your other network client devices such as mobile phones/tablets/etc... and switch it back to client mode quickly if needed.

**In the client mode**, the network interface acts normally as it does on your normal client Linux computer. It retrieves a IPv4 from a DHCP server on your local network and acts as client, etc.

**In the router mode**, a DHCP server on your computer kicks in and allocates IPv4 addresses for any connected client devices (which use a DHCP client, of course). This is similar behavior to normal stock/home router.

- You can perform occasional [MITM attack](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) scenarios without needing a fixed network setup for that
    
- You can occasionally analyze all network traffic going through your network interface, and find out suspicious network traffic originating from a client device
    
- You can quickly extend network area if needed

- You can periodically use the same network interface for playing with Raspberry Pi/Arduino/... and switch quickly back to regular internet connection if needed

- etc. ...

----------------------

## Requirements

- Linux OS

- Software:

    - `sudo`

        - root permissions required to configure NIC settings

    - `bash`

        - the main script uses bash environment

    - `systemd`

        - the core functionality is implemented partly into systemd service files

    - `iproute2`

        - 'ip' command which is required for NIC configuration

    - `dhcp` (server)

        - DHCP server is required to allocate IPv4 addresses for connected clients

    - `hostapd` (for wireless router)

        - hostapd is required to establish a Wi-Fi hotspot (wireless interfaces)

**NOTE:** Although this repository includes PKGBUILD + tar.xz files, this is not dependent on Arch Linux. You can use this repository on other Linux distributions as well. However, you should adapt the settings properly as configuration and file locations may differ.

----------------------

## Files

- `snic.sh` = main script. See section "Snic main script" below

- `snic/` = Snic configuration files. See section "Snic configuration files" below

- `systemd/` = Snic systemd service files. See section "systemd service files" below

- `conf-templates/` = Snic templates for iptables & hostapd. See section "Templates folder" below

## Arch Linux PKGBUILD

- [Link here](https://github.com/Fincer/linux-patches-and-scripts/blob/master/snic/PKGBUILD)

----------------------

## Pre-configuration

### Find your network interfaces

First you need to know which network interfaces you have in your system. You can check the output of `ip address` or `ifconfig` commands or simply take a look into `/sys/class/net` folder.

### Snic main script

Snic main script is a bourne shell script (bash) `snic.sh`. It can be run individually, but for global purposes location such as `/usr/bin/` or `/usr/local/bin` is recommended. If you put the script in these locations (in your $PATH), it is recommended to rename the script from `snic.sh` to `snic` for convenience.

Make sure the main script file is executable, i.e. run `chmod +x snic.sh`

### Snic configuration files

This repository includes some sample configurations for wlan0 and eth0. Please be aware that these network interface names may not be the same you have in your system.

Configuration files of snic should be placed at `/etc/snic/` folder on a Linux system. The *required* files are:

- `/etc/snic/dhcpd4-<nic>.conf`

    - e.g. `/etc/snic/dhcpd4-eth0.conf`

- `/etc/snic/snic-<nic>.conf`

    - e.g. `/etc/snic/snic-eth0.conf`

Please take a look into these files to find correct configuration for your Linux system.

### systemd service files

Additionally, `systemd` service files are usually placed at `/usr/lib/systemd/system/` on a Linux system.

**NOTE:** It is not recommended to `enable` (read: autostart) systemd service files provided by snic! These service files are used by the snic main script for its internal operations.

### Templates folder

This repository includes templates for `iptables.rules` and `hostapd` configuration.

#### iptables.rules

This is a sample `iptables` ruleset file. Change contents as you want. This file includes basic configuration to route traffic from network interface to another one.

**NOTE:** In order to apply traffic between a local client and internet, you must have `iptables` running. In order to check that, run `systemctl is-active iptables`. If the answer is `inactive`, your iptables firewall service is not running.

Before issuing any of the following commands (~before starting iptables), make sure you have your iptables configuration file `/etc/iptables/iptables.rules` set up correctly on your system.

Once the configuration file is OK, you should check whether iptables is started during computer boot process or not: run `systemctl is-enabled iptables`

And finally, to ensure iptables is automatically started during computer boot and, well, started right now: run `sudo systemctl restart iptables && sudo systemctl enable iptables`.

#### hostapd.conf

This is a sample `hostapd` configuration file. Change contents as you want. Usually this file is located at `etc/hostapd/hostapd.conf` on Linux system. On some Linux systems, different locations are used.

----------------------

## Usage

The script syntax is as follows:

- `snic <nic> <mode> <wireless (optional)>`

`wireless` parameter is required only for wireless interfaces.

For instance:

- `snic eth0 router`

    - Set eth0 interface to router mode

    - Set a static IPv4 address for eth0, defined in `/etc/snic/snic-eth0.conf`

    - Start DHCP server on subnet where eth0 belongs to.

    - Disable NetworkManager for this interface because it interferes the connection

- `snic eth0 client`

    - Set eth0 interface to client mode

    - Do not set any IPv4 address, let a DHCP server in our network to give one (requires DHCP client daemon on the computer for which eth0 belongs to. Common clients on Linux are `dhcpcd` and `dhclient`)

    - Enable NetworkManager for this interface, let it handle the connection

- `snic wlan0 router wireless`

    - Set wlan0 interface to router mode.

    - Tell snic script that this is a wireless interface (starts hostapd service)

    - Set a static IPv4 address for eth0, defined in `/etc/snic/snic-wlan0.conf`

    - Start DHCP server on the subnet where wlan0 belongs to.

    - Disable NetworkManager for this interface because it interferes the connection

- `snic wlan0 client wireless`

    - Set wlan0 interface to client mode

    - Tell snic script that this is a wireless interface (stops hostapd service)

    - Do not set any IPv4 address, let a DHCP server in our network to give one (requires DHCP client daemon on the computer for which eth0 belongs to. Common clients on Linux are `dhcpcd` and `dhclient`)

    - Enable NetworkManager for this interface, let it handle the connection

----------------------

## Issues

For any connectivity issues, please check the output of following programs/commands:

- program: Wireshark (check traffic of relevant network interfaces)

    - Any weird network traffic such as ARP broadcast requests flooding the whole subnet

- command: `journalctl -xe`

    - Any weird log entries

- command: `route`

    - Network route tables

- command (router mode): `systemctl status snic-dhcpd4@<nic>`

    - Any weird DHCP server log entries

- command (wireless router mode): `systemctl status hostapd`

    - Any weird hostapd log entries

- `ip addr` and/or `ifconfig`

    - Network interface misconfigurations (missing IPv4 addresses or interfaces, etc.)

And double check contents of all relevant snic configuration files described above in "Pre-configuration" section.

## Do not use if...

- **Snic? WTF is it? Useless crap!** Basically, you don't know what the hell snic does, you don't care to find out or you don't find it useful in your setup.

- **Predefined network configuration** Do not use snic for absolutely static Linux network interfaces, in environments where client/router mode switching for a single computer is not required/allowed/recommended

- **DHCP settings are in danger** Be aware that this script may alter your current DHCP server setup. However, your current *DHCP server setup configuration files are **NOT** overwritten (or even touched)* but snic configuration may cause conflicts in your setup, anyway.

Just be careful when adapting snic settings, thank you. Debug your setup if needed.
