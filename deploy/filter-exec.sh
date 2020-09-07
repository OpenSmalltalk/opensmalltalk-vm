#!/bin/bash
# Deployment filter (compatible with Travis and AppVeyor)
#
# execute script if:
#   - $BINTRAYAPIKEY is set
#   - REPOSITORY=OpenSmalltalk/opensmalltalk-vm
#   - Build is not triggered by a pull request
#   - BRANCH=Cog or TAG_NAME is not empty

readonly REPO_NAME="${TRAVIS_REPO_SLUG:-${APPVEYOR_REPO_NAME}}"
readonly PR_SHA="${TRAVIS_PULL_REQUEST_SHA:-${APPVEYOR_PULL_REQUEST_HEAD_COMMIT}}"
readonly BRANCH_NAME="${TRAVIS_BRANCH:-${APPVEYOR_REPO_BRANCH}}"
readonly TAG_NAME="${TRAVIS_TAG:-${APPVEYOR_REPO_TAG_NAME}}"

if [[ -z "${BINTRAYAPIKEY}" ]]; then
  echo 'Skipping a deployment because $BINTRAYAPIKEY was not provided.'
  exit
fi

if [[ "${REPO_NAME}" != "OpenSmalltalk/opensmalltalk-vm" ]]; then
  echo "Trying to deploy in repository: ${REPO_NAME}. Skipping."
  exit
fi

if [[ -n "${PR_SHA}" ]]; then
  echo "Skipping a deployment with the script provider because PRs are not permitted."
  exit
fi

if [[ "${BRANCH_NAME}" != "Cog" ]] && [[ -z "${TAG_NAME}" ]]; then
  echo "Skipping a deployment with the script provider because this branch is not permitted."
  exit
fi

`dirname $0`/$1
