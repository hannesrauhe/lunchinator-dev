#!/bin/bash

export DEBFULLNAME="Lunch Team"
export DEBEMAIL=info@lunchinator.de
export OBSUSERNAME=Cornelius_Ratsch

function log() {
  echo "$@" | tee -a buildserver.log
}

function finish() {
  log "---------- Finished build at $(date) ----------"
  exit $1
}

pushd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null
DIR="$(pwd)"

log "---------- Starting build at $(date) ----------"

args=$(getopt -l "no-publish,no-nightlies,build:,no-cleanup" -o "b:" -- "$@")

if [ ! $? == 0 ]
then
  exit 1
fi

eval set -- "$args"

NIGHTLIES=true
PUBLISH=true
CLEANUP=true

while [ $# -ge 1 ]; do
  case "$1" in
    --)
        # No more options left.
        shift
        break
       ;;
    -b|--build)
        BUILD_SCRIPT="$2"
        shift
        ;;
    --no-publish)
        PUBLISH=false
        ;;
    --no-nightlies)
        NIGHTLIES=false
        ;;
    --no-cleanup)
        CLEANUP=false
        ;;
    -h)
        echo "--no-publish to disable publishing, --no-nightlies to disable nightly builds."
        exit 0
        ;;
  esac

  shift
done

if [ "$BUILD_SCRIPT" == "" ]
then
  log "No build script provided. Use --build to specify one." 1>&2
  finish 1
fi

if [ ! -d "lunchinator" ]
then
  git clone https://github.com/hannesrauhe/lunchinator.git
fi

# for use in make_*.sh
export CHANGELOG_PY="$(pwd)/changelog.py"
export LUNCHINATOR_GIT="$(pwd)/lunchinator"
export LUNCHINATOR_DEV="$DIR"
export PYTHONPATH=$LUNCHINATOR_GIT:$PYTHONPATH

if $NIGHTLIES
then
  branches=(master nightly)
else
  branches=(master)
fi

for branch in "${branches[@]}"
do
  export LUNCHINATOR_BRANCH="$branch"
  pushd "$LUNCHINATOR_GIT" &>/dev/null
  LAST_HASH=$(git rev-parse $(git describe --tags)^1)
  popd &>/dev/null

  if [ -e last_hash_${BUILD_SCRIPT}_${branch} ]
  then
    LAST_HASH=$(cat last_hash_${BUILD_SCRIPT}_${branch})
  fi
  
  pushd "$LUNCHINATOR_GIT" &>/dev/null
  git checkout $branch
  git pull

  THIS_HASH="$(git rev-parse HEAD)"
  popd &>/dev/null

  if [ $LAST_HASH == $THIS_HASH ]
  then
    log "No new version in git for $branch"
  else
    export LAST_HASH

    #echo $VERSION
    if $PUBLISH
    then
      eval "./$BUILD_SCRIPT --publish" 2>&1 | tee -a buildserver.log
    else
      eval "./$BUILD_SCRIPT" 2>&1 | tee -a buildserver.log
    fi
    if [ ${PIPESTATUS[0]} -eq 0 ]
    then
      log "Successfully built version $VERSION"
      if $PUBLISH
      then
        echo $THIS_HASH > last_hash_${BUILD_SCRIPT}_${branch}
      fi
    fi
    if $CLEANUP
    then
      log "Cleaning up"
      eval "./$BUILD_SCRIPT --clean" 2>&1 | tee -a buildserver.log
    fi

  fi

  sleep 2
done

finish
popd &>/dev/null
