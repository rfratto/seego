FROM debian:stable as osxcross

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
    OSXCROSS_REV=748108aec4e3ceb672990df8164a11b0ac6084f7 \
    SDK_VERSION=10.15
RUN  mkdir -p /tmp/osxcross && cd /tmp/osxcross                                           \
  && curl -sSL "https://codeload.github.com/tpoechtrager/osxcross/tar.gz/${OSXCROSS_REV}" \
      | tar -C /tmp/osxcross --strip=1 -xzf -                                             \
  && curl -sSLo tarballs/MacOSX${SDK_VERSION}.sdk.tar.xz ${OSXCROSS_SDK_URL}              \
  && UNATTENDED=yes ./build.sh                                                            \
  && mv target "${OSXCROSS_PATH}"                                                         \
  && rm -rf /tmp/osxcross "/usr/osxcross/SDK/MacOSX${SDK_VERSION}.sdk/usr/share/man"

FROM debian:stable
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

#
# OSX
#

ENV OSXCROSS_PATH=/usr/osxcross
COPY --from=osxcross $OSXCROSS_PATH $OSXCROSS_PATH
ENV PATH $OSXCROSS_PATH/bin:$PATH

#
# Go
#

ENV GOLANG_VERSION 1.14.4
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 aed845e4185a0b2a3c3d5e1d0a35491702c55889192bb9c30e67a3de6849c067

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
RUN chmod +x /go_wrapper.sh
ENTRYPOINT ["/go_wrapper.sh"]
