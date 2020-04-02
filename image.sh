#!/bin/bash


get_image() {
	xml=$(curl -s https://downloads.raspberrypi.org/raspbian_lite_latest)
	sub=${xml#*href=\"}
	url=${sub%\">here*}
	curl -O ${url}
	if [[ ! -d /Applications/balenaEtcher.app ]]; then
		echo "balenaEtcher application not found. Download at https://www.balena.io/etcher/"
		exit 1
	fi
	echo
	echo "Opening balena Etcher. Select image from the downloaded file at $(pwd). Press enter to continue."
	read
	open /Applications/balenaEtcher.app
}

enable_ssh() {
	echo "Enabling ssh on pi"
	touch /Volumes/boot/ssh
}

copy_key() {
	scp ~/.ssh/${ssh_key_path} ${username}@${host}:
	ssh ${username}@${host} "mkdir -p ~/.ssh; cat ${ssh_key_path} > ~/.ssh/authorized_keys; rm ${ssh_key_path}; sudo passwd pi -d"
}

set_hostname() {
	username=${1}
	host=${2}
	new_hostname=${3}
	ssh ${username}@${host} "sudo sed -i 's/raspberrypi/${new_hostname}/g' /etc/hostname; sudo sed -i 's/raspberrypi/${new_hostname}/g' /etc/hosts; sudo reboot now & exit"
}

set_timezone() {
  username=${1}
  host=${2}
  ssh ${username}@${host} "sudo timedatectl set-timezone America/Los_Angeles"
}

configure_wifi() {
	echo "** The WIFI on Raspberry pi is 2.4GHz only, unless you have a 5GHz dongle. Press enter to continue."
	read
	echo 'Enter the ssid of the wifi network.'
	read ssid
	echo 'Enter the psk of the wifi network.'
	read -s psk
	if [[ -z ${ssid} || -z ${psk} ]]; then
	  echo "Wrong arguments used"
	  exit 1
	fi
	sed "s/{{.ssid}}/${ssid}/" wpa_supplicant.conf.tmpl \
	| sed "s/{{.psk}}/${psk}/" > /Volumes/boot/wpa_supplicant.conf
	echo "Writing wifi connection information to /Volumes/boot/wpa_supplicant.conf. You may now safely eject the SD card, insert it into the Pi, and turn it on."
	echo
	echo "To connect run 'ssh pi@raspberrypi.local'"
}

format_drive() {
	sudo fdisk -l
	echo "Look for your hard drive and note the Device. Type the name of the device then press enter."
	read device
	sudo mkfs.ext4 ${device}
	echo "Taken from https://raspberrytips.com/format-mount-usb-drive/"
}

case ${1} in
	get-image )
		get_image
		;;
	enable-ssh )
		enable_ssh
		;;
	config-wifi )
		configure_wifi
		enable_ssh
		;;
	copy-key )
		username=${2}
		host=${3}
		ssh_key_path=${4}
		if [[ -z ${username} || -z ${host} || -z ${ssh_key_path} ]]; then
		  echo "Wrong arguments used"
		  exit 1
		fi
		copy_key
		;;
	config-hostname )
		username=${2}
		host=${3}
		echo 'Enter the new hostname of the device.'
		read new_hostname
		if [[ -z ${username} || -z ${host} || -z ${new_hostname} ]]; then
		  echo "Wrong arguments used"
		  exit 1
		fi
		set_hostname ${username} ${host} ${new_hostname}
		;;
	set-timezone )
		username=${2}
		host=${3}
		if [[ -z ${username} || -z ${host} ]]; then
		  echo "Wrong arguments used"
		  exit 1
		fi
		set_timezone ${username} ${host}
		;;
esac
