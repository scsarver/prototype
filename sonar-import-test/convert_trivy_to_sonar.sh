#!/usr/bin/env bash
#
# Created By: sarvers
# Created Date: 20200827-164320
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
readonly SCRIPTDIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
readonly SCRIPTNAME="$(basename "$0")"
readonly LOGFILE="${SCRIPTNAME%.*}-$(date +%Y%m%d-%H%M%S).log"
function missing_arg { echo "Error: Argument for $1 is missing" >&2; exit 1; }
function unsupported_flag { echo "Error: Unsupported flag $1" >&2; exit 1; }
function usage {
cat <<HEREDOCUSAGE
  Usage: $SCRIPTNAME Path:$SCRIPTDIR
  Purpose:

    POC converting trivy docker scan output into sonarqube generic readable input.
    see:
      - https://docs.sonarqube.org/latest/analysis/generic-issue/
      - https://docs.sonarqube.org/latest/analysis/generic-test/

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



SONR_TEMPLATE=$(cat <<HEREDOCSONARFORMAT
{ "issues": [
    {
      "engineId": "trivy",
      "ruleId": "$CVE_ID",
      "severity":"BLOCKER",
      "type":"CODE_SMELL",
      "primaryLocation": {
        "message": "fully-fleshed issue",
        "filePath": "sources/A.java",
        "textRange": {
          "startLine": 30,
          "endLine": 30,
          "startColumn": 9,
          "endColumn": 14
        }
      },
      "effortMinutes": 90,
      "secondaryLocations": [
        {
          "message": "cross-file 2ndary location",
          "filePath": "sources/B.java",
          "textRange": {
            "startLine": 10,
            "endLine": 10,
            "startColumn": 6,
            "endColumn": 38
          }
        }
      ]
    },
    {
      "engineId": "test",
      "ruleId": "rule2",
      "severity": "INFO",
      "type": "BUG",
      "primaryLocation": {
        "message": "minimal issue raised at file level",
        "filePath": "sources/Measure.java"
      }
    }
]}
HEREDOCSONARFORMAT


# Parse the node.json file and for each vulnerability found translate the properties to the sonrqube generic format to upload.
jq -r '.' node.json



# .engineId == trivy
#.ruleId == .VulnerabilityID
#.severity == .Severity
#.type == "VULNERABILITY" #BUG, VULNERABILITY, CODE_SMELL
#primaryLocation.message == .Description
#primaryLocation.filePath == .PkgName


SONRFORMAT=$(cat <<HEREDOCSONARFORMAT
{ "issues": [
    {
      "engineId": "test",
      "ruleId": "rule1",
      "severity":"BLOCKER",
      "type":"CODE_SMELL",
      "primaryLocation": {
        "message": "fully-fleshed issue",
        "filePath": "sources/A.java",
        "textRange": {
          "startLine": 30,
          "endLine": 30,
          "startColumn": 9,
          "endColumn": 14
        }
      },
      "effortMinutes": 90,
      "secondaryLocations": [
        {
          "message": "cross-file 2ndary location",
          "filePath": "sources/B.java",
          "textRange": {
            "startLine": 10,
            "endLine": 10,
            "startColumn": 6,
            "endColumn": 38
          }
        }
      ]
    },
    {
      "engineId": "test",
      "ruleId": "rule2",
      "severity": "INFO",
      "type": "BUG",
      "primaryLocation": {
        "message": "minimal issue raised at file level",
        "filePath": "sources/Measure.java"
      }
    }
]}
HEREDOCSONARFORMAT
)


TRIVYFORMAT=$(cat <<HEREDOCTRIVYFORMAT
{
  "VulnerabilityID": "CVE-2011-3374",
  "PkgName": "apt",
  "InstalledVersion": "1.4.10",
  "Layer": {
    "DiffID": "sha256:4e38024e7e09292105545a625272c47b49dbd1db721040f2e85662e0a41ad587"
  },
  "SeveritySource": "debian",
  "Description": "It was found that apt-key in apt, all versions, do not correctly validate gpg keys with the master keyring, leading to a potential man-in-the-middle attack.",
  "Severity": "LOW",
  "CweIDs": [
    "CWE-347"
  ],
  "VendorVectors": {
    "nvd": {
      "v2": "AV:N/AC:M/Au:N/C:N/I:P/A:N",
      "v3": "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:L/A:N"
    }
  },
  "CVSS": {
    "nvd": {
      "V2Vector": "AV:N/AC:M/Au:N/C:N/I:P/A:N",
      "V3Vector": "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:U/C:N/I:L/A:N",
      "V2Score": 4.3,
      "V3Score": 3.7
    }
  },
  "References": [
    "https://access.redhat.com/security/cve/cve-2011-3374",
    "https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=642480",
    "https://people.canonical.com/~ubuntu-security/cve/2011/CVE-2011-3374.html",
    "https://security-tracker.debian.org/tracker/CVE-2011-3374",
    "https://snyk.io/vuln/SNYK-LINUX-APT-116518"
  ]
}
HEREDOCTRIVYFORMAT
)
