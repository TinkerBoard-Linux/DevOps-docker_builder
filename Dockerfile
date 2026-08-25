# Pinned to Canonical's jammy-20260731.1 release (published 2026-08-04) to avoid
# silently picking up a newer Ubuntu 22.04 rebuild. Re-verify tar's version and
# pseudo compatibility (see meta/recipes-devtools/pseudo/pseudo_git.bb) before
# moving this pin.
FROM ubuntu:22.04@sha256:3b06811b2afd352be909dd088a004166d665dc76d38b13eada33522a9d915c6f

ARG DEBIAN_FRONTEND=noninteractive
ARG userid
ARG groupid
ARG username

# Install required packages for building Tinker Board 2 Debian
# kmod: depmod is required by "make modules_install"
COPY packages /packages
COPY ./qemu-aarch64-static .

# Install required packages for building Debian
RUN apt-get update
RUN apt-get install -y g++-aarch64-linux-gnu
RUN apt-get update && apt-get install -y ssh make gcc libssl-dev liblz4-tool expect g++ patchelf chrpath gawk texinfo chrpath diffstat binfmt-support qemu-user-static live-build bison flex fakeroot cmake gcc-multilib g++-multilib unzip device-tree-compiler ncurses-dev libgucharmap-2-90-dev bzip2 expat gpgv2 cpp-aarch64-linux-gnu libgmp-dev libmpc-dev

# kmod: depmod is required by "make modules_install"
RUN apt-get update && apt-get install -y kmod

RUN apt-get update && apt-get install -y zip mtools

RUN apt-get update && apt-get install -y fdisk parted

#Install required packages to build Debian package
RUN apt-get update && apt-get install -y dpkg-dev
RUN apt-get update && apt-get install -y devscripts
# Install additional packages for building base debian system by ubuntu-build-service from linaro
#RUN apt-get install -y binfmt-support qemu-user-static live-build
RUN apt-get update && apt-get install -y bc time rsync zstd python3 python2 python2-dev python3-dev python-is-python3 file vim-common sudo curl iputils-ping
RUN apt-get update && apt-get install -y locales
RUN apt-get update && apt-get install -y bsdmainutils
RUN dpkg -i /packages/* || apt-get install -f -y
COPY qemu-aarch64-static /usr/bin/qemu-aarch64-static
RUN rm qemu-aarch64-static

RUN locale-gen en_US.UTF-8

RUN groupadd -g $groupid $username && \
    useradd -m -u $userid -g $groupid $username && \
    echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo $username >/root/username

ENV HOME=/home/$username
ENV USER=$username
WORKDIR /source

RUN git config --global gc.autoDetach false
