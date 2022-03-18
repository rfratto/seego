#!/usr/bin/env bash

# This script is installed as /bin/seegocc and can be used as a Cgo-aware
# gcc/clang. Set CC=seegocc in the container to use.

FOUND_CC=""
FOUND_LD_PATH=""
CC_EXTRA=""

CGO_ENABLED=${CGO_ENABLED:-$(go env CGO_ENABLED)}
GOARCH=$(go env GOARCH)
GOOS=$(go env GOOS)
GOARM=$(go env GOARM)

main() {
  case "$GOOS" in
    linux)   configure_linux   ;;
    darwin)  configure_darwin  ;;
    freebsd) configure_bsd     ;;
    windows) configure_windows ;;
    *)
      echo "fatal: unsupported GOOS value $GOOS" >&2
      exit 1
  esac

  if [ ! -z "$FOUND_LD_PATH" ]; then
    export LD_LIBRARY_PATH="$FOUND_LD_PATH:$LD_LIBRARY_PATH"
  fi
  exec "$FOUND_CC" "$CC_EXTRA $@"
}

configure_linux() {
  toolchain_prefix=""

  case "$GOARCH" in
    # Do nothing for native archs
    amd64 | 386) ;;

    arm)      toolchain_prefix="arm-linux-gnueabi-" ;;
    arm64)    toolchain_prefix="aarch64-linux-gnu-" ;;

    ppc64)    toolchain_prefix="powerpc-linux-gnu-"     ;;
    ppc64le)  toolchain_prefix="powerpc64le-linux-gnu-" ;;

    mips)     toolchain_prefix="mips-linux-gnu-"          ;;
    mipsle)   toolchain_prefix="mipsel-linux-gnu-"        ;;
    mips64)   toolchain_prefix="mips64-linux-gnuabi64-"   ;;
    mips64le) toolchain_prefix="mips64el-linux-gnuabi64-" ;;

    s390x)    toolchain_prefix="s390x-linux-gnu-" ;;

    *)
      echo "fatal: unsupported linux GOARCH value $GOARCH" >&2
      echo "supported values: amd64, 386, arm, arm64, ppc64, ppc64le, mips, mipsle, mips64, mips64le, s390x" >&2
      exit 1
  esac

  if [ "$GOARCH" == "arm" ] && [ "$GOARM" == "7" ]; then
    toolchain_prefix="arm-linux-gnueabihf-"
  fi

  FOUND_CC="${toolchain_prefix}gcc"
}

configure_darwin() {
  case "$GOARCH" in
    amd64)
      FOUND_CC="x86_64-apple-darwin20.2-clang"
      FOUND_LD_PATH="$OSXCROSS_PATH/lib"
      ;;
    arm64)
      FOUND_CC="arm64-apple-darwin20.2-clang"
      FOUND_LD_PATH="$OSXCROSS_PATH/lib"
      ;;
    *)
      echo "fatal: unsupported darwin GOARCH value $GOARCH" >&2
      echo "supported values: amd64, arm64" >&2
      exit 1
  esac
}

configure_bsd() {
  case "$GOARCH" in
    amd64)
      FOUND_CC="clang"
      CC_EXTRA="-target x86_64-pc-freebsd11 --sysroot=/usr/freebsd/x86_64-pc-freebsd11"
      ;;
    386)
      FOUND_CC="clang"
      CC_EXTRA="-target i386-pc-freebsd11 --sysroot=/usr/freebsd/i386-pc-freebsd11 -v"
      ;;

    *)
      echo "fatal: unsupported bsd GOARCH value $GOARCH" >&2
      echo "supported values: amd64, 386" >&2
      exit 1
  esac
}

configure_windows() {
  case "$GOARCH" in
    386)
      FOUND_CC="i686-w64-mingw32-gcc"
      ;;
    amd64)
      FOUND_CC="x86_64-w64-mingw32-gcc"
      ;;

    *)
      echo "fatal: unsupported windows GOARCH value $GOARCH" >&2
      echo "supported values: 386, amd64" >&2
      exit 1
  esac
}

main "$@"
