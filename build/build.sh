#!/bin/bash
dockeruser="jcrespoc311"
buildver="v1.0.0"

read -e -i "$buildver" -p "Building docker image for $dockeruser/svn-ssh:" buildver
docker build --build-arg DOCKER_USER="$dockeruser" --build-arg SVN_VERSION="$buildver" . -t "$dockeruser"/svn-ssh:"$buildver" -t "$dockeruser"/svn-ssh:latest
echo "Para publicar en DockerHub, usa:"
echo "docker push $dockeruser/svn-ssh:$buildver"
echo "docker push $dockeruser/svn-ssh:latest"
