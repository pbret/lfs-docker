set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
MAKEFLAGS="-j $(nproc)"
export LFS LC_ALL LFS_TGT PATH MAKEFLAGS
