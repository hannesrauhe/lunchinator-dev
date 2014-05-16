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

log "---------- Starting build at $(date) ----------"

if [ "$1" == "" ]
then
  log "No command provided. Aborting." 1>&2
  finish 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $DIR

if [ ! -d "lunchinator" ]
then
  git clone https://github.com/hannesrauhe/lunchinator.git
fi

branches=(master nightly)

for branch in "${branches[@]}"
do
  LAST_HASH="HEAD^"
  if [ -e last_hash_${branch} ]
  then
    LAST_HASH=$(cat last_hash_${branch})
  fi
  
  pushd lunchinator
  git checkout $branch
  git pull

  THIS_HASH="$(git rev-parse HEAD)"

  if [ $LAST_HASH == $THIS_HASH ]
  then
    popd 
    log "No new version in git for $branch"
  else
    VERSION="$(git describe --tags --abbrev=0).$(git rev-list HEAD --count)"
    echo $VERSION > version
    git log $LAST_HASH..HEAD --oneline --no-merges > changelog
    popd

    #echo $VERSION
    if eval "./$1 --publish" 2>&1 | tee -a buildserver.log
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
