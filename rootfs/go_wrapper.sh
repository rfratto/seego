#!/usr/bin/env bash

FOUND_CC=""
FOUND_CXX=""

GOARCH=$(go env GOARCH)
GOOS=$(go env GOOS)
GOARM=$(go env GOARM)

main() {
  echo ">>> discovering toolchain for GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM}"

  case "$GOOS" in
    linux)   configure_linux   ;;
    darwin)  configure_darwin  ;;
    freebsd) conigure_bsd      ;;
    netbsd)  configure_bsd     ;;
    windows) configure_windows ;;
    *)
      echo ">>> ERROR: unsupported GOOS value $GOOS"
      exit 1
  esac

  echo ">>> discovered CC ${FOUND_CC}"
  echo ">>> discovered CXX ${FOUND_CXX}"

  echo ">>> CGO_ENABLED=1 CC=$FOUND_CC CXX=$FOUND_CXX go $@"
  CGO_ENABLED=1 CC=$FOUND_CC CXX=${FOUND_CXX} go "$@"
}

configure_linux() {
  toolchain_prefix=""

  case "$GOARCH" in
    # Do nothing for native archs
    amd64 | 386) ;;

    arm)   toolchain_prefix="arm-linux-gnueabi-" ;;
    arm64) toolchain_prefix="aarch64-linux-gnu-" ;;

    ppc64)   toolchain_prefix="powerpc-linux-gnu-"     ;;
    ppc64le) toolchain_prefix="powerpc64le-linux-gnu-" ;;

    mips)    toolchain_prefix="mips-linux-gnu-"          ;;
    mipsle)  toolchain_prefix="mipsel-linux-gnu-"        ;;
    mips64)  toolchain_prefix="mips64-linux-gnuabi64-"   ;;
    mips64le) toolchain_prefix="mips64el-linux-gnuabi64-" ;;

    *)
      echo ">>> ERROR: unsupported linux GOARCH value $GOARCH"
      echo ">>> supported values: amd64, 386, arm, arm64, ppc64, ppc64le, mips, mipsle, mips64, mips64le"
      exit 1
  esac

  if [ "$GOARCH" == "arm" ] && [ "$GOARM" == "7" ]; then
    toolchain_prefix="arm-linux-gnueabihf-"
  fi

  FOUND_CC="${toolchain_prefix}-gcc"
  FOUND_CXX="${toolchain_prefix}-g++"
}

configure_darwin() {
  case "$GOARCH" in
    amd64)
      FOUND_CC="x86_64-apple-darwin19-clang"
      FOUND_CXX="x86_64-apple-darwin19-clang++"
      ;;
    *)
      echo ">>> ERROR: unsupported darwin GOARCH value $GOARCH"
      echo ">>> supported values: amd64"
      exit 1
  esac
}

configure_bsd() {
  toolchain_prefix=""

  case "$GOARCH" in
    # Do nothing for native archs
    amd64 | 386) ;;

    arm)   toolchain_prefix="arm-linux-gnueabi-" ;;
    arm64) toolchain_prefix="aarch64-linux-gnu-" ;;

    *)
      echo ">>> ERROR: unsupported bsd GOARCH value $GOARCH"
      echo ">>> supported values: amd64, 386, arm, arm64"
      exit 1
  esac

  if [ "$GOARCH" == "arm" ] && [ "$GOARM" == "7" ]; then
    toolchain_prefix="arm-linux-gnueabihf-"
  fi

  FOUND_CC="${toolchain_prefix}-gcc"
  FOUND_CXX="${toolchain_prefix}-g++"
}

configure_windows() {
  case "$GOARCH" in
    386)
      FOUND_CC="i686-w64-mingw32-gcc"
      FOUND_CXX="i686-w64-mingw32-g++"
      ;;
    amd64)
      FOUND_CC="x86_64-w64-mingw32-gcc"
      FOUND_CXX="x86_64-w64-mingw32-g++"
      ;;

    *)
      echo ">>> ERROR: unsupported windows GOARCH value $GOARCH"
      echo ">>> supported values: 386, amd64"
      exit 1
  esac
}

main "$@"
