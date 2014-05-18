#!/bin/bash
. /etc/profile
export DEBFULLNAME="The Lunch Team"
export DEBEMAIL=info@lunchinator.de
export OBSUSERNAME=Cornelius_Ratsch

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

pushd "$( dirname "${BASH_SOURCE[0]}" )"


log "---------- Starting build at $(date) ----------"

if [ "$1" == "" ]
then
  log "No command provided. Aborting." 1>&2
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

branches=(master nightly)

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
    eval "./$1 --publish" 2>&1 | tee -a buildserver.log
    if [ ${PIPESTATUS[0]} -eq 0 ]
    then
      log "Successfully built version $VERSION"
      echo $THIS_HASH > last_hash_${branch}
    fi
    log "Cleaning up"
    eval "./$1 --clean" 2>&1 | tee -a buildserver.log

  fi

  sleep 2
done

popd
