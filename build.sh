#!/bin/bash

BUILDDIR="./build"
DEBSDIR="./debs"
ROOTDIR="$PWD"

fail() {
  [ -n "$1" ] && echo $1
  exit 1
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo "Usage: $0 [ENV_FILE]"
  exit 0
fi

if [ -n "$1" ]; then
  if [ -r "$1" ]; then
    set -a
    . "$1"
    set +a
  else
    fail "ENV_FILE not readable or missing"
  fi
fi

[ -n "$KERNEL_VERSION" ] || fail "KERNEL_VERSION is not set"

if [ "$CLEAN" = true ] && [ -d "$BUILDDIR" ]; then
  echo "== Cleaning kernel build  directory"
  rm -fr "$BUILDDIR"
fi

KERNEL_BUILDDIR="$BUILDDIR"/linux-"$KERNEL_VERSION"

if [ -n "$KERNEL_SNAPSHOT" ] && [ ! -d "$KERNEL_BUILDDIR" ]; then
  mkdir -p "$KERNEL_BUILDDIR"
  echo "== Downloading kernel snapshot: $KERNEL_SNAPSHOT"
  curl "$KERNEL_SNAPSHOT" | tar -xz -C "$BUILDDIR"
  [[ $? == 0 ]] || fail "Kernel snapshot downloading failed"
fi

if [ -n "$KERNEL_UBUNTU_PPA" ]; then
  mkdir -p "$KERNEL_PATCHDIR"
  echo "== Loading Ubuntu patches into $KERNEL_PATCHDIR"
  for file in $(curl -s "$KERNEL_UBUNTU_PPA/SOURCES" | grep ".patch"); do
    echo "==== $file"
    curl -s -o "$KERNEL_PATCHDIR/$file" "$KERNEL_UBUNTU_PPA/$file"
  done
fi

if [ -d "$KERNEL_PATCHDIR" ]; then
  echo "== Applying patches from $KERNEL_PATCHDIR..."
  find "$ROOTDIR/$KERNEL_PATCHDIR" -name "*.patch" -print0 | sort -zn | xargs -0 -I '{}' patch -d "$KERNEL_BUILDDIR" -t -N -p1 -i {}
  echo "== Kernel patched."
fi

if [ -n "$KERNEL_CONFIG" ]; then
  cp -f "$KERNEL_CONFIG" "$KERNEL_BUILDDIR"/.config
else
  fail "KERNEL_CONFIG is not set"
fi

echo "== Building kernel $KERNEL_VERSION"
cd "$KERNEL_BUILDDIR"
yes '' | make oldconfig
if [ "$CLEAN" = true ]; then
  make -j`nproc` deb-pkg LOCALVERSION=-"$KERNEL_LOCALVER"
else
  make -j`nproc` bindeb-pkg LOCALVERSION=-"$KERNEL_LOCALVER"
fi

[[ $? == 0 ]] ||  fail "Kernel build failed"

cd "$ROOTDIR"
mv "$BUILDDIR"/*.deb "$DEBSDIR"/
echo "== Kernel successfully built! DEB files moved to $DEBSDIR"
