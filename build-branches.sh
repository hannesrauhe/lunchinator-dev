#!/bin/bash
. /etc/profile
export DEBFULLNAME="The Lunch Team"
export DEBEMAIL=info@lunchinator.de

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $DIR

git clone https://github.com/hannesrauhe/lunchinator.git

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
    echo "No new version in git for $branch"
  else
    VERSION="$(git describe --tags --abbrev=0).$(git rev-list HEAD --count)"
    echo $VERSION > version
    git log $LAST_HASH..HEAD --oneline --no-merges > changelog
    popd

    #echo $VERSION
    ./make_deb.sh --publish &&
    echo $THIS_HASH > last_hash_${branch}
    ./make_deb.sh --clean

  fi

  sleep 2
done

popd
