#!/bin/sh

set -euo pipefail

if [ ! -d /repo ]; then
    mkdir /repo
    aws s3 cp s3://omegat/omegat-git-svn.tar.gz - | tar xvz -C /repo
fi

cd /repo/*
# Ensure garbage collection happens synchronously, not in background.
git config gc.autodetach false
git svn info
# Overwrite the authors file with the latest version from SVN.
svn cat svn://svn.code.sf.net/p/omegat/svn/trunk/release/ci/authors.txt >authors-new
mv authors-new authors
git svn fetch
git branch -f master trunk
# New tags will appear in refs/remotes/tags, but will disappear after repacking.
[ "$(ls -A refs/remotes/tags)" ] && cp refs/remotes/tags/* refs/tags/
git push --tags ssh://omegat-jenkins@git.code.sf.net/p/omegat/code master
GIT_SHA=$(git rev-parse master)
GIT_SHA_SHORT=$(git rev-parse --short $GIT_SHA)
SVN_REVISION=$(git svn find-rev $GIT_SHA)
echo "r$SVN_REVISION $GIT_SHA_SHORT"

cd /repo
tar czvf $(echo *).tar.gz *
TARGET=$(echo *.tar.gz)
TEMP=$TARGET-r$SVN_REVISION
aws s3 cp ./*.tar.gz s3://omegat/$TEMP
aws s3 mv s3://omegat/$TEMP s3://omegat/$TARGET
