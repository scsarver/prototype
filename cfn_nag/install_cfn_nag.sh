#!/usr/bin/env bash
#
# Created By: sarvers
# Created Date: 20200818-131701
#
# Purpose and References: See usage function defined below - ref: https://en.wikipedia.org/wiki/Usage_message
# Where you want the options to take effect, use set -o option-name or, in short form, set -option-abbrev, To disable an option within a script, use set +o option-name or set +option-abbrev: https://www.tldp.org/LDP/abs/html/options.html
set +x #xtrace
set +v #verbose
set -e #errexit
set -o pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
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
    Update me!
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

DESIRED_RUBY_VERSION="2.7.1"

echo "========================================================================="
echo ""
echo "Starting cfn_nag install: https://github.com/stelligent/cfn_nag"
echo ""

# echo "Search in brew for rbenv dependencies: [ rbenv ruby-build ]"
# brew search rbenv
# brew search ruby-build
# echo ""
#
# echo "brew upgrade: [ rbenv ruby-build ] "
# brew upgrade rbenv ruby-build
# echo ""
#
#
# echo "cfn_nag isbased on ruby so we need to make sure our rbenv is setup correctly by running the doctor..."
# curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
# echo ""


# echo "Show rbenv versions available:"
# rbenv versions
# echo ""
#
# echo "Show installed version: "
# rbenv install --list-all
# echo ""
#
# echo "Show which rbenvc executable: "
# rbenv which irb
# echo ""
#
#
# echo "rbenv install: $DESIRED_RUBY_VERSION"
# # rbenv install $DESIRED_RUBY_VERSION
# echo ""


# echo "rbenv set local to: $DESIRED_RUBY_VERSION"
# rbenv local
# # rbenv local $DESIRED_RUBY_VERSION
# echo ""

echo "rbenv init shell"
rbenv init
echo ""

echo "rbenv set shell to: $DESIRED_RUBY_VERSION"
# rbenv shell
rbenv shell $DESIRED_RUBY_VERSION
# export RBENV_VERSION=$DESIRED_RUBY_VERSION
echo ""

# ruby --version
# gem --version
gem update --system

exit

# brew search cfn_nag
# brew search ruby
brew search brew-gem
brew gem search cfn-nag

# https://github.com/stelligent/cfn_nag
# brew install ruby brew-gem
# brew gem install cfn-nag
