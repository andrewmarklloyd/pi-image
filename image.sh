#!/bin/bash


get_image() {
	xml=$(curl -s https://downloads.raspberrypi.org/raspbian_lite_latest)
	sub=${xml#*href=\"}
	url=${sub%\">here*}
	curl -O ${url}
}

copy_key() {
	scp ~/.ssh/${ssh_key_path} ${username}@${host}:
	ssh ${username}@${host} "mkdir -p ~/.ssh; cat ${ssh_key_path} > ~/.ssh/authorized_keys; rm ${ssh_key_path}; sudo passwd pi -d"
}

username=${1}
host=${2}
ssh_key_path=${3}
if [[ -z ${username} || -z ${host} || -z ${ssh_key_path} ]]; then
  echo "Wrong arguments used"
  exit 1
fi
