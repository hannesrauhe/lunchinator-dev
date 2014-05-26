#!/bin/bash

if [ "$LUNCHINATOR_GIT" == "" ] && [ -d "lunchinator" ]
then
  LUNCHINATOR_GIT="$(pwd)/lunchinator"
  LUNCHINATOR_DEV=".."
fi

if [ "$OBSUSERNAME" == "" ]
then
  echo "Please export OBSUSERNAME to your environment."
  exit -1
fi

args=$(getopt -l "publish,clean" -o "pc" -- "$@")

if [ ! $? == 0 ]
then
  exit 1
fi

eval set -- "$args"

PUBLISH=false

function clean() {
  pushd osc/home:${OBSUSERNAME}/${LBASENAME} &>/dev/null
  for f in $(osc st | grep '^?' | sed -e 's/^?\s*//')
  do
    echo "Deleting ${f}"
    rm "$f"
  done
  for f in $(osc st | grep '^M' | sed -e 's/^M\s*//')
  do
    echo "Reverting ${f}"
    osc revert "$f"
  done
  popd &>/dev/null
}

function update() {
  pushd osc/home:${OBSUSERNAME}/${LBASENAME} &>/dev/null
  osc up
  popd &>/dev/null
}

while [ $# -ge 1 ]; do
  case "$1" in
    --)
        # No more options left.
        shift
        break
       ;;
    -p|--publish)
        PUBLISH=true
        shift
        ;;
    -c|--clean)
        clean
        exit 0
        ;;
    -h)
        echo "Use with -p|--publish to publish to OBS immediately."
        exit 0
        ;;
  esac

  shift
done

if ! type osc &>/dev/null
then
  echo "Please install osc first."
  exit 1
fi

if ! type rpm &>/dev/null
then
  echo "Please install rpm first."
  exit 1
fi

mkdir -p osc
if [ ! -d osc/home:${OBSUSERNAME} ]
then
  echo "Checking out repository..."
  pushd osc
  if ! osc checkout home:${OBSUSERNAME}
  then
    popd
    echo "Error checkout out repository."
    rm -rf osc
    exit 1
  fi
  popd
fi

pushd "$LUNCHINATOR_GIT" &>/dev/null 
BRANCH=$(git rev-parse --abbrev-ref HEAD)
export __lunchinator_branch=$BRANCH

if [ $BRANCH == "master" ]
then
  LBASENAME=lunchinator
  SPECFILE=lunchinator.spec
else
  LBASENAME=lunchinator-${BRANCH}
  SPECFILE=lunchinator-${BRANCH}.spec
fi
popd &>/dev/null

# make sure there are no unversioned files that are unintentionally checked in
clean
update

# version has to be located besides setup.py
pushd "$LUNCHINATOR_GIT" &>/dev/null 
VERSION="$(git describe --tags --abbrev=0).$(git rev-list HEAD --count)"
echo "$VERSION" > version

export dist=
# if this is run on Ubuntu, have setup.py know this is not for Ubuntu.
export __notubuntu=1

python setup.py sdist --dist-dir="${LUNCHINATOR_DEV}/osc/home:${OBSUSERNAME}/${LBASENAME}"
python setup.py bdist_rpm --spec-only --dist-dir="${LUNCHINATOR_DEV}/osc/home:${OBSUSERNAME}/${LBASENAME}"
popd &>/dev/null

sed -i -e 's/\(^BuildArch.*$\)/#\1/' osc/home:${OBSUSERNAME}/${LBASENAME}/$SPECFILE

if $PUBLISH
then
  pushd osc/home:${OBSUSERNAME}/${LBASENAME}
  osc add $SPECFILE
  for f in $(osc st | grep '^?' | sed -e 's/^?\s*//')
  do
    osc add "$f"
  done
  osc commit -m "automatic build"
  popd
fi
