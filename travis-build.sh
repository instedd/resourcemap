#!/bin/bash
set -eo pipefail

git describe --always > REVISION

PROJECT_VERSION=`cat REVISION`

# Restore original version of Gemfile.lock so bundle install --deployment during the build does not fail
# The lockfile is modified in Travis because of poirot_rails which is not installed on CI environments
git checkout Gemfile.lock

if [ "$TRAVIS_TAG" = "" ]; then
  REV=`git rev-parse --short HEAD`
  VERSION="$PROJECT_VERSION-dev (build $TRAVIS_BUILD_NUMBER)"
  case $TRAVIS_BRANCH in
    master)
      DOCKER_TAG="dev"
      ;;

    release/*)
      DOCKER_TAG="$PROJECT_VERSION-dev"
      ;;

    stable)
      echo "Pulling $PROJECT_VERSION and tagging as latest"
      docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}
      docker pull ${DOCKER_REPOSITORY}:${PROJECT_VERSION}
      docker tag ${DOCKER_REPOSITORY}:${PROJECT_VERSION} ${DOCKER_REPOSITORY}:latest
      docker push ${DOCKER_REPOSITORY}:latest
      exit 0
      ;;

    dockerfile)
      DOCKER_TAG="dockerfile"
      ;;

    *)
      exit 0
      ;;
  esac
else
  TAG_VERSION="${TRAVIS_TAG/-*/}"
  if [ "$PROJECT_VERSION" != "$TAG_VERSION" ]; then
    echo "Project version and tag differs: $PROJECT_VERSION != $TRAVIS_TAG"
    exit 1
  fi

  VERSION="$TRAVIS_TAG (build $TRAVIS_BUILD_NUMBER)"
  DOCKER_TAG="$TRAVIS_TAG"

  if [ "$TAG_VERSION" = "$TRAVIS_TAG" ]; then
    EXTRA_DOCKER_TAG="${TRAVIS_TAG%.*}"
  fi
fi

echo "Version: $VERSION"
echo $VERSION > VERSION

# Build and push Docker image
echo "Docker tag: $DOCKER_TAG"
docker build -t ${DOCKER_REPOSITORY}:${DOCKER_TAG} .
docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}
docker push ${DOCKER_REPOSITORY}:${DOCKER_TAG}

# Push extra image on exact tags
if [ "$EXTRA_DOCKER_TAG" != "" ]; then
  echo "Pushing also as $EXTRA_DOCKER_TAG"
  docker tag ${DOCKER_REPOSITORY}:${DOCKER_TAG} ${DOCKER_REPOSITORY}:${EXTRA_DOCKER_TAG}
  docker push ${DOCKER_REPOSITORY}:${EXTRA_DOCKER_TAG}
fi
