#!/usr/bin/env bash
#
# Created By: sarvers
# Created Date: 20200702-165134
#
# Purpose and References: See usage function defined below - ref: https://en.wikipedia.org/wiki/Usage_message
# Where you want the options to take effect, use set -o option-name or, in short form, set -option-abbrev, To disable an option within a script, use set +o option-name or set +option-abbrev: https://www.tldp.org/LDP/abs/html/options.html
set +x #xtrace
set +v #verbose
set -e #errexit
# set -u #nounset - This is off by default until the parameter parsing while block usage of $1 forcing an error can be figured out.
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
    This script is used to test some of the features available in the cfn guard project found here: https://aws.amazon.com/about-aws/whats-new/2020/06/introducing-aws-cloudformation-guard-preview/

    https://github.com/aws-cloudformation/cloudformation-guard
    Note the dependencies on RUST are included in this script.
  Flags:
    -v|--verbose [true|false - default false]- Used to increase the verbosity of output.
    -q|--quiet   [true|false - default false]- Used to turn off logging and output.
    -l|--log [true|false - default false]- Used to turn on logging output to a file with the naming pattern [${SCRIPTNAME%.*}-%Y%m%d-%H%M%S.log]
    -u|--usage - Used to display this usage documentation and exit.
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
if [ "true" == "$LOG_TO_FILE" ]; then
  touch "$LOGFILE" #This happens after flags are parsed
fi

PROJECT_NAME="cloudformation-guard"
GIT_ORG_NAME="aws-cloudformation"
REPOS_DIRECTORY="/Users/$(whoami)/Documents/repos"

if [ ! -d "$REPOS_DIRECTORY/$GIT_ORG_NAME" ]; then
  pushd .
  mkdir -p "$REPOS_DIRECTORY/$GIT_ORG_NAME"
  cd "$REPOS_DIRECTORY/$GIT_ORG_NAME"
  # git clone "git@github.com:$GIT_ORG_NAME/$PROJECT_NAME.git"
  git clone https://github.com/aws-cloudformation/cloudformation-guard.git
  popd
fi

echo "Show cloned repo: $REPOS_DIRECTORY/$GIT_ORG_NAME"
ls -la "$REPOS_DIRECTORY/$GIT_ORG_NAME"

RUST_CHECK="$(rustc --version  2>&1 || true)"
if [[ "$RUST_CHECK" == *"command not found"* ]]; then
  echo "Rust is not found installing!"
  echo "be sure to follow the prompts:"
  # https://www.rust-lang.org/tools/install
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  echo " "
  echo "Sourcing $HOME/.cargo/env"
  source $HOME/.cargo/env
  rustc --version
else
  rustc --version
fi

echo "------------------------------------------------------------"
echo "Starting cfn-guard ..."
echo " "
# cfn-guard -t Examples/ebs_volume_template.json -r Examples/ebs_volume_template.ruleset
TEMPLATES_DIR='/Users/sarvers/Documents/repos/vwcredit/transformers-tenant-infra/templates'
RULES_FILE='/Users/sarvers/Documents/repos/aws-cloudformation/cloudformation-guard/Examples/aws-waf-security-automations.ruleset'

for FILE in $(ls $TEMPLATES_DIR)
do
  echo "Checking file: $FILE"
  echo " "
  # cfn-guard -t "$FILE" -r "$RULES_FILERULES_FILE"
  pushd .
  cd "$REPOS_DIRECTORY/$GIT_ORG_NAME/$PROJECT_NAME/cfn-guard"

  #https://github.com/aws-cloudformation/cloudformation-guard/blob/master/cfn-guard/README.md
  # cargo run -- -t <CloudFormation Template> -r <Rules File>
  cargo run -- -t "$TEMPLATES_DIR/$FILE" -r "$RULES_FILE"
  popd
  echo " "
done
