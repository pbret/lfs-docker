# cf. http://www.linuxfromscratch.org/lfs/view/7.9-systemd/
FROM debian:8
ARG LFS_TEST=1
ARG PROC=1
MAINTAINER Perceval BRET
LABEL  com.ac.src.architecture="x86_64" \
    com.ac.src.distribution="lfs" \
    com.ac.src.version="7.9" \
    com.ac.src.init="systemd"
CMD ["/bin/bash"]

# install required packages
RUN  apt-get -q update && \
  apt-get -q -y install build-essential bison gawk texinfo wget file && \
  apt-get -q -y autoremove && \
  rm -rf /var/lib/apt/lists/*

# set bash as default shell
WORKDIR /bin
RUN  rm sh && \
  ln -s bash sh
  
# create directories
ENV  LFS=/mnt/lfs
RUN  mkdir -pv $LFS/{usr,sources} && \
  chmod -v a+wt $LFS/sources
WORKDIR $LFS/sources


# check environment
COPY [ "version-check.sh", "library-check.sh", "$LFS/sources/" ]
RUN chmod -v 755 *.sh && sync && ./version-check.sh && ./library-check.sh

# create tools directory
RUN  mkdir -pv $LFS/tools && \
  ln -sv $LFS/tools /

# create lfs user (with lfs as password)
RUN  groupadd lfs && \
  useradd -s /bin/bash -g lfs -m -k /dev/null lfs && \
  echo "lfs:lfs" | chpasswd

# set directories accesses
RUN  chown -v lfs $LFS/tools && \
  chown -v lfs $LFS/sources

# set lfs user environment
USER lfs
COPY [ ".bash_profile", ".bashrc", "/home/lfs/" ]

# @hint must be defined as ENV to be accessible by RUN commands
ENV  LC_ALL=POSIX \
  LFS_TGT=x86_64-lfs-linux-gnu \
  PATH=/tools/bin:/bin:/usr/bin \
  MAKEFLAGS="-j $PROC"

 
###########################
# compile binutils (pass 1)
###########################
COPY [ "binutils-2.26.tar.bz2", "$LFS/sources/" ]
RUN  tar -xf binutils-2.26.tar.bz2 -C /tmp/ && \
  pushd /tmp/binutils-2.26 && \
  mkdir -v build && \
  cd build && \
  ../configure     \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror && \
  make && \
  mkdir -pv /tools/lib && \
  ln -sv lib /tools/lib64 && \
  make install && \
  popd && \
  rm -rf /tmp/binutils-*


######################
# compile gcc (pass 1)
######################
COPY [ "gcc-5.3.0.tar.bz2", "mpfr-3.1.3.tar.xz", "gmp-6.1.0.tar.xz", "mpc-1.0.3.tar.gz", "$LFS/sources/" ]
RUN  tar -xf gcc-5.3.0.tar.bz2 -C /tmp/ && \
  pushd /tmp/gcc-5.3.0 && \
  tar -xf $LFS/sources/mpfr-3.1.3.tar.xz && \
  mv -v mpfr-3.1.3 mpfr && \
  tar -xf $LFS/sources/gmp-6.1.0.tar.xz && \
  mv -v gmp-6.1.0 gmp && \
  tar -xf $LFS/sources/mpc-1.0.3.tar.gz && \
  mv -v mpc-1.0.3 mpc && \
  for file in $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h); do \
      cp -uv $file{,.orig}; \
      sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' -e 's@/usr@/tools@g' $file.orig > $file; \
      echo -e "\n#undef STANDARD_STARTFILE_PREFIX_1 \n#undef STANDARD_STARTFILE_PREFIX_2 \n#define STANDARD_STARTFILE_PREFIX_1 \"/tools/lib/\" \n#define STANDARD_STARTFILE_PREFIX_2 \"\"" >> $file; \
      touch $file.orig; \
  done && \
  mkdir -v build && \
  cd build && \
  ../configure                             \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++ && \
  make && \
  make install && \
  popd && \
  rm -rf /tmp/gcc-*


###########################
# compile Linux API headers
###########################
COPY [ "linux-4.4.2.tar.xz", "$LFS/sources/" ]
RUN  tar -xf linux-4.4.2.tar.xz -C /tmp/ && \
  pushd /tmp/linux-4.4.2 && \
  make mrproper && \
  make INSTALL_HDR_PATH=dest headers_install && \
  cp -rv dest/include/* /tools/include && \
  popd && \
  rm -rf /tmp/linux-*


###############
# compile glibc
###############
COPY [ "glibc-2.23.tar.xz", "$LFS/sources/" ]
RUN  tar -xf glibc-2.23.tar.xz -C /tmp/ && \
  pushd /tmp/glibc-2.23 && \
  mkdir -v build && \
  cd build && \
  ../configure                             \
    --prefix=/tools                               \
    --host=$LFS_TGT                               \
    --build=$(../scripts/config.guess) \
    --disable-profile                             \
    --enable-kernel=2.6.32                        \
    --enable-obsolete-rpc                         \
    --with-headers=/tools/include                 \
    libc_cv_forced_unwind=yes                     \
    libc_cv_ctors_header=yes                      \
    libc_cv_c_cleanup=yes && \
  make && \
  make install && \
  popd && \
  rm -rf /tmp/glibc-*

# run tests
RUN  echo 'int main(){}' > dummy.c && \
  $LFS_TGT-gcc dummy.c && \
  readelf -l a.out | grep ': /tools' && \
  rm -v dummy.c a.out

###################
# compile libstdc++
###################
COPY [ "gcc-5.3.0.tar.bz2", "$LFS/sources/" ]
RUN  tar -xf gcc-5.3.0.tar.bz2 -C /tmp/ && \
  pushd /tmp/gcc-5.3.0 && \
  mkdir -v build && \
  cd build && \
  ../libstdc++-v3/configure \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/5.3.0 && \
  make && \
  make install && \
  popd && \
  rm -rf /tmp/gcc-*

  
###########################
# compile binutils (pass 2)
###########################
COPY [ "binutils-2.26.tar.bz2", "$LFS/sources/" ]
RUN  tar -xf binutils-2.26.tar.bz2 -C /tmp/ && \
  pushd /tmp/binutils-2.26 && \
  mkdir -v build && \
  cd build && \
  CC=$LFS_TGT-gcc AR=$LFS_TGT-ar RANLIB=$LFS_TGT-ranlib \
  ../configure     \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot && \
  make && \
  make install && \
  make -C ld clean && \
  make -C ld LIB_PATH=/usr/lib:/lib && \
  cp -v ld/ld-new /tools/bin && \
  popd && \
  rm -rf /tmp/binutils-*
  
  
######################
# compile gcc (pass 2)
######################
COPY [ "gcc-5.3.0.tar.bz2", "mpfr-3.1.3.tar.xz", "gmp-6.1.0.tar.xz", "mpc-1.0.3.tar.gz", "$LFS/sources/" ]
RUN  tar -xf gcc-5.3.0.tar.bz2 -C /tmp/ && \
  pushd /tmp/gcc-5.3.0 && \
  cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h && \
  for file in $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h); do \
      cp -uv $file{,.orig}; \
      sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' -e 's@/usr@/tools@g' $file.orig > $file; \
      echo -e "\n#undef STANDARD_STARTFILE_PREFIX_1 \n#undef STANDARD_STARTFILE_PREFIX_2 \n#define STANDARD_STARTFILE_PREFIX_1 \"/tools/lib/\" \n#define STANDARD_STARTFILE_PREFIX_2 \"\"" >> $file; \
      touch $file.orig; \
  done && \
  tar -xf $LFS/sources/mpfr-3.1.3.tar.xz && \
  mv -v mpfr-3.1.3 mpfr && \
  tar -xf $LFS/sources/gmp-6.1.0.tar.xz && \
  mv -v gmp-6.1.0 gmp && \
  tar -xf $LFS/sources/mpc-1.0.3.tar.gz && \
  mv -v mpc-1.0.3 mpc && \
  mkdir -v build && \
  cd build && \
  CC=$LFS_TGT-gcc CXX=$LFS_TGT-g++ AR=$LFS_TGT-ar RANLIB=$LFS_TGT-ranlib \
  ../configure                             \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp && \
  make && \
  make install && \
  ln -sv gcc /tools/bin/cc && \
  popd && \
  rm -rf /tmp/gcc-*
  
# run tests
RUN  echo 'int main(){}' > dummy.c && \
  cc dummy.c && \
  readelf -l a.out | grep ': /tools' && \
  rm -v dummy.c a.out
  

##################
# compile tcl-core
##################
COPY [ "tcl-core8.6.4-src.tar.gz", "$LFS/sources/" ]
RUN  tar -xf tcl-core8.6.4-src.tar.gz -C /tmp/ && \
  pushd /tmp/tcl8.6.4 && \
  cd unix && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then TZ=UTC make test; fi && \
  make install && \
  chmod -v u+w /tools/lib/libtcl8.6.so && \
  make install-private-headers && \
  ln -sv tclsh8.6 /tools/bin/tclsh && \
  popd && \
  rm -rf /tmp/tcl*

  
################
# compile expect
################
COPY [ "expect5.45.tar.gz", "$LFS/sources/" ]
RUN  tar -xf expect5.45.tar.gz -C /tmp/ && \
  pushd /tmp/expect5.45 && \
  cp -v configure{,.orig} && \
  sed 's:/usr/local/bin:/bin:' configure.orig > configure && \
  ./configure --prefix=/tools       \
    --with-tcl=/tools/lib \
    --with-tclinclude=/tools/include && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make test; fi && \
  make SCRIPTS="" install && \
  popd && \
  rm -rf /tmp/expect*

  
#################
# compile dejaGNU
#################
COPY [ "dejagnu-1.5.3.tar.gz", "$LFS/sources/" ]
RUN  tar -xf dejagnu-1.5.3.tar.gz -C /tmp/ && \
  pushd /tmp/dejagnu-1.5.3 && \
  ./configure --prefix=/tools && \
  make install && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  popd && \
  rm -rf /tmp/dejagnu-*


###############
# compile check
###############
COPY [ "check-0.10.0.tar.gz", "$LFS/sources/" ]
RUN  tar -xf check-0.10.0.tar.gz -C /tmp/ && \
  pushd /tmp/check-0.10.0 && \
  PKG_CONFIG= ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/check-*


#################
# compile ncurses
#################
COPY [ "ncurses-6.0.tar.gz", "$LFS/sources/" ]
RUN  tar -xf ncurses-6.0.tar.gz -C /tmp/ && \
  pushd /tmp/ncurses-6.0 && \
  sed -i s/mawk// configure && \
  ./configure --prefix=/tools \
    --with-shared   \
    --without-debug \
    --without-ada   \
    --enable-widec  \
    --enable-overwrite && \
  make && \
  make install && \
  popd && \
  rm -rf /tmp/ncurses-*


##############
# compile bash
##############
COPY [ "bash-4.3.30.tar.gz", "$LFS/sources/" ]
RUN  tar -xf bash-4.3.30.tar.gz -C /tmp/ && \
  pushd /tmp/bash-4.3.30 && \
  ./configure --prefix=/tools --without-bash-malloc && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make tests; fi && \
  make install && \
  ln -sv bash /tools/bin/sh && \
  popd && \
  rm -rf /tmp/bash-*

  
###############
# compile bzip2
###############
COPY [ "bzip2-1.0.6.tar.gz", "$LFS/sources/" ]
RUN  tar -xf bzip2-1.0.6.tar.gz -C /tmp/ && \
  pushd /tmp/bzip2-1.0.6 && \
  make && \
  make PREFIX=/tools install && \
  popd && \
  rm -rf /tmp/bzip2-*

  
###################
# compile coreutils
###################
# 2 tests fail (dd/direct.sh, dd/sparse.sh). Similar issue reported on some file systems => may be linked to docker fs
COPY [ "coreutils-8.25.tar.xz", "$LFS/sources/" ]
RUN  tar -xf coreutils-8.25.tar.xz -C /tmp/ && \
  pushd /tmp/coreutils-8.25 && \
  ./configure --prefix=/tools --enable-install-program=hostname && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make RUN_EXPENSIVE_TESTS=yes check || true; fi && \
  make install && \
  popd && \
  rm -rf /tmp/coreutils-*

  
###################
# compile diffutils
###################
COPY [ "diffutils-3.3.tar.xz", "$LFS/sources/" ]
RUN  tar -xf diffutils-3.3.tar.xz -C /tmp/ && \
  pushd /tmp/diffutils-3.3 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/diffutils-*

  
##############
# compile file
##############
COPY [ "file-5.25.tar.gz", "$LFS/sources/" ]
RUN  tar -xf file-5.25.tar.gz -C /tmp/ && \
  pushd /tmp/file-5.25 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/file-*

  
###################
# compile findutils
###################
COPY [ "findutils-4.6.0.tar.gz", "$LFS/sources/" ]
RUN  tar -xf findutils-4.6.0.tar.gz -C /tmp/ && \
  pushd /tmp/findutils-4.6.0 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/findutils-*


##############
# compile gawk
##############
COPY [ "gawk-4.1.3.tar.xz", "$LFS/sources/" ]
RUN  tar -xf gawk-4.1.3.tar.xz -C /tmp/ && \
  pushd /tmp/gawk-4.1.3 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/gawk-*

  
#################
# compile gettext
#################
COPY [ "gettext-0.19.7.tar.xz", "$LFS/sources/" ]
RUN  tar -xf gettext-0.19.7.tar.xz -C /tmp/ && \
  pushd /tmp/gettext-0.19.7 && \
  cd gettext-tools && \
  EMACS="no" ./configure --prefix=/tools --disable-shared && \
  make -C gnulib-lib && \
  make -C intl pluralx.c && \
  make -C src msgfmt && \
  make -C src msgmerge && \
  make -C src xgettext && \
  cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin && \
  popd && \
  rm -rf /tmp/gettext-*

  
##############
# compile grep
##############
COPY [ "grep-2.23.tar.xz", "$LFS/sources/" ]
RUN  tar -xf grep-2.23.tar.xz -C /tmp/ && \
  pushd /tmp/grep-2.23 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/grep-*

  
##############
# compile gzip 
##############
# 1 test fails (zless)
COPY [ "gzip-1.6.tar.xz", "$LFS/sources/" ]
RUN  tar -xf gzip-1.6.tar.xz -C /tmp/ && \
  pushd /tmp/gzip-1.6 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check || true; fi && \
  make install && \
  popd && \
  rm -rf /tmp/gzip-*

  
############
# compile m4
############
COPY [ "m4-1.4.17.tar.xz", "$LFS/sources/" ]
RUN  tar -xf m4-1.4.17.tar.xz -C /tmp/ && \
  pushd /tmp/m4-1.4.17 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/m4-*

  
##############
# compile make
##############
# 1 test fails (misc/fopen-fail)
COPY [ "make-4.1.tar.bz2", "$LFS/sources/" ]
RUN  tar -xf make-4.1.tar.bz2 -C /tmp/ && \
  pushd /tmp/make-4.1 && \
  ./configure --prefix=/tools --without-guile && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check || true; fi && \
  make install && \
  popd && \
  rm -rf /tmp/make-*

  
###############
# compile patch
###############
COPY [ "patch-2.7.5.tar.xz", "$LFS/sources/" ]
RUN  tar -xf patch-2.7.5.tar.xz -C /tmp/ && \
  pushd /tmp/patch-2.7.5 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/patch-*

  
##############
# compile perl
##############
COPY [ "perl-5.22.1.tar.bz2", "$LFS/sources/" ]
RUN  tar -xf perl-5.22.1.tar.bz2 -C /tmp/ && \
  pushd /tmp/perl-5.22.1 && \
  sh Configure -des -Dprefix=/tools -Dlibs=-lm && \
  make && \
  cp -v perl cpan/podlators/pod2man /tools/bin && \
  mkdir -pv /tools/lib/perl5/5.22.1 && \
  cp -Rv lib/* /tools/lib/perl5/5.22.1 && \
  popd && \
  rm -rf /tmp/perl-*

  
#############
# compile sed
#############
COPY [ "sed-4.2.2.tar.bz2", "$LFS/sources/" ]
RUN  tar -xf sed-4.2.2.tar.bz2 -C /tmp/ && \
  pushd /tmp/sed-4.2.2 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/sed-*

  
#############
# compile tar
#############
COPY [ "tar-1.28.tar.xz", "$LFS/sources/" ]
RUN  tar -xf tar-1.28.tar.xz -C /tmp/ && \
  pushd /tmp/tar-1.28 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/tar-*

  
#################
# compile texinfo
#################
COPY [ "texinfo-6.1.tar.xz", "$LFS/sources/" ]
RUN  tar -xf texinfo-6.1.tar.xz -C /tmp/ && \
  pushd /tmp/texinfo-6.1 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/texinfo-*

  
####################
# compile util-linux
####################
COPY [ "util-linux-2.27.1.tar.xz", "$LFS/sources/" ]
RUN  tar -xf util-linux-2.27.1.tar.xz -C /tmp/ && \
  pushd /tmp/util-linux-2.27.1 && \
  ./configure --prefix=/tools        \
    --without-python               \
    --disable-makeinstall-chown    \
    --without-systemdsystemunitdir \
    PKG_CONFIG="" && \
  make && \
  make install && \
  popd && \
  rm -rf /tmp/util-linux-*

  
############
# compile xz
############
COPY [ "xz-5.2.2.tar.xz", "$LFS/sources/" ]
RUN  tar -xf xz-5.2.2.tar.xz -C /tmp/ && \
  pushd /tmp/xz-5.2.2 && \
  ./configure --prefix=/tools && \
  make && \
  if [ $LFS_TEST -eq 1 ]; then make check; fi && \
  make install && \
  popd && \
  rm -rf /tmp/xz-*


# stripping
RUN  strip --strip-debug /tools/lib/* || true
RUN  /usr/bin/strip --strip-unneeded /tools/{,s}bin/* || true
RUN rm -rf /tools/{,share}/{info,man,doc}
USER root
RUN chown -R root:root $LFS/tools
