#!/usr/bin/env bash
#
# Created By: sarvers
# Created Date: 20211108-155832
#
# Purpose and References: See usage function defined below - ref: https://en.wikipedia.org/wiki/Usage_message
# Where you want the options to take effect, use set -o option-name or, in short form, set -option-abbrev, To disable an option within a script, use set +o option-name or set +option-abbrev: https://www.tldp.org/LDP/abs/html/options.html
set +x #xtrace
set +v #verbose
set -e #errexit
set -o pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
# set -u #nounset - This is off by default until the parameter parsing while block usage of $1 forcing an error can be figured out.
SHELLCHECK="false"
QUIET="false"
VERBOSE="false"
LOG_TO_FILE="false"
readonly SCRIPTDIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
readonly SCRIPTNAME="$(basename "$0")"
readonly LOGFILE="${SCRIPTNAME%.*}-$(date +%Y%m%d-%H%M%S).log"
function missing_arg { echo "Error: Argument for $1 is missing" >&2; exit 1; }
function unsupported_flag { echo "Error: Unsupported flag $1" >&2; exit 1; }
function usage {
cat <<HEREDOCUSAGE
  Usage: $SCRIPTNAME Path: $SCRIPTDIR
  Purpose:
    Update me!
  Flags:
    -v|--verbose [true|false - default false]- Used to increase the verbosity of output.
    -q|--quiet   [true|false - default false]- Used to turn off logging and output.
    -l|--log [true|false - default false]- Used to turn on logging output to a file with the naming pattern [${SCRIPTNAME%.*}-%Y%m%d-%H%M%S.log]
    -u|--usage - Used to display this usage documentation and exit.
    -z|--shellcheck [true|false] - default false - Used to run shellcheck against this script.
HEREDOCUSAGE
}
# Consider enhancing with color logging some examples found here: https://github.com/docker/docker-bench-security/blob/master/output_lib.sh
function log {
  if [ "true" != "$QUIET" ]; then
    if [ "true" == "$LOG_TO_FILE" ]; then
      if [ "" == "$(which tee)" ]; then
        echo "$1" && echo "$1">>"$LOGFILE"
      else
        echo "$1" | tee -a "$LOGFILE"
      fi
    else
      echo "$1"
    fi
  fi
}
function vlog {
  if [ "true" == "$VERBOSE" ]; then
    log "$1"
  fi
}
readonly REQUIRED_SOFTWARE='shellcheck tput aws jq yq'
for REQUIRED in $REQUIRED_SOFTWARE; do
  command -v "$REQUIRED" >/dev/null 2>&1 || { printf "%s command not found and is required to be installed to use the script [$SCRIPTNAME].\n" "$REQUIRED"; exit 1; }
done
BOLD_TEXT=$(tput bold)
NORMAL_TEXT=$(tput sgr0)
while (( "$#" )); do #Referenced: https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f
case "$1" in
    -z|--shellcheck)export SHELLCHECK="true";shift;;
    -q|--quiet)export QUIET="true";shift;;
    -v|--verbose)
      export VERBOSE="true";shift;;
    -l|--log)
      export LOG_TO_FILE="true";touch "$LOGFILE";shift;;
    -h|-u|--help|--usage )
      usage;exit;;
    # -ab|--boolean-flag)
    #   MY_FLAG=0;shift;;
    # -b|--flag-with-argument)
    #   if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
    #     MY_FLAG_ARG=$2;shift 2;
    #   else
    #     missing_arg "$1"
    #   fi
    #   ;;
    -*|--*=) # Error on unsupported flags
      unsupported_flag "$1";;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1";shift;;
  esac
done

if [ "true" == "$SHELLCHECK" ]; then
  echo "shellcheck $SCRIPTNAME - Supressing 2 rules: SC2221 & SC2222 - the line it complains about is written to intentionally catch unsupported flags passed to this script."
  shellcheck -e SC2221 -e SC2222 "$SCRIPTNAME"
  exit
fi



jq -r "." test.json

echo "---------------------------------------"
jq -r ".TemplateBody" test.json | jq -r "."
