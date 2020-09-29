#!/bin/bash

# https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt install hostapd dnsmasq -y

sudo systemctl unmask hostapd
sudo systemctl enable hostapd

sudo DEBIAN_FRONTEND=noninteractive apt install -y netfilter-persistent iptables-persistent

echo "interface wlan0
    static ip_address=192.168.4.1/24
    nohook wpa_supplicant" | sudo tee -a /etc/dhcpcd.conf

sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo "interface=wlan0 # Listening interface
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
                # Pool of IP addresses served via DHCP
domain=wlan     # Local wireless DNS domain
address=/gw.wlan/192.168.4.1
                # Alias for this router" | sudo tee -a /etc/dnsmasq.conf

sudo rfkill unblock wlan

echo "country_code=US
interface=wlan0
ssid=pi-hole-config
hw_mode=g
channel=7
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=pi-hole-config
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP" | sudo tee -a /etc/hostapd/hostapd.conf

sudo systemctl reboot

# connect to wifi: pi-hole-config with password pi-hole-config
# visit http://gw.wlan:8080/ to configure
