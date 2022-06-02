VERSION=v14.0.0
TARGET=origin
# git push $TARGET :refs/tags/$VERSION
git tag -d $VERSION
git tag $VERSION
git push -f $TARGET $VERSION

