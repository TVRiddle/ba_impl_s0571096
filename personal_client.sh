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

LOG_LOCATION="${PWD}"/client/custom_log.txt

function help() {
  colorprint "$BLACK_GREEN" "#########################################################################################"
  colorprint "$BLACK_GREEN" "### This is the introduction how you can use this script to do all the stuff you want ###"
  colorprint "$BLACK_GREEN" "#########################################################################################"
  colorprint "$CYAN" "Available Servers:
  1: first.server
  2: second.server
  3: third.server"
  colorprint "$YELLOW" "Commands (order is important!):"
  colorprint "$BLUE" "cu (create user)    -> <server_number> <user_name>"
  colorprint "$BLUE" "cr (create room)    -> <server_number> <user_name> <room_name> (server_number have to fit to user)"
  colorprint "$BLUE" "iu (invite user)    -> <server_number_invite_user> <invite_user_name> <room_name> <server_number_invited_user <invited_user_name>"
  colorprint "$BLUE" "wm (write message)  -> <server_number> <user_name> <room_name> <message>"
  colorprint "$BLUE" "rm (read message)   -> <server_number> <user_name> <room_name>"
  colorprint "$BLUE" "gd (get done)       -> No parameter. Just prints out what you already have done"
}

function check() {
  if [ "$1" != "$2" ]; then
    colorprint "$RED" "Not correct amount of parameters. Have a look at the manual:"
    help
    exit 1
  fi
}

function get_server() {
  if [[ $1 =~ [1-3] ]]; then
    if [ "$1" -eq 1 ]; then
      local var="first.m_server"
    elif [ "$1" -eq 2 ]; then
      local var="second.m_server"
    elif [ "$1" -eq 3 ]; then
      local var="third.m_server"
    fi
  else
    colorprint "$RED" "Invalid server ${1}. Please name one between 1 and 3"
  fi
  echo $var
}

function log() {
  echo "$1" >>"$LOG_LOCATION"
}

function create_user() {
  check $# 2
  SERVER=$(get_server "$1")
  colorprint "$BLACK_GREEN" "Create user $2 on $(echo $SERVER | sed 's/m_//')"
  docker exec -it "$SERVER" register_new_matrix_user http://localhost:8008 -c ./data/homeserver.yaml -u "${2}" -p "${2}" --no-admin || exit 1
  log "Create user $2 on $(echo $SERVER | sed 's/m_//')"
}

function create_room() {
  check $# 3
  colorprint "$BLACK_GREEN" "Create room ${3} for user ${2}"
  SERVER=$(get_server "$1")
  python "${PWD}"/client/custom_client.py create-room "$SERVER" "$2" "$3"
  log "User $2 created room $3 on $(echo $SERVER | sed 's/m_//')"
}

function invite_user() {
  check $# 5
  SERVER=$(get_server "$1")
  SERVER_INV=$(get_server "$4")
  colorprint "$BLACK_GREEN" "Invite User: From $2||$(echo $SERVER | sed 's/m_//') to $5||$(echo $SERVER_INV | sed 's/m_//') in room $3"
  python "${PWD}"/client/custom_client.py invite-user "$SERVER" "$2" "$3" "$SERVER_INV" "$5"
  log "User $2 on $(echo $SERVER | sed 's/m_//') invited user $5 on $(echo $SERVER_INV | sed 's/m_//') to room $3"
}

function write_message() {
  check $# 4
  SERVER=$(get_server "$1")
  colorprint "$BLACK_GREEN" "From $2||$(echo $SERVER | sed 's/m_//') to room $3 Write message: $4"
  python "${PWD}"/client/custom_client.py write-message "$SERVER" "$2" "$3" "$4"
  log "User $2 wrote in room $3 $4"
}

function read_message() {
  check $# 3
  SERVER=$(get_server "$1")
  colorprint "$BLACK_GREEN" "Get all messages from user $2 in room $3"
  python "${PWD}"/client/custom_client.py read-message "$SERVER" "$2" "$3"
  log "User $2 requested messages from room $3"
}

COMMAND="$1"
shift
if [ "$COMMAND" == "cu" ]; then
  create_user "$@"
elif [ "$COMMAND" == "cr" ]; then
  create_room "$@"
elif [ "$COMMAND" == "iu" ]; then
  invite_user "$@"
elif [ "$COMMAND" == "wm" ]; then
  write_message "$@"
elif [ "$COMMAND" == "rm" ]; then
  read_message "$@"
elif [ "$COMMAND" == "gd" ]; then
  cat "$LOG_LOCATION"
  exit 0
else
  colorprint "$RED" "Unknown command $1"
  help
  exit 1
fi
