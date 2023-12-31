#!/bin/bash

set -e

if [ -x "$(command -v docker)" ]; then
    echo "Docker is installed and the execute permission is granted."
    if getent group docker | grep &>/dev/null "\b$(id -un)\b"; then
	echo "User $(id -un) is in the group docker."
    else
        echo "Docker is not managed as a non-root user."
	echo "Please refer to the following URL to manage Docker as a non-root user."
        echo "https://docs.docker.com/install/linux/linux-postinstall/"
	exit
    fi
else
    echo "Docker is not installed or the execute permission is not granted."
    echo "Please refer to the following URL to install Docker."
    echo "http://redmine.corpnet.asus/projects/configuration-management-service/wiki/Docker"
    exit
fi

if dpkg-query -s qemu-user-static 1>/dev/null 2>&1; then
    echo "The package qemu-user-static is installed."
else
    echo "The package qemu-user-static is not installed yet and it will be installed now."
    sudo apt-get install -y qemu-user-static
fi

if dpkg-query -s binfmt-support 1>/dev/null 2>&1; then
    echo "The package binfmt-support is installed."
else
    echo "The package binfmt-support is not installed yet and it will be installed now."
    sudo apt-get install -y binfmt-support
fi

DIRECTORY_PATH_TO_SOURCE="$(dirname $(dirname $(readlink -f $0)))"

if [ $# -eq 0 ]; then
    echo "There is no directory path to the source provided."
    echo "Use the default directory path to the source [$DIRECTORY_PATH_TO_SOURCE]."
else
    DIRECTORY_PATH_TO_SOURCE=$1
    if [ ! -d $DIRECTORY_PATH_TO_SOURCE ]; then
        echo "The source directory [$DIRECTORY_PATH_TO_SOURCE] is not found."
        exit
    fi
fi

DOCKER_IMAGE="asus/tinker_2-linux-builder:latest"
#cp ~/.gitconfig gitconfig
cp -r $DIRECTORY_PATH_TO_SOURCE/debian/ubuntu-build-service/packages $DIRECTORY_PATH_TO_SOURCE/docker_builder/.
docker build --build-arg userid=$(id -u) --build-arg groupid=$(id -g) --build-arg username=$(id -un) -t $DOCKER_IMAGE \
    --file $DIRECTORY_PATH_TO_SOURCE/docker_builder/Dockerfile $DIRECTORY_PATH_TO_SOURCE/docker_builder
rm -rf $DIRECTORY_PATH_TO_SOURCE/docker_builder/packages

if [ $VERSION ] || [ $VERSION_NUMBER ] || [ $JENKINS_COMMAND ]; then
	OPTIONS="--privileged --rm -t -e VERSION=$VERSION -e VERSION_NUMBER=$VERSION_NUMBER"
else
	OPTIONS="--privileged --rm -it"
fi

OPTIONS+=" --volume $DIRECTORY_PATH_TO_SOURCE:/source"
echo "Options to run docker: $OPTIONS"

COMMAND="chroot --skip-chdir --userspec=$(id -un):$(id -un) / /bin/bash"

if [ $VERSION ] || [ $VERSION_NUMBER ] || [ $JENKINS_COMMAND ]; then
	docker run $OPTIONS $DOCKER_IMAGE $COMMAND -c "$JENKINS_COMMAND"
else
	docker run $OPTIONS $DOCKER_IMAGE $COMMAND
fi
