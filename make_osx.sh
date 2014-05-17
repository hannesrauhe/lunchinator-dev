#!/bin/bash

if [ "$LUNCHINATOR_GIT" == "" ] && [ -d "lunchinator" ]
then
  export LUNCHINATOR_GIT="$(pwd)/lunchinator"
fi

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
        rm -rf build dist
        exit 0
        ;;
    -h)
        echo "Use with -p|--publish to publish to Launchpad immediately."
        exit 0
        ;;
  esac

  shift
done

pushd "$LUNCHINATOR_GIT" &>/dev/null 
VERSION="$(git describe --tags --abbrev=0).$(git rev-list HEAD --count)"
echo "$VERSION" > lunchinator/version
popd &>/dev/null

rm -rf build/ dist/

echo "*** Building Application Bundle ***"
if ! pyinstaller -y -F -w lunchinator_osx.spec
then
  exit 1
fi

cp lunchinator/version dist/Lunchinator.app/Contents
git rev-list HEAD --count > dist/Lunchinator.app/Contents/commit_count
cat > dist/Lunchinator.app/Contents/Resources/qt.conf <<EOF
[paths]
Plugins=MacOS/qt4_plugins
EOF

echo "*** copying python code into bundle ***"
cp -r lunchinator/bin lunchinator/images lunchinator/lunchinator lunchinator/plugins lunchinator/sounds lunchinator/start_lunchinator.py  dist/Lunchinator.app/Contents
cp $(which terminal-notifier) dist/Lunchinator.app/Contents/bin

echo "*** Creating tarball ***"
cd dist
if ! tar cjf Lunchinator.app.tbz Lunchinator.app
then
  exit 1
fi
cd ..

echo "*** Creating signature file ***"
if ! PYTHONPATH=$LUNCHINATOR_GIT:$PYTHONPATH python hashNsign.py dist/Lunchinator.app.tbz
then
  exit 1
fi

if $PUBLISH
then
  USER=$(security find-internet-password -s update.lunchinator.de | grep "acct" | cut -d '"' -f 4)
  PASSWD=$(security 2>&1 >/dev/null find-internet-password -gs update.lunchinator.de | cut -d '"' -f 2)
  ncftp <<EOF
open -u ${USER} -p ${PASSWD} ftp://update.lunchinator.de/mac/
mput -rf dist/${VERSION}/
mput -f dist/latest_version.asc
quit
EOF
  if [ $? != 0 ]
  then
    exit 1
  fi
fi
