travis_fold() {
  local action=$1
  local name=$2
  local title="${3:-}"

  if [[ "${TRAVIS:-}" = "true" ]]; then
    echo -en "travis_fold:${action}:${name}\r\033[0K"
  fi
  if [[ -n "${title}" ]]; then
    echo -e "\033[34;1m${title}\033[0m"
  fi
}
