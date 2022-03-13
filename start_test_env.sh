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

RESTRICTION="with"
REFRESH_DB=false
CREATE_ACCOUNTS=false
DEBUG_TOOLS=false
SERVER_TO_INSTALL="1"

function help() {
  colorprint "$YELLOW" "This script starts the usually three matrix-server with their regarding proxies. It can be customized a little with following options"
  colorprint "$RED" "Options:"
  colorprint "$BLUE" "-w -> starts setup with not restricting proxies
-d -> refresh db
-c -> creates accounts (highly recommended if DB got refreshed or initial start)
-i -> installs debgging tools on first matrix server. If followed by a number (2 || 3) second and thrid can be installed as well
-n -> if set the docker image build will be done without cache
-s -> shuts down all running containers regarding this project
-h -> help
"
  colorprint "$CYAN" "Most common commands for a clean environment:
Without restricting Proxies -> ./start_test_env -w -c -d
With restricting Proxies -> ./start_test_env -c -d
"
}

### CONFIG FUNCTIONS
function do_checks() {
  DOCKER_OUTPUT=$(docker ps)
  DOCKER_REG='.*CONTAINER ID.*$'
  if [[ ! $DOCKER_OUTPUT =~ $DOCKER_REG ]]; then
    colorprint "$RED" "Seems your docker engine is not running. Please start Docker first"
    colorprint "$YELLOW" "If you haven't Docker installed, visit https://docs.docker.com/engine/install/"
    exit 1
  fi
}

### DB FUNCTIONS
function delete_db() {
  colorprint "$GREEN" 'Deleting old DB'
  rm "${PWD}"/server/config_a/homeserver.db
  rm "${PWD}"/server/config_b/homeserver.db
  rm "${PWD}"/server/config_c/homeserver.db
}

function refresh_db() {
  colorprint "$GREEN" 'Copy fresh DB'
  cp "${PWD}"/server/emptyDB.db "${PWD}"/server/config_a/homeserver.db
  cp "${PWD}"/server/emptyDB.db "${PWD}"/server/config_b/homeserver.db
  cp "${PWD}"/server/emptyDB.db "${PWD}"/server/config_c/homeserver.db
  # Delete DB also means that custom chat logs can be delete
  colorprint "$GREEN" "Delete custom log"
  rm "${PWD}"/client/custom_log.txt || colorprint "$YELLOW" "No custom log found"
}

### DOCKER FUNCTIONS
function stop() {
  colorprint "$GREEN" "Stoping running servers"
  docker compose -f ./server/docker-compose.yml down -v
}

function start() {
  colorprint "$GREEN" "Going to start server with restriction proxy ..."
  docker compose -f "./server/docker-compose.yml" up -d
  install_root_ca first.m_server
  install_root_ca second.m_server
  install_root_ca third.m_server
}

function install_root_ca() {
  colorprint "$GREEN" "Install custom rootCA for ${1}"
  docker exec -it "$1" bash -c "cp /app/*.crt /usr/share/ca-certificates \
      && echo tvr-root-ca.crt >> /etc/ca-certificates.conf \
      && update-ca-certificates > /dev/null \
    "
}

function install_test_packages() {
  colorprint "$GREEN" "Installing debugtools for first.m_server"
  docker exec -it first.m_server bash -c "apt-get update -q > /dev/null && apt-get install tcpdump iputils-ping -y -q > /dev/null"
  if [ $SERVER_TO_INSTALL -eq "2" ] || [ $SERVER_TO_INSTALL -eq "3" ]; then
    colorprint "$GREEN" "Installing debugtools for second.m_server"
    docker exec -it second.m_server bash -c "apt-get update -q > /dev/null && apt-get install tcpdump iputils-ping -y -q > /dev/null"
  fi
  if [ $SERVER_TO_INSTALL -eq "3" ]; then
    colorprint "$GREEN" "Installing debugtools for third.m_server"
    docker exec -it third.m_server bash -c "apt-get update -q > /dev/null && apt-get install tcpdump iputils-ping -y -q > /dev/null"
  fi
}

function update_federation_data() {
  docker exec first.server curl localhost:8080/update -s -o /dev/null
}

### CREATE DATA FUNCTIONS
function create_accounts() {
  # To ensure the Matrix Server are running
  sleep 5
  colorprint "$GREEN" 'Creating admin user <User=admin> <Password=admin> on every server'
  docker exec -it first.m_server register_new_matrix_user http://localhost:8008 -c ./data/homeserver.yaml -u admin_a -p admin -a
  docker exec -it second.m_server register_new_matrix_user http://localhost:8008 -c ./data/homeserver.yaml -u admin_b -p admin -a
  docker exec -it third.m_server register_new_matrix_user http://localhost:8008 -c ./data/homeserver.yaml -u admin_c -p admin -a

  colorprint "$GREEN" 'Creating normal user <User=user> <Password=user> on every server'
  docker exec -it first.m_server register_new_matrix_user http://localhost:8008 -c ./data/homeserver.yaml -u user_a -p user --no-admin
  docker exec -it second.m_server register_new_matrix_user http://localhost:8008 -c ./data/homeserver.yaml -u user_b -p user --no-admin
  docker exec -it third.m_server register_new_matrix_user http://localhost:8008 -c ./data/homeserver.yaml -u user_c -p user --no-admin
}

### PARSE ARGS
function parse_args() {
  while [ $# -ne 0 ]; do
    case "$1" in
    -w)
      export RESTRICTION="without"
      ;;
    -d)
      REFRESH_DB=true
      ;;
    -c)
      CREATE_ACCOUNTS=true
      ;;
    -i)
      DEBUG_TOOLS=true
      if [ ! -z "$2" ]; then
        if [ "$2" -eq "2" -o "$2" -eq "3" ]; then
          SERVER_TO_INSTALL=$2
          shift
        fi
      fi
      ;;
    -s)
      stop
      exit 0
      ;;
    -h)
      help
      exit 0
      ;;
    -u)
      colorprint "$YELLOW" "Updating all proxies"
      colorprint "$MAGENTA" "First server"
      docker exec first.server nginx -s reload
      if [ ! -z "$2" ]; then
        if [ "$2" -eq "2" ]; then
          docker exec first.server nginx -s reload
          colorprint "$MAGENTA" "Second server"
          docker exec second.server nginx -s reload
          shift
        fi
        if [ "$2" -eq "3" ]; then
          colorprint "$MAGENTA" "Second server"
          docker exec second.server nginx -s reload
          colorprint "$MAGENTA" "Third"
          docker exec third.server nginx -s reload
          shift
        fi
      fi
      exit 0
      ;;
    *)
      colorprint "$RED" "Unknown argument $1"
      help
      exit 1
      ;;
    esac
    shift
  done
}
#
#### RUN
do_checks
parse_args "$@"
stop
if $REFRESH_DB; then
  delete_db
  refresh_db
fi
start
if $CREATE_ACCOUNTS; then
  create_accounts
fi
if $DEBUG_TOOLS; then
  install_test_packages
fi
update_federation_data
