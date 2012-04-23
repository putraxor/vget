version() {
  BRANCH=$1
  VERSION=$2

  for DIR in .; do
    (cd $DIR ; mvn versions:set -DgenerateBackupPoms=false -DnewVersion=$VERSION || exit 1)
  done

  git commit -m "bump version $BRANCH $VERSION" . || exit 1
}

push() {
  git checkout dev || exit 1
  git push || exit 1
  git push --tags || exit 1
}

# ex: server-1.0.0
TAG=$1
# ex: server
BRANCH=${TAG%-*}
# ex: 1.0.0
VERSION=${TAG#*-}
# ex: 1.0.0-SNAPSHOT
VERSIONSNAPSHOT=$VERSION-SNAPSHOT

if [ -z "$TAG" ]; then
  echo
  echo "type version like $0 server-1.0.0"
  git tag | tail
  exit 1
fi

MOD=$(git status --porcelain)

if [ ! -z "$MOD" ]; then
  echo "Can't bump version on modified tree:"
  git status -s
  exit 1
fi

# switch to dev
git checkout dev || exit 1

# update version to new one
version $BRANCH $VERSION || exit 1

# create proper branch (server-1.0.0), helps produce nice git history
git checkout -b $TAG || exit 1

# prepare to merge
git checkout master || exit 1

# do merge with a propertly named branch
git merge --no-ff $TAG || exit 1

# do tag last master commit
git tag $TAG || exit 1

# drop perpared branch
git branch -d $TAG || exit 1

# switch back to the dev
git checkout dev || exit 1

# update version with -SNAPSHOT postfix
version $BRANCH $VERSIONSNAPSHOT || exit 1

# push all back to the central repo
push || exit 1

