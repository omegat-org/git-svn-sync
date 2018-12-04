#!/bin/sh

set -euox pipefail

# Utilities

gitSha() {
    (
        cd $1
        git rev-parse master
    )
}

svnRevisionLocal() {
    (
        cd $1
        git svn find-rev $(gitSha $1)
    )
}

svnRevisionRemote() {
    svn info --show-item revision svn://svn.code.sf.net/p/omegat/svn/trunk
}

# Sync phases

init() {
    if [ ! -d /repo ]; then
        mkdir /repo
        aws s3 cp s3://omegat/omegat-git-svn.tar.gz - | tar xz -C /repo
    fi
    echo /repo/*
}

needsUpdate() {
    [ "$(svnRevisionLocal $1)" != "$(svnRevisionRemote $1)" ]
    return
}

doSync() {
    (
        cd $1
        # Ensure garbage collection happens synchronously, not in background.
        git config gc.autodetach false
        git svn info
        # Overwrite the authors file with the latest version from SVN.
        svn cat svn://svn.code.sf.net/p/omegat/svn/trunk/release/ci/authors.txt >authors
        git svn fetch
        git branch -f master trunk
        # New tags will appear in refs/remotes/tags, but will disappear after repacking.
        [ "$(ls -A refs/remotes/tags)" ] && cp refs/remotes/tags/* refs/tags/
        git push --tags ssh://omegat-jenkins@git.code.sf.net/p/omegat/code master
        git gc
    )
}

finalize() {
    (
        cd $(dirname $1)
        local TARGET=$(basename $1).tar.gz
        tar czf $TARGET *
        local TEMP=$TARGET-r$(svnRevisionLocal $1)
        aws s3 cp ./*.tar.gz s3://omegat/$TEMP
        aws s3 mv s3://omegat/$TEMP s3://omegat/$TARGET
        rm $TARGET
    )
}

REPO=$(init)
for _ in $(seq 1 10); do
    if needsUpdate $REPO; then
        doSync $REPO
        finalize $REPO
    else
        exit 0
    fi
done
