#!/bin/bash
. /etc/profile
export DEBFULLNAME="The Lunch Team"
export DEBEMAIL=info@lunchinator.de

if [ $(uname) == "Darwin" ]
then
  # ensure environment is fine (MacPorts and stuff)
  source ~/.profile
  source ~/.bash_profile
fi

function log() {
  echo "$@" | tee -a buildserver.log
}

function finish() {
  log "---------- Finished build at $(date) ----------"
  exit $1
}

DIR="$(dirname "${BASH_SOURCE[0]}")"
pushd $DIR

log "---------- Starting build at $(date) ----------"

args=$(getopt -l "no-publish,no-nightlies,build:" -o "b:" -- "$@")

if [ ! $? == 0 ]
then
  exit 1
fi

eval set -- "$args"

NIGHTLIES=true
PUBLISH=true

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
  LAST_HASH="HEAD^"
  if [ -e last_hash_${branch} ]
  then
    LAST_HASH=$(cat last_hash_${branch})
  fi
  
  pushd "$LUNCHINATOR_GIT"
  git checkout $branch
  git pull

  THIS_HASH="$(git rev-parse HEAD)"
  popd

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
      echo $THIS_HASH > last_hash_${branch}
    fi
    log "Cleaning up"
    eval "./$BUILD_SCRIPT --clean" 2>&1 | tee -a buildserver.log

  fi

  sleep 2
done

popd
