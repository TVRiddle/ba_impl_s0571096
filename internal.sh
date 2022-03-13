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
SEP="======================================================================"

function colorprint() {
  printf '%b%b%b\n' "${1}" "${2}" "$RESET"
}

function help() {
  colorprint $BLACK_GREEN "#############################################################"
  colorprint $BLACK_GREEN "### This is the internal test for messaging on one server ###"
  colorprint $BLACK_GREEN "#############################################################"
  colorprint $BLUE ""
  colorprint $YELLOW "You can extend this script by adding by some parameters:"
  colorprint $BLUE "
  * Any number between 1 and 3 -> This number represents the amount of servers you want to involve.
  * -r <custom_room_name> -> If you want to create an default room (Usefully if you want to restart the test and want a clean room with no old messages)

On default only the first server will invite and all users will try to send messages.

What happens in this script? The agenda is:
### 1. Admin creates room
### 2. Admin invites the user that is on the same server
### 3. The user join the room
### 4. Both try to write a message
### 5. Admin reads all messages in the room he created"
}

SERVERS_TO_DO="1"
ROOM=""

if [ "$1" == "-h" ]; then
  help
  exit 0
fi

while [ $# -ne 0 ]; do
  if [[ $1 =~ [1-3] ]]; then
    if [ -z "$1" ]; then
      SERVERS_TO_DO="1"
    elif [ "$1" -eq "2" ]; then
      SERVERS_TO_DO="12"
    elif [ "$1" -eq "3" ]; then
      SERVERS_TO_DO="123"
    fi
  elif [ "$1" == "-r" ]; then
    NAMED_ROOM=$2
    shift
  else
    colorprint "$RED" "###########################"
    colorprint "$RED" "### Unknown argument: $1 ###"
    colorprint "$RED" "###########################"
    help
    exit 1
  fi
  shift
done

declare -A server=(
  ["1"]="admin_a,user_a,first_room_internal"
  ["2"]="admin_b,user_b,second_room_internal"
  ["3"]="admin_c,user_c,third_room_internal"
)

function resolve_room() {
  if [ -z "${NAMED_ROOM}" ]; then
    ROOM=$1
  fi
}

function do_roundtrip() {
  resolve_room "$3"
  colorprint "$YELLOW" "$SEP\nDoing roundtrip for $1 and $2 in room ${ROOM}\n$SEP"
  python ./client/cli_client.py create-room -u "$1" -r "${ROOM}"
  python ./client/cli_client.py invite -u "$1" -r "${ROOM}" -n "$2"
  python ./client/cli_client.py send-message -u "$1" -r "${ROOM}" -m "Hey "$2", how do you do?"
  python ./client/cli_client.py send-message -u "$2" -r "${ROOM}" -m "Hey "$1", nice to hear from you. I'm fine, what about you?"
  python ./client/cli_client.py receive-messages -u "$1" -r "${ROOM}"
}

while read -n 1 number; do
  if [ ! -z "$number" ]; then
    IFS="," read -ra NAMES <<<"${server[$number]}"
    do_roundtrip "${NAMES[0]}" "${NAMES[1]}" "${NAMES[2]}"
  fi
done <<<"$SERVERS_TO_DO"
