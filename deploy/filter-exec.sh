# Deployment filter (compatible with Travis and AppVeyor)
#
# execute script if: 
#   - REPOSITORY=OpenSmalltalk/opensmalltalk-vm
#   - BRANCH=Cog

if [ "${TRAVIS_REPO_SLUG:-${APPVEYOR_REPO_NAME}}" != "OpenSmalltalk/opensmalltalk-vm" ]; then
	echo "Trying to deploy in repository: ${APPVEYOR_REPO_NAME}. Skipping."
	exit
fi

if [ "${TRAVIS_BRANCH:-${APPVEYOR_REPO_BRANCH}}" != "Cog" ]; then
  echo "Skipping a deployment with the script provider because this branch is not permitted"
	exit
fi

sh `dirname $0`/$1