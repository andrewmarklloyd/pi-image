#!/bin/bash


get_image() {
	xml=$(curl -s https://downloads.raspberrypi.org/raspbian_lite_latest)
	sub=${xml#*href=\"}
	url=${sub%\">here*}
	curl -O ${url}
}

enable_ssh() {
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

configure_wifi() {
	echo
}


case ${1} in
	enable-ssh )
		configure_ssh
		;;
	copy-key )
		username=${2}
		host=${3}
		ssh_key_path=${4}
		echo $username
		echo $host
		echo $ssh_key_path
		if [[ -z ${username} || -z ${host} || -z ${ssh_key_path} ]]; then
		  echo "Wrong arguments used"
		  exit 1
		fi
		copy_key
		;;
	config-wifi )
		echo 'Enter the ssid of the wifi network.'
		read ssid
		echo 'Enter the psk of the wifi network.'
		read -s psk
		if [[ -z ${ssid} || -z ${psk} ]]; then
		  echo "Wrong arguments used"
		  exit 1
		fi
		tmpYaml=$(mktemp)
		echo "ssid: ${ssid}" > ${tmpYaml}
		echo "psk: ${psk}" >> ${tmpYaml}
		gotpl wpa_supplicant.conf.tmpl < ${tmpYaml} > /Volumes/boot/wpa_supplicant.conf
		rm ${tmpYaml}
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
esac
