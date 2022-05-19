#!/usr/bin/env bash
#
# Created By: sarvers
# Created Date: 20200701-170635
#
# Purpose and References: See usage function defined below - ref: https://en.wikipedia.org/wiki/Usage_message
# Where you want the options to take effect, use set -o option-name or, in short form, set -option-abbrev, To disable an option within a script, use set +o option-name or set +option-abbrev: https://www.tldp.org/LDP/abs/html/options.html
set +x #xtrace
set +v #verbose
set -e #errexit
# set -u #nounset - This is off by default until the parameter parsing while block usage of $1 forcing an error can be figured out.
CONCOURSE_TEAM="vw-cred-sandbox"
CONCOURSE_URL="https://ci.platform.vwfs.io"
QUIET="false"
VERBOSE="false"
LOG_TO_FILE="false"
SCRIPTDIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
SCRIPTNAME="$(basename "$0")"
LOGFILE="${SCRIPTNAME%.*}-$(date +%Y%m%d-%H%M%S).log"
function missing_arg { echo "Error: Argument for $1 is missing" >&2; exit 1; }
function unsupported_flag { echo "Error: Unsupported flag $1" >&2; exit 1; }
function usage {
cat <<HEREDOCUSAGE
  Usage: $SCRIPTNAME Path:$SCRIPTDIR
  Purpose:
    Update me!
  Flags:
    -v|--verbose [true|false - default false]- Used to increase the verbosity of output.
    -q|--quiet   [true|false - default false]- Used to turn off logging and output.
    -l|--log [true|false - default false]- Used to turn on logging output to a file with the naming pattern [${SCRIPTNAME%.*}-%Y%m%d-%H%M%S.log]
    -u|--usage - Used to display this usage documentation and exit.
    -t|--team - The team name in Concourse team name when executing fly (Very often the tenants name is used as the team name).
HEREDOCUSAGE
}
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
if [ "true" == "$LOG_TO_FILE" ]; then
  touch "$LOGFILE" #This happens after flags are parsed
fi
while (( "$#" )); do #Referenced: https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f
case "$1" in
    -q|--quiet)export QUIET="true";shift;;
    -v|--verbose)
      export VERBOSE="true";shift;;
    -l|--log)
      export LOG_TO_FILE="true";shift;;
    -h|-u|--help|--usage )
      usage;exit;;
    # -ab|--boolean-flag)
    #   MY_FLAG=0;shift;;
    -t|--team)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CONCOURSE_TEAM=$2;shift 2;
      else
        missing_arg "$1"
      fi
      ;;
    -*|--*=) # Error on unsupported flags
      unsupported_flag "$1";;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1";shift;;
  esac
done
if [ "true" == "$LOG_TO_FILE" ]; then
  touch "$LOGFILE" #This happens after flags are parsed
fi

VWCREDIT_REPOS="/Users/sarvers/Documents/repos/vwcredit"
BASE_PIPELINE="transformers-tenant-infra/ci/pipeline.yaml"
COMPARE_FILE_DESTINATION="${SCRIPTNAME%.*}"
PIPELINE_NAME="transformers-tenant-infra"
ERROR_FILE_NAME="$(date +%Y.%m.%d-%H:%M:%S)-INVALID-YAML-$CONCOURSE_TEAM-pipeline.yaml"

vlog "============================================================"
log "  $CONCOURSE_TEAM $PIPELINE_NAME compare pipeline to master at the HEAD."
vlog "  source dir: $VWCREDIT_REPOS"
vlog "  source file: $BASE_PIPELINE"
vlog "  tmp dir: $COMPARE_FILE_DESTINATION"
vlog "============================================================"
vlog " "

log " ****************************************"
log " ****************************************"
log "   format the source pipeline file using fly before doing the compare to what is pulled from Concourse!!!!"
log "     - thjis expands all the anchors!"
log " ****************************************"
log " ****************************************"




if [ ! -d "$COMPARE_FILE_DESTINATION" ]; then
  log "  Creating directory: $COMPARE_FILE_DESTINATION"
  mkdir "$COMPARE_FILE_DESTINATION"
fi

vlog "  Check for team login: "
GET_TEAM="$(fly -t "$CONCOURSE_TEAM" get-team --team-name=$CONCOURSE_TEAM 2>&1 || true)"
if [[ $GET_TEAM"" == *"not authorized. run the following to log in"* ]]; then
  vlog "  Login to Concourse required, using team: $CONCOURSE_TEAM and url: $CONCOURSE_URL"
  fly -t "$CONCOURSE_TEAM" login --concourse-url="$CONCOURSE_URL" --team-name="$CONCOURSE_TEAM"
elif [[ $GET_TEAM"" == *"error: unknown target"* ]]; then
  vlog "  Error getting team: $CONCOURSE_TEAM details."
  log "  $GET_TEAM"
  fly -t "$CONCOURSE_TEAM" login --concourse-url="$CONCOURSE_URL" --team-name="$CONCOURSE_TEAM"
  vlog " "
  exit 1
else
  echo "    [$GET_TEAM]"
fi

VALID_MASTER_YAML="$(echo $VWCREDIT_REPOS/$BASE_PIPELINE | yq validate - 2>&1 || true)"
if [ "" == "$VALID_MASTER_YAML" ]; then
  vlog "  Master pipeline passed validation with yq."
else
  vlog "  Master pipeline did not pass validation with yq we will use a file diff when comparing."
fi

vlog "  Get deployed pipeline source: "
PIPELINE_SOURCE="$(fly -t $CONCOURSE_TEAM get-pipeline --pipeline=$PIPELINE_NAME)"


# fly -t "$CONCOURSE_TEAM" set-pipeline --pipeline="$PIPELINE_NAME"


vlog "  Validate retrieved yaml with yq:"
VALID_YAML="$(echo "$PIPELINE_SOURCE" | yq validate - 2>&1 || true)"

if [ "" == "$VALID_YAML" ]; then
  SAVED_FILE_NAME="$CONCOURSE_TEAM-pipeline.yaml"
  vlog "  yaml is valid so writing file: $COMPARE_FILE_DESTINATION/$SAVED_FILE_NAME"
  echo "$PIPELINE_SOURCE">"$COMPARE_FILE_DESTINATION/$SAVED_FILE_NAME"
else
  log "  Error: saved output to: $COMPARE_FILE_DESTINATION/$ERROR_FILE_NAME"
  echo "$PIPELINE_SOURCE">"$COMPARE_FILE_DESTINATION/$ERROR_FILE_NAME"
  vlog "$VALID_YAML"
  vlog " "
fi

COMPARE_OUTPUT=''
if [ "" == "$VALID_YAML" ] && [ "" == "$VALID_MASTER_YAML" ]; then
  # vlog "  Both master and source are valid yaml. Using yq to compare."
  # COMPARE_OUTPUT="$(yq compare --prettyPrint "$VWCREDIT_REPOS/$BASE_PIPELINE" "$COMPARE_FILE_DESTINATION/$SAVED_FILE_NAME" 2>&1 || true)"
  # vlog "$COMPARE_OUTPUT"

  vlog "  Both master and source are valid yaml."
  COMPARE_OUTPUT="$(diff "$VWCREDIT_REPOS/$BASE_PIPELINE" "$COMPARE_FILE_DESTINATION/$SAVED_FILE_NAME" 2>&1 || true)"
  log "  $(echo "$COMPARE_OUTPUT" | diffstat)"
  log "meld $VWCREDIT_REPOS/$BASE_PIPELINE $COMPARE_FILE_DESTINATION/$SAVED_FILE_NAME"
else
  if [ "" == "$VALID_YAML" ]; then
    vlog "  Using standard file compare due to master pipeline failing yaml validation."
    COMPARE_OUTPUT="$(diff "$VWCREDIT_REPOS/$BASE_PIPELINE" "$COMPARE_FILE_DESTINATION/$SAVED_FILE_NAME")"
    log "  $(echo "$COMPARE_OUTPUT" | diffstat)"
    log "meld $VWCREDIT_REPOS/$BASE_PIPELINE $COMPARE_FILE_DESTINATION/$SAVED_FILE_NAME"
  else
    vlog "  Using standard file compare due to master pipeline and source pipeline failing yaml validations."
    COMPARE_OUTPUT="$(diff "$VWCREDIT_REPOS/$BASE_PIPELINE" "$COMPARE_FILE_DESTINATION/$ERROR_FILE_NAME")"
    log "  $(echo "$COMPARE_OUTPUT" | diffstat)"
    log "meld $VWCREDIT_REPOS/$BASE_PIPELINE $COMPARE_FILE_DESTINATION/$ERROR_FILE_NAME"
  fi
fi
