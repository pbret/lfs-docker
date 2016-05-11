#Build LFS using Docker

This project aims to automate [Linux From Scratch](http://www.linuxfromscratch.org/lfs/) build, using [Docker](https://www.docker.com/) capabilities.

Most of the instructions used to build LFS have been extracted from the LFS book.

Currently, only the build of the *LFS toolchain* for [LFS 7.9-systemd](http://www.linuxfromscratch.org/lfs/view/7.9-systemd/) is provided.

## Prerequesites
You need a Linux environment with:
* wget (or curl, or any equivalent tool)
* docker

## Steps

**Download the sources for LFS**

This step has been excluded from the Dockerfile to speed up the build process. Once the sources have been successfully downloaded, it's useless to execute it again.

The instructions hereafter will download the sources for LFS and put them in the `lfs-toolchain` directory. It take times to download the sources (size is around 340 Mo).

    wget --quiet --timestamping http://www.linuxfromscratch.org/lfs/view/7.9-systemd/wget-list
    wget --quiet --timestamping --directory-prefix=lfs-toolchain --continue --input-file=wget-list

**Build the docker image for the toolchain**

The whole process is automated. All executed instructions are defined in `lfs-toolchain/Dockerfile`.
The overall compilation may takes hours.

    docker build --tag=lfs-systemd/lfs-toolchain:7.9 --build-arg PROC=$(nproc) lfs-toolchain

**Extract the toolchain**

You can now extract the toolchain (size is around 480 Mo).

    docker run lfs-systemd/lfs-toolchain:7.9 tar -cJf - -C /mnt/lfs . > lfs-toolchain.tar.xz

## Next steps

TODO: use the toolchain as a Dockerfile basis to build the LFS system.

## Licenses

As precised in the [LFS book](http://www.linuxfromscratch.org/lfs/view/7.9-systemd/appendices/licenses.html), the LFS computer instructions are licensed under the [MIT License](http://www.linuxfromscratch.org/lfs/view/7.9-systemd/appendices/mit.html).