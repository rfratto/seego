FROM debian:buster as osxcross

RUN \
    dpkg --add-architecture i386 \
    && apt-get update && apt-get install -y --no-install-recommends \
        build-essential     \
        bzr                 \
        ca-certificates     \
        clang               \
        cmake               \
        curl                \
        g++                 \
        gcc                 \
        gcc-multilib        \
        git                 \
        gnupg               \
        libc6-dev           \
        libc6-dev-i386      \
        libsnmp-dev         \
        libxml2-dev         \
        linux-libc-dev:i386 \
        make                \
        mingw-w64           \
        patch               \
        xz-utils            \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ARG OSXCROSS_SDK_URL
ENV OSXCROSS_PATH=/usr/osxcross \
    OSXCROSS_REV=035cc170338b7b252e3f13b0e3ccbf4411bffc41 \
    SDK_VERSION=11.1
RUN  mkdir -p /tmp/osxcross && cd /tmp/osxcross                                           \
  && curl -sSL "https://codeload.github.com/tpoechtrager/osxcross/tar.gz/${OSXCROSS_REV}" \
      | tar -C /tmp/osxcross --strip=1 -xzf -                                             \
  && curl -sSLo tarballs/MacOSX${SDK_VERSION}.sdk.tar.xz ${OSXCROSS_SDK_URL}              \
  && UNATTENDED=yes ./build.sh                                                            \
  && mv target "${OSXCROSS_PATH}"                                                         \
  && rm -rf /tmp/osxcross "/usr/osxcross/SDK/MacOSX${SDK_VERSION}.sdk/usr/share/man"

FROM debian:buster
MAINTAINER Robert Fratto <robertfratto@gmail.com> (https://github.com/rfratto)

RUN  dpkg --add-architecture amd64    \
  && dpkg --add-architecture i386     \
  && dpkg --add-architecture armel    \
  && dpkg --add-architecture armhf    \
  && dpkg --add-architecture arm64    \
  && dpkg --add-architecture mips     \
  && dpkg --add-architecture mipsel   \
  && dpkg --add-architecture powerpc  \
  && dpkg --add-architecture ppc64el  \
  && dpkg --add-architecture s390x    \
  && apt-get update                   \
  && apt-get install -yq              \
        binfmt-support                \
        binutils-multiarch            \
        binutils-multiarch-dev        \
        build-essential               \
        bzr                           \
        clang                         \
        crossbuild-essential-arm64    \
        crossbuild-essential-armel    \
        crossbuild-essential-armhf    \
        crossbuild-essential-mipsel   \
        crossbuild-essential-powerpc  \
        crossbuild-essential-ppc64el  \
        crossbuild-essential-s390x    \
        curl                          \
        git                           \
        git-core                      \
        libssl-dev                    \
        llvm                          \
        mercurial                     \
        mingw-w64                     \
        openssl                       \
        patch                         \
        qemu-user-static              \
        software-properties-common    \
        subversion                    \
        sudo                          \
        wget                          \
        xz-utils                      \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Backports repo required to get a libsystemd version 246 or newer which is required to handle journal +ZSTD compression
RUN echo "deb http://deb.debian.org/debian buster-backports main" >> /etc/apt/sources.list
RUN  apt-get update \
  && apt-get install -t buster-backports -qy libsystemd-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

#
# OSX
#

ENV OSXCROSS_PATH=/usr/osxcross
COPY --from=osxcross $OSXCROSS_PATH $OSXCROSS_PATH
ENV PATH $OSXCROSS_PATH/bin:$PATH

#
# Go
#

ENV GOLANG_VERSION 1.16
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 013a489ebb3e24ef3d915abe5b94c3286c070dfe0818d5bca8108f1d6e8440d2

RUN  curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz             \
  && echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
  && tar -C /usr/local -xzf golang.tar.gz                           \
  && rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH:/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

#
# FreeBSD
#

COPY assets/freebsd-amd64-11.3.tar.xz /usr/freebsd/freebsd-amd64.tar.xz
COPY assets/freebsd-i386-11.3.tar.xz /usr/freebsd/freebsd-i386.tar.xz

RUN  mkdir /usr/freebsd/x86_64-pc-freebsd11 \
  && cd /usr/freebsd/x86_64-pc-freebsd11 \
  && tar -xf /usr/freebsd/freebsd-amd64.tar.xz ./lib ./usr/lib ./usr/include \
  && rm /usr/freebsd/freebsd-amd64.tar.xz \
  \
  && mkdir /usr/freebsd/i386-pc-freebsd11 \
  && cd /usr/freebsd/i386-pc-freebsd11 \
  && tar -xf /usr/freebsd/freebsd-i386.tar.xz ./lib ./usr/lib ./usr/include \
  && rm /usr/freebsd/freebsd-i386.tar.xz

#
# Final
#
WORKDIR $GOPATH

COPY rootfs/go_wrapper.sh /
COPY rootfs/seegocc.sh /bin/seegocc
RUN chmod +x /go_wrapper.sh && chmod +x /bin/seegocc
ENTRYPOINT ["/go_wrapper.sh"]
