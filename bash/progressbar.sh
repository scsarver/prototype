#!/usr/bin/env bash
#
# Created By: $(whoami)
# Created Date: $(date +%Y%m%d-%H%M%S)
#
# Purpose and References: See usage function defined below - ref: https://en.wikipedia.org/wiki/Usage_message
#
# Where you want the options to take effect, use set -o option-name or, in short form, set -option-abbrev, To disable an option within a script, use set +o option-name or set +option-abbrev: https://www.tldp.org/LDP/abs/html/options.html
set +x #xtrace
set +v #verbose
set -e #errexit
set -u #nounset
SCRIPTDIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
SCRIPTNAME="$(basename "$0")"
LOG_TO_FILE="false"
LOGFILE="$SCRIPTNAME-$(date +%Y%m%d-%H%M%S).log"
function log {
  if [ "true" == "$LOG_TO_FILE" ]; then
    if [ "" == "$(which tee)" ]; then
      echo "$1" && echo "$1">>"$LOGFILE"
    else
      echo "$1" | tee -a "$LOGFILE"
    fi
  else
    echo "$1"
  fi
}
if [ "true" == "$LOG_TO_FILE" ]; then
  touch "$LOGFILE"
fi
function usage {
USAGE=$(cat <<HEREDOCUSAGE
  Usage: $SCRIPTNAME Path:$SCRIPTDIR

  Examples and ideas taken from here: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script

HEREDOCUSAGE
  )
echo "$USAGE"
}

# usage

echo -ne '#####                     (33%)\r'
sleep 1
echo -ne '#############             (66%)\r'
sleep 1
echo -ne '#######################   (100%)\r'
echo -ne '\n'

PROGRESSION=(
1
2
3
4
5
6
7
8
9
10
)

for PROGRESS_POINT in ${PROGRESSION[@]}
do
  PROGRESS_BAR=''
  for INCREMENT in $(seq 0 $PROGRESS_POINT)
  do
    PROGRESS_BAR+="*"
  done
  echo -ne "$PROGRESS_BAR\r"
  sleep 1
done
echo -e "$PROGRESS_BAR"



PROGRESS_COUNT=0
for PROGRESS_POINT in ${PROGRESSION[@]}
do
  PROGRESS_BAR_2=''
  for INCREMENT in $(seq 0 $PROGRESS_COUNT)
  do
    PROGRESS_BAR_2+=">"
  done
  echo -ne "$PROGRESS_BAR_2\r"
  sleep 1
  # PROGRESS_COUNT=$((PROGRESS_COUNT+1))
  ((PROGRESS_COUNT+=1))
done
echo -e "$PROGRESS_BAR_2"
