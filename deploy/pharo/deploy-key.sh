#! /bin/bash
# This script will add a deploy key to the CI;
# Required environment variables:
# 
#	PHARO_DEPLOY_KEY   		- The -K key (a phrase on hex)
# 	PHARO_DEPLOY_KEY_IV   	- The -iv key (a phrase on hex)
# 	PHARO_DEPLOY_USER		- The username for deploying

set -e

if [ ! -e ~/.shh ]; then
	mkdir -p ~/.ssh
fi
openssl aes-256-cbc -K $PHARO_DEPLOY_KEY -iv $PHARO_DEPLOY_KEY_IV -in deploy_key.enc -out ~/.ssh/id_rsa -d
chmod 600 ~/.ssh/id_rsa

echo "Host files.pharo.org
	User $PHARO_DEPLOY_USER
	Hostname ssh.cluster023.hosting.ovh.net
" >> ~/.ssh/config

echo "files.pharo.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6CP8ge+bLZMtSK/GWha70Iih+4qPfXjixz7g4c+is3VmhDBY2JF9mHCUOzTpnYVnfBFomv4EavDGJZU+7a3GzllflJeRdcYt6X+rxKJ6aMa5TIi5m8FRfHyojjVeNWAG2M51U8yonQE8h4nsDcs2y/sXycx5jwvuFUWLuB41ubc28EiYLdHMsI6yq9HygNrxF6QLwWdl17so6qZo91GafpxlZz0YFhHxJ7h8WS/XJAAKQl4rx59Eqo8N1nhwlmQMa0GNJAy0TDTAy/rgF6AG6D47P2evKKvqFSJ7GkjvtzxA7lVS9kS8WmfMHLNOOq+d+BXvVAHfg5VJOQPaWYfRP" >> ~/.ssh/known_hosts
