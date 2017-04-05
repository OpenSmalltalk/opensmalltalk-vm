# deploy if repository is OpenSmalltalk/opensmalltalk-vm

if [[ "$FLAVOR" != *pharo* ]]; then
	exit 
fi

if [ "$APPVEYOR_REPO_NAME" != "OpenSmalltalk/opensmalltalk-vm" ]; then
	echo "Trying to deploy in repository: $APPVEYOR_REPO_NAME. Skipping."
	exit 
fi

# deploy on master branch
if [ "$APPVEYOR_REPO_BRANCH" != "Cog" ]; then
	echo "Trying to deploy in branch: $APPVEYOR_REPO_BRANCH. Skipping."
	exit 
fi

sh `dirname $0`/deploy-files.pharo.org.sh