#!/bin/bash

set -e


HARBOR_REGISTRY=harbor.metabot.pro:5000/rpa-portal
IMAGE_NAME=${HARBOR_REGISTRY}/${NAME}

function help {
cat <<EOF
Usage:
  NAME=app_name PORT=8082:80 VERSION=1.0 deploy.sh
EOF
exit 1
}

[ -z "${NAME}" ] && echo "ERROR: NAME not defined" && help
[ -z "${PORT}" ] && echo "ERROR: PORT not defined" && help

[ -z "${VERSION}" ] && VERSION=$(date +"%y%m%d-%H%M%S")
#VERSION=latest

WORKDIR=~/build/${NAME}

pushd $WORKDIR

# Update latest
if [ -d ".git" ]; then
  git checkout .
  git pull
fi

# Build a new app
docker build -t ${IMAGE_NAME}:${VERSION} .

# Push an image
docker push ${IMAGE_NAME}:${VERSION}

# Stop a previous app

prev_app=$(docker ps -f name="${NAME}$" -q)
[ -n "${prev_app}" ] && docker rm -f ${prev_app}

# Run a new app
docker run -d --name ${NAME} \
           --restart=unless-stopped \
           -p "${PORT}" ${IMAGE_NAME}:${VERSION}


# Delete untaged images
dangled_images=$(docker images | grep none | awk '{print $3}')
[ -n "${dangled_images}" ] && docker rmi -f ${dangled_images}

popd