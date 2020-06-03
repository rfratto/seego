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
  && apt-get update                   \
  && apt-get install -yq              \
        autoconf                      \
        automake                      \
        autotools-dev                 \
        bc                            \
        binfmt-support                \
        binutils-multiarch            \
        binutils-multiarch-dev        \
        build-essential               \
        bzr                           \
        clang                         \
        cmake                         \
        crossbuild-essential-arm64    \
        crossbuild-essential-armel    \
        crossbuild-essential-armhf    \
        crossbuild-essential-mipsel   \
        crossbuild-essential-powerpc  \
        crossbuild-essential-ppc64el  \
        curl                          \
        devscripts                    \
        gdb                           \
        git                           \
        git-core                      \
        gnupg                         \
        libsnmp-dev                   \
        libssl-dev                    \
        libtool                       \
        libxml2-dev                   \
        llvm                          \
        lzma-dev                      \
        make                          \
        mercurial                     \
        mingw-w64                     \
        multistrap                    \
        openssl                       \
        patch                         \
        qemu-user-static              \
        software-properties-common    \
        subversion                    \
        wget                          \
        xz-utils                      \
  && apt-get clean

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

ENV PATH $OSXCROSS_PATH/bin:$PATH
ENV LD_LIBRARY_PATH $OSXCROSS_PATH/lib:$LD_LIBRARY_PATH

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
WORKDIR $GOPATH

COPY rootfs/go_wrapper.sh /
RUN chmod +x /go_wrapper.sh
ENTRYPOINT ["/go_wrapper.sh"]
