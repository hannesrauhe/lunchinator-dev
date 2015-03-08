#!/bin/bash

if [ "$LUNCHINATOR_GIT" == "" ] && [ -d "lunchinator" ]
then
  export LUNCHINATOR_GIT="$(pwd)/lunchinator"
fi

args=$(getopt -l "publish,clean,no-tarball" -o "pcn" -- "$@")

if [ ! $? == 0 ]
then
  exit 1
fi

eval set -- "$args"

TARBALL=true
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
    -n|--no-tarball)
        TARBALL=false
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
echo "$VERSION" > version
popd &>/dev/null

rm -rf build/ dist/

echo "*** Building Application Bundle ***"
if ! pyinstaller -y -F -w lunchinator_osx.spec
then
  exit 1
fi

cp "${LUNCHINATOR_GIT}/version" dist/Lunchinator.app/Contents
git rev-list HEAD --count > dist/Lunchinator.app/Contents/commit_count
cat > dist/Lunchinator.app/Contents/Resources/qt.conf <<EOF
[paths]
Plugins=MacOS/qt4_plugins
EOF

echo "*** copying python code into bundle ***"
cp -r ${LUNCHINATOR_GIT}/bin ${LUNCHINATOR_GIT}/images ${LUNCHINATOR_GIT}/lunchinator ${LUNCHINATOR_GIT}/plugins ${LUNCHINATOR_GIT}/sounds ${LUNCHINATOR_GIT}/start_lunchinator.py ${LUNCHINATOR_GIT}/lunchinator_pub.asc dist/Lunchinator.app/Contents
cp -r /usr/local/Cellar/terminal-notifier/1.6.2/terminal-notifier.app dist/Lunchinator.app/Contents/bin

echo "*** Code-Signing Application ***"
pushd dist &>/dev/null
if ! codesign --deep -s "Code Signing" Lunchinator.app
then
  exit 1
fi
popd &>/dev/null

if ! $TARBALL
then
  exit 0
fi

echo "*** Creating tarball ***"
pushd dist
if ! tar cjf Lunchinator.app.tbz Lunchinator.app
then
  exit 1
fi
popd &>/dev/null

echo "*** Creating signature file ***"
if ! PYTHONPATH=$LUNCHINATOR_GIT:$PYTHONPATH python hashNsign.py dist/Lunchinator.app.tbz
then
  exit 1
fi

if [ "$LUNCHINATOR_BRANCH" == "master" ]
then
  UPLOAD_TARGET="update.lunchinator.de"
elif [ "$LUNCHINATOR_BRANCH" == "nightly" ]
then
  UPLOAD_TARGET="nightly.lunchinator.de"
else
  echo "Unknown branch, cannot publish."
  exit 1
fi

if $PUBLISH
then
  USER=$(security find-internet-password -s "$UPLOAD_TARGET" | grep "acct" | cut -d '"' -f 4)
  PASSWD=$(security 2>&1 >/dev/null find-internet-password -gs "$UPLOAD_TARGET" | cut -d '"' -f 2)
  ncftp <<EOF
open -u ${USER} -p ${PASSWD} "ftp://${UPLOAD_TARGET}/mac/"
mput -rf dist/${VERSION}/
mput -f dist/latest_version.asc
mput -f dist/index.html 
quit
EOF
  if [ $? != 0 ]
  then
    exit 1
  fi
fi
