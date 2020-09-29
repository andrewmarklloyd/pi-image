#!/bin/bash

if [[ ${DEBUG} == "true" ]]; then
  echo "Debug mode, exiting"
  exit 0
fi

date > enabled.txt
sudo mv ./wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf
sudo systemctl stop hostapd
sudo systemctl disable hostapd
cp dhcpcd.conf.disabled /etc/dhcpcd.conf
