#!/bin/bash

BLACK='\033[30m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
RESET='\033[0m'
BLACK_GREEN='\033[30;42m'

function colorprint() {
  echo -e "${1}""${2}""$RESET"
}

function help() {
  colorprint "$BLACK_GREEN" "###################################################################################"
  colorprint "$BLACK_GREEN" "### Let me tell you how you can customize the directory server the easiest way: ###"
  colorprint "$BLACK_GREEN" "###################################################################################"
  colorprint "$YELLOW" "Just run the script followed by the numbers of the matrix server you want to allow."
  colorprint "$BLUE" "0 -> NO SERVER"
  colorprint "$BLUE" "1 -> first.server"
  colorprint "$BLUE" "2 -> second.server"
  colorprint "$BLUE" "3 -> third.server"
  colorprint "$BLUE" "Example: \"./set_allowed_servers.sh 1 3\" -> (This enables only the first and the second sever to participate in the federation"
  colorprint "$RED" "The changes will be effective immediately if the test environment is already running! You don't have to restart the whole test environment."
}

ALLOWED_SERVERS=""

if [ -z "$1" ]; then
  help
  exit 0
fi

function add_allowed_server() {
  if [ -z "$ALLOWED_SERVERS" ]; then
    ALLOWED_SERVERS=\"$1\"
  else
    ALLOWED_SERVERS=$ALLOWED_SERVERS,\"$1\"
  fi
}

while [ $# -ne 0 ]; do
  if [[ $1 =~ [1-3] ]]; then
    if [ "$1" -eq 1 ]; then
      add_allowed_server "first.server"
    elif [ "$1" -eq 2 ]; then
      add_allowed_server "second.server"
    elif [ "$1" -eq 3 ]; then
      add_allowed_server "third.server"
    fi
  elif [ "$1" == "-h" ]; then
    help
    exit 0
  elif [ "$1" -eq 0 ]; then
    echo "Starting with no allowed servers"
  else
    colorprint "$RED" "##########################"
    colorprint "$RED" "### Unknown argument $1 ###"
    colorprint "$RED" "##########################"
    help
    exit 1
  fi
  shift
done

sed -i "s/\[.*\]/\[${ALLOWED_SERVERS}\]/" ./server/registration_service/default.conf

REG_RUNNING=$(docker ps | grep 'registration_service')
if [ -z "$REG_RUNNING" ]; then
  colorprint "$YELLOW" "Test environment seems not running!"
  exit 0
fi
colorprint "$GREEN" "Updating registration service with new allowed servers: ${ALLOWED_SERVERS}"
docker exec registration_service nginx -s reload
colorprint "$GREEN" "Updating proxies with new allowed servers: ${ALLOWED_SERVERS}"
docker exec first.server curl localhost:8080/update -s -o /dev/null
