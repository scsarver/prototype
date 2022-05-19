#!/usr/bin/env bash
SHELL_STARTUP_ABS_PATH="$_"

#
# Created By: sarvers
# Created Date: 20200701-132701
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
USAGE=$(cat <<HEREDOCUSAGE
  Usage: $SCRIPTNAME Path:$SCRIPTDIR
  Purpose:
    Update me!
  Flags:
    -v|--verbose [true|false - default false]- Used to increase the verbosity of output.
    -q|--quiet   [true|false - default false]- Used to turn off logging and output.
    -l|--log [true|false - default false]- Used to turn on logging output to a file with the naming pattern [${SCRIPTNAME%.*}-%Y%m%d-%H%M%S.log]
    -u|--usage - Used to display this usage documentation and exit.
HEREDOCUSAGE
  )
echo "$USAGE"
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



# echo "$(ls .)"
# echo "{ ls .;}"
# echo " "
# echo "$- [Expands  to  the  current  option  flags  as  specified upon invocation, by the set builtin command, or those set by the shell itself (such as the -i option).]"
# echo " "
# echo "$$ [Expands to the process ID of the shell.  In  a  ()  subshell,  it  expands  to  the process ID of the current shell, not the subshell.]"
# echo " "
# echo "SHELL_STARTUP_ABS_PATH: $SHELL_STARTUP_ABS_PATH"
# echo "$FUNCNAME"

# Heredocs: https://en.wikipedia.org/wiki/Here_document
echo " "
echo "[HEREDOC - standard] -  variable names are replaced by their values, commands within backticks are evaluated"
cat << EOF
\$ Working dir "$PWD" `pwd`
EOF

echo " "
echo "[HEREDOC - standard but quoted] - no variable expansion"
cat << 'EOF'
\$ Working dir "$PWD" `pwd`
EOF

echo " "
echo "[HEREDOC - ignore leadign tabs] - Appending a minus sign to the << (i.e. <<-) has the effect that leading tabs are ignored. Useful for indenting here documents in shell scripts."

LANG=C tr a-z A-Z <<-END_TEXT
Here doc with <<-
 A single space character (i.e. 0x20 )  is at the beginnning of this line
	This line begins with a single TAB character i.e 0x09  as does the next line
	END_TEXT
echo '------------------------'








exit
