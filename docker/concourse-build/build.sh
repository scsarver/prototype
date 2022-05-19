#!/usr/bin/env bash
#
# Created By: sarvers
# Created Date: 20200817-112841
#
# Purpose and References: See usage function defined below - ref: https://en.wikipedia.org/wiki/Usage_message
# Where you want the options to take effect, use set -o option-name or, in short form, set -option-abbrev, To disable an option within a script, use set +o option-name or set +option-abbrev: https://www.tldp.org/LDP/abs/html/options.html
set +x #xtrace
set +v #verbose
# set -e #errexit
# set -o pipefail # https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
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

    This script is used to implement some basic scans using diferent products to see how usable they will be
    for inclusion in our build pipelines.

    Tested: https://hub.docker.com/r/docker/docker-bench-security - [This tool is a simple set of scriptes that can be paired down to only scan the docker image (This scans the docker context which means it need the image run as a container which could be a risk! )]
    Skipped: https://github.com/quay/clair/blob/master/Documentation/running-clair.md - [This product requires an external database, completely building api payloads or 3rd party clients, the setup and usage is painfull with terribnle documentation ]
    Skipped: https://github.com/cilium/cilium - [This toolls focus is the networking and connectivity which is not in scope for scanning images that will be used in fargate.]
    Tested: https://github.com/anchore/anchore-engine - [This tool gives a good scan report however it does require a series of containers and a database which means infrastructure that would need to be supported.]
    Tetsed: https://www.open-scap.org/resources/documentation/security-compliance-of-rhel7-docker-containers/
  Flags:
    -g|--getlogs Invokes the function to get the container logs
    -b|--build  invokes the build function which will build the dockerfile and list the docker images.
    -r|--run  invokes the run function which executes the docker run command.
    -sb|--scan-bench  invokes the docker-bench scan.
    -ia|--init-anchore  invokes the anchore infra code i.e. sets up the docker containers so they can synch the CVEs.
    -sa|--scan-anchore  invokes the anchore scan.
    -da|--destroy-anchore  destroys the anchore resources.
    -ic|--init-clair  invokes the anchore infra code i.e. sets up the docker containers so they can synch the CVEs.
    -sc|--scan-clair  invokes the anchore scan.
    -da|--destroy-clair  destroys the clair resources.
    -so|--scan-openscap  run the openscap docker scan.
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

IMAGE_TAG="concourse-base-job"
IMAGE_REPO="scsarver"
ANCHORE_TMP_DIR=".anchore"
CLAIR_TMP_DIR=".clair"

function build {
  docker build --tag "$IMAGE_REPO:$IMAGE_TAG" - < Dockerfile
  docker image ls
}

function run {
  # docker images
  # docker container ls --all
  IMAGE_ID="$(docker images | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 3)"
  log "Running docker image: [$IMAGE_ID] matching tag: [$IMAGE_TAG]"
  CONTAINER_ID="$(docker container ls --all | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 1)"

  if [ "" != "$CONTAINER_ID" ]; then
    log "Found docker container: [$CONTAINER_ID] matching name [$IMAGE_TAG] removing to reuse the name!"
    docker container rm $CONTAINER_ID
  fi

  docker run -it --name concourse-base-job "$IMAGE_ID"
  docker container ls --all | grep "$IMAGE_TAG"
  CONTAINER_ID="$(docker container ls --all | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 1)"
  docker container logs "$CONTAINER_ID"
}

function get_logs {
  log "************************************************************"
  log "Get Logs:"
  log "************************************************************"
  CONTAINER_ID="$(docker container ls --all | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 1)"
  log "Getting logs for container: $CONTAINER_ID"
  docker container logs "$CONTAINER_ID"
}


# ============================================================
# Docker-bench-security scan functions
# ============================================================
function scan_bench {
  log "************************************************************"
  log "Docker-bench-security:"
  log "************************************************************"
  IMAGE_ID="$(docker images | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 3)"
  log "  - Running docker image: [$IMAGE_ID] matching tag: [$IMAGE_TAG]"
  CONTAINER_ID="$(docker container ls --all | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 1 )"
  log " - $CONTAINER_ID"
  if [ "" == "$CONTAINER_ID" ]; then
    true;
  elif [ "0" == "$CONTAINER_ID" ]; then
    true;
  else
    log "  - Found docker container: [$CONTAINER_ID] matching name [$IMAGE_TAG], removing to reuse the name!"
    docker container kill "$CONTAINER_ID"
    docker container rm "$CONTAINER_ID"
  fi
  # NOTE: we are running this container in the background so it can be scanned!
  log " "
  log "WARNING: Running the container so it can be scanned is a risk!!!!!!"
  log "  - running $IMAGE_ID so it is in the docker context when the scan is run."
  docker run --name concourse-base-job "$IMAGE_ID" sh -c 'while sleep 3600; do :; done' &
  CONTAINER_ID="$(docker container ls --all | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 1)"
  log "  - Image: $IMAGE_ID is running as container with id: $CONTAINER_ID"
  log " "

  pushd .
  cd ../../../../docker/docker-bench-security

  # NOTE: After testing the docker container we determined the container will need privledges it will not have in concourse4!
    # docker run -it #--net host --pid host --userns host --cap-add audit_control \
    # docker run -it --net host --pid host --userns host --cap-add audit_control -e DOCKER_CONTENT_TRUST="false" --label docker_bench_security docker/docker-bench-security
    # docker run -it --net host --pid host --userns host --cap-add audit_control -e DOCKER_CONTENT_TRUST=false -v /etc:/etc -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro --label docker_bench_security docker/docker-bench-security -c container_images
    # docker run -it -e DOCKER_CONTENT_TRUST=false -v /etc:/etc -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro --label docker_bench_security docker/docker-bench-security -c container_images

  RESULTS="$(./docker-bench-security.sh -c container_images)"
  # RESULTS="$(./docker-bench-security.sh )"
  # echo "$RESULTS"
  echo "$RESULTS" | grep "WARN"
  log " "
  log "$RESULTS" | grep "Checks:"
  log "$RESULTS" | grep "Score:"
  popd

  log "  - Removing docker container: [$CONTAINER_ID]"
  if [ "" == "$CONTAINER_ID" ]; then
    true;
  elif [ "0" == "$CONTAINER_ID" ]; then
    true;
  else
    log "  - Found docker container: [$CONTAINER_ID] matching name [$IMAGE_TAG] removing to reuse the name!"
    docker container kill "$CONTAINER_ID"
    docker container rm "$CONTAINER_ID"
  fi
}


# ============================================================
# Anchore scan functions
# ============================================================
function init_anchore {
  # https://docs.anchore.com/current/docs/engine/quickstart/
  if [ ! -d "$ANCHORE_TMP_DIR" ]; then
    log "Creating the [$ANCHORE_TMP_DIR] temp diretory."
    mkdir "$ANCHORE_TMP_DIR"
  fi

  if [ ! -f "$ANCHORE_TMP_DIR/docker-compose.yaml" ]; then
    cd "$ANCHORE_TMP_DIR"
    log "Downloading the Anchore docker compose file."
    curl https://docs.anchore.com/current/docs/engine/quickstart/docker-compose.yaml > docker-compose.yaml
    log "Running the Anchore docker compose file."
    # The next step can take up to 10 minutes for the database to be synched up ( This solution really needs a persistent database to be effective!)
    docker-compose up -d
  fi

  log "Waiting for the Anchore system, feeds and system status to become ready..."
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli system wait
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli system status
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli system feeds list
  log "Completed, the Anchore system, feeds and system status are become ready!"
}

function destroy_anchore {
  log "Removing the Anchore resources created by the docker compose file."
  cd "$ANCHORE_TMP_DIR"
  docker-compose down
}

function scan_anchore {
  log "  - Anchore: Start scan"

  # REGISTRY_IMAGE="docker.io/scsarver/sentiment-analysis-frontend:latest"
  REGISTRY_IMAGE="docker.io/node:latest"
  log "  - Anchore: Scanning docker image: [$REGISTRY_IMAGE] - this image is required to be pulled form a regisrty!"
  log "       Unsure [it can ses link below!] if access to artifactory as an image repository would be a problem here!"
  log "                  https://docs.anchore.com/current/docs/engine/general/concepts/registries/"
  SCAN_IMAGE="$REGISTRY_IMAGE"

  # IMAGE_ID="$(docker images | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 3)"
  log "  - Anchore: Scanning docker image: [$SCAN_IMAGE]"
  # anchore-cli image add myrepo.example.com:5000/app/webapp:latest --dockerfile=/path/to/Dockerfile
  # SCAN_IMAGE="$IMAGE_ID"

  log "  - Anchore: add image"
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli image add "$SCAN_IMAGE"
  # docker-compose exec api anchore-cli image add "$SCAN_IMAGE" --dockerfile=Dockerfile  --noautosubscribe
  log "  - Anchore: wait for image add to complete..."
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli image wait "$SCAN_IMAGE"
  log "  - Anchore: image content"
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli image content "$SCAN_IMAGE"
  log "  - Anchore: check image vulnerabilities"
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli image vuln "$SCAN_IMAGE"
  log "  - Anchore: evaluate checks"
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli evaluate check "$SCAN_IMAGE"
  log " "
  log "  - Anchore: display vulnerabilities:"
  docker-compose -f "$ANCHORE_TMP_DIR/docker-compose.yaml" exec api anchore-cli image vuln "$SCAN_IMAGE" all
  log "  - Anchore: scan completed!"
}

# ============================================================
# Clair scan functions
# ============================================================

# None of this worked containers would spin up and exit imediately!!!
# function init_clair_OLD {
#   # mkdir $PWD/clair_config
#   # curl -L https://raw.githubusercontent.com/coreos/clair/master/config.yaml.sample -o $PWD/clair_config/config.yaml
#   # docker network create clairnet
#   # docker run -d --name clairdb --network clairnet postgres:9.6
#   # docker run --net=clairnet --name clair -d -p 6060-6061:6060-6061 -v $PWD/clair_config:/config quay.io/coreos/clair:latest -config=/config/config.yaml
#
#   # curl -L https://raw.githubusercontent.com/coreos/clair/master/docker-compose.yaml.sample -o $PWD/docker-compose.yaml
#   # mkdir $PWD/clair_config
#   # curl -L https://raw.githubusercontent.com/coreos/clair/master/config.yaml.sample -o $PWD/clair_config/config.yaml
#   # docker-compose -f docker-compose.yaml up -d
#
#   if [ ! -d "$CLAIR_TMP_DIR" ]; then
#     log "Creating the [$CLAIR_TMP_DIR] temp diretory."
#     mkdir "$CLAIR_TMP_DIR"
#   fi
#
#   CLAIR_NETWORK_NAME="clairnet"
#   CLAIR_DB_NAME="clairdb"
#   CLAIR_APP_NAME="clairapp"
#   CLAIR_NETWORK_ID="$(docker network ls --filter name=$CLAIR_NETWORK_NAME -q)"
#
#   if [ ! -f "$CLAIR_TMP_DIR/config.yaml" ]; then
#     cd "$CLAIR_TMP_DIR"
#     log "Downloading the Clair config file."
#     curl -L https://raw.githubusercontent.com/coreos/clair/master/config.yaml.sample -o "config.yaml"
#   fi
#
#   if [ "" == "$CLAIR_NETWORK_ID" ]; then
#     docker network create "$CLAIR_NETWORK_NAME"
#   fi
#
#   CONTAINER_ID="$(docker container ls --all | grep "$CLAIR_DB_NAME" | tr -s ' ' | cut -d ' ' -f 1 )"
#   log " - $CONTAINER_ID"
#   if [ "" == "$CONTAINER_ID" ]; then
#     true;
#   elif [ "0" == "$CONTAINER_ID" ]; then
#     true;
#   else
#     log "  - Found docker container: [$CONTAINER_ID] matching name [$CLAIR_DB_NAME], removing to reuse the name!"
#     docker container kill "$CONTAINER_ID"
#     docker container rm "$CONTAINER_ID"
#   fi
#   docker run -d --name "$CLAIR_DB_NAME" --network "$CLAIR_NETWORK_NAME" postgres:9.6
#
#   CONTAINER_ID="$(docker container ls --all | grep "$CLAIR_APP_NAME" | tr -s ' ' | cut -d ' ' -f 1 )"
#   log " - $CONTAINER_ID"
#   if [ "" == "$CONTAINER_ID" ]; then
#     true;
#   elif [ "0" == "$CONTAINER_ID" ]; then
#     true;
#   else
#     log "  - Found docker container: [$CONTAINER_ID] matching name [$CLAIR_APP_NAME], removing to reuse the name!"
#     docker container kill "$CONTAINER_ID"
#     docker container rm "$CONTAINER_ID"
#   fi
#   docker run --network "$CLAIR_NETWORK_NAME" --name "$CLAIR_APP_NAME" -d -p 6060-6061:6060-6061 -v "$PWD/$CLAIR_TMP_DIR":/config quay.io/coreos/clair:latest -config=/config/config.yaml
# }


function init_clair {
  if [ ! -d "$CLAIR_TMP_DIR" ]; then
    log "Creating the [$CLAIR_TMP_DIR] temp diretory."
    mkdir "$CLAIR_TMP_DIR"
  fi
  if [ ! -f "$CLAIR_TMP_DIR/docker-compose.yaml" ]; then
    log "Downloading the Clair docker-compose file."
    curl -L https://raw.githubusercontent.com/coreos/clair/master/docker-compose.yaml.sample -o "$CLAIR_TMP_DIR/docker-compose.yaml"
    log "Updating the Clair docker-compose file to use the [$CLAIR_TMP_DIR] as the config directory."
    sed -i '' 's/clair_config/\.clair/g' "$CLAIR_TMP_DIR/docker-compose.yaml"
  fi
  if [ ! -f "$CLAIR_TMP_DIR/config.yaml" ]; then
    log "Downloading the Clair config file."
    curl -L https://raw.githubusercontent.com/coreos/clair/master/config.yaml.sample -o "$CLAIR_TMP_DIR/config.yaml"
  fi
  docker-compose -f "$CLAIR_TMP_DIR/docker-compose.yaml" up -d
}

function destroy_clair {
  log "Removing the Clair resources created by the docker compose file."
  cd "$CLAIR_TMP_DIR"
  docker-compose down
}

function scan_clair {
  echo "The details of HOW to actually make a call to scan an image for this tool is very shady at best!"
  echo "  - [https://www.nearform.com/blog/static-analysis-of-docker-image-vulnerabilities-with-clair/]"
  echo "  - [api reference: https://coreos.com/clair/docs/latest/api_v1.html]"
  echo "Based on the article found above there is no reason to try to build the base api data payloads as it is messy."
  echo "This leads us to trying a 3rd party client which further complicates trying to use this product!!"
  echo "The clairctl client requires go and glide to be installed further complicating this setup!!"
  echo "   - https://github.com/jgsqware/clairctl"
  echo "************************************************************"
  echo " NO further investigation into this tool at this time due to the reasons stated above!"
  echo "************************************************************"
}


function scan_openscap {
  log "  - Anchore: Start scan"
  # REGISTRY_IMAGE="docker.io/scsarver/sentiment-analysis-frontend:latest"
  REGISTRY_IMAGE="docker.io/node:latest"
  log "  - Anchore: Scanning docker image: [$REGISTRY_IMAGE] - this image is required to be pulled form a regisrty!"
  log "       Unsure [it can ses link below!] if access to artifactory as an image repository would be a problem here!"
  log "                  https://docs.anchore.com/current/docs/engine/general/concepts/registries/"
  SCAN_IMAGE="$REGISTRY_IMAGE"

  # IMAGE_ID="$(docker images | grep "$IMAGE_TAG" | tr -s ' ' | cut -d ' ' -f 3)"
  log "  - Anchore: Scanning docker image: [$IMAGE_ID] matching tag: [$IMAGE_TAG]"
  # anchore-cli image add myrepo.example.com:5000/app/webapp:latest --dockerfile=/path/to/Dockerfile
  # SCAN_IMAGE="$IMAGE_ID"

  # docker run --name openscap openscap/openscap  sh -c "oscap-docker <image/container>[-cve] <image/container identifier> <oscap parameters>" &
  # docker run --name openscap openscap/openscap  sh -c "yum install openscap-utils; oscap-docker --help"

  docker run -it --name openscap docker.io/centos
  # yum install -y openscap openscap-utils scap-security-guide atomic
  # ls -la /usr/share/xml/scap/ssg/content
  docker rm openscap
}

# ==============================================================================
#
# Case statement to parse parameters and run functions accordingly
#
# ==============================================================================
while (( "$#" )); do #Referenced: https://medium.com/@Drew_Stokes/bash-argument-parsing-54f3b81a6a8f
case "$1" in
    -g|--getlogs)get_logs;exit;;
    -b|--build)build;exit;;
    -r|--run)run;exit;;
    -sb|--scan-bench)scan_bench;exit;;
    -ia|--init-anchore)init_anchore;exit;;
    -sa|--scan-anchore)scan_anchore;exit;;
    -da|--destroy-anchore)destroy_anchore;exit;;
    -ic|--init-clair)init_clair;exit;;
    -sc|--scan-clair)scan_clair;exit;;
    -dc|--destroy-clair)destroy_clair;exit;;
    -so|--scan-openscap)scan_openscap;exit;;
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
