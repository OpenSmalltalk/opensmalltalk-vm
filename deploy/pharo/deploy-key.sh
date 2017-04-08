#! /bin/bash
# This script will add a deploy key to the CI;
# Required environment variables:
# 
#	DEPLOY_KEY   	- The -K key (a phrase on hex)
# 	DEPLOY_KEY_IV   - The -iv key (a phrase on hex)
# 	DEPLOY_USER		- The username for deploying

set -ex

if [ ! -e ~/.shh ]; then
	mkdir -p ~/.ssh
fi
openssl aes-256-cbc -K $DEPLOY_KEY -iv $DEPLOY_KEY_IV -in deploy_key.enc -out ~/.ssh/id_rsa -d
chmod 600 ~/.ssh/id_rsa

echo "Host files.pharo.org
	User $DEPLOY_USER
	ProxyCommand ssh $DEPLOY_USER@sesi-ssh.inria.fr \"nc file-pharo.inria.fr %p 2> /dev/null\"
" >> ~/.ssh/config

echo "files.pharo.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCeVezoVox1IBcyqhPZbWaHoJR1R8iYZwZuqYDCjmmp1+bXxdPwI4FNbulc8CvGS+pvmJbWe6ypIksT1BNHOySZ574+mNq73YvgXuyl8FO45D7y22l7tjdQPR3b3XZ6gcTFoW+MTSMmipujN8D71vcbyhT7xQlgnP681LGRhTKbPZBOL84w2iPWc71l7keen/LMW4ifdJR46MdrOyXFNN2pxF3o42wItAv5Koae3ydD6UBw58xQlDsJpr1XVVpxVAEW1vonMs0IYJWKBRxvJVh1k/Nx8GwqlUHxQvjiHFlCheQ6ebuARwCH7ccJETKPxbkkVH1TESzOxjZH5W/miFGD
sesi-ssh.inria.fr ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAnOBtRNSwF5Gj4XmaPaWgIJY3GmONfC1g7/0DU9if5IpJ9Wq76t7fUmnTFBKHbmQsGWMdauPzpcu6iovB08bqZWaXNQj1xjuhj0vrRzgwV/8uYnpDMaB6d65Ef9KY8nnvQDFfD5wT3vdDht8LN4MHNQfeUzax1M0IT+w9uElotd9RgtJE8SnoFN9CGjkpP8C97V3xuXCHKYxVkWpmXIlFrbT1D4ct47DH6t3V8tZbpFbsQwWxUUWdbBsLLcYsXx+aulKiQg+5jXuFfSnA3FfLH8eIKShA0QGfGPB1XkMqffaUY8yzby9DDpBPFBj1zoXQd9qt2Zsti/5VJ38+53PTLw==
" >> ~/.ssh/known_hosts