#!/bin/bash

if [ "$LUNCHINATOR_GIT" == "" ] && [ -d "lunchinator" ]
then
  LUNCHINATOR_GIT="$(pwd)/lunchinator"
fi

function generate_changelog() {
	if [ "$LAST_HASH" != "" ]
	then
	  CHANGELOG="$(python "$CHANGELOG_PY" --only-first-line --print-lines --last-hash=$LAST_HASH --path="$LUNCHINATOR_GIT")"
	  echo "$CHANGELOG" |
	  while read line 
	  do
	    dch -a "$line"
	  done
  fi
  sed -i -e '/automatically created by stdeb/d' debian/changelog
}

dists=(lucid precise saucy trusty)

args=$(getopt -l "publish,clean" -o "pc" -- "$@")

if [ ! $? == 0 ]
then
  exit 1
fi

eval set -- "$args"

PUBLISH=false

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
        rm -rf deb_*/ *.log dist
        exit 0
        ;;
    -h)
        echo "Use with -p|--publish to publish to Launchpad immediately."
        exit 0
        ;;
  esac

  shift
done

if [ "$DEBFULLNAME" == "" ] || [ "$DEBEMAIL" == "" ]
then
  echo "Please export DEBFULLNAME and DEBEMAIL to your environment."
  exit 1
fi

if ! type py2dsc &>/dev/null
then
  echo "Please install python-stdeb first, using pip. Do NOT install it via aptitude!"
  exit 1
fi

if python -c "from stdeb.util import PYTHON_ALL_MIN_VERS; print PYTHON_ALL_MIN_VERS" &>/dev/null
then
  echo "Please uninstall python-stdeb via aptitude and install it via pip."
  exit 1
fi

if ! type dch &>/dev/null
then
  echo "Please install devscripts first."
  exit 1
fi

if ! type lintian &>/dev/null
then
  echo "Please install lintian first."
  exit 1
fi

pushd "$LUNCHINATOR_GIT" &>/dev/null 
VERSION="$(git describe --tags --abbrev=0).$(git rev-list HEAD --count)"
echo "$VERSION" > version
popd &>/dev/null

for dist in "${dists[@]}"
do
  echo -e "\e[00;31m***** Creating source package for ${dist} *****\e[00m"
  export dist
  rm -rf dist deb_${dist}
  pushd "$LUNCHINATOR_GIT"
  export __lunchinator_branch=$(git rev-parse --abbrev-ref HEAD)
  export __isubuntu=1 #make sure setup.py builds for ubuntu
  python setup.py sdist --dist-dir=../dist
  popd
  py2dsc --suite=${dist} --dist-dir=deb_${dist} dist/Lunchinator*
  pushd deb_${dist}/lunchinator-*
  generate_changelog
  debuild -S 2>&1 | tee ../../${dist}.log
  if $PUBLISH
  then
    pushd ..
    echo -e "\e[00;31m***** Publishing package for ${dist} *****\e[00m"
    dput ppa:lunch-team/lunchinator lunchinator*.changes
    popd
  fi
  popd
done
