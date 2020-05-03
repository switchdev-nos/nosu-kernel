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

[ -n "$NOSU_KERNEL_VERSION" ] || fail "NOSU_KERNEL_VERSION is not set"

if [ "$CLEAN" = true ] && [ -d "$BUILDDIR" ]; then
  echo "== Cleaning kernel build  directory"
  rm -fr "$BUILDDIR"
fi

KERNEL_BUILDDIR="$BUILDDIR"/linux-"$NOSU_KERNEL_VERSION"

if [ -n "$NOSU_KERNEL_SNAPSHOT" ] && [ ! -d "$KERNEL_BUILDDIR" ]; then
  mkdir -p "$KERNEL_BUILDDIR"
  echo "== Downloading kernel snapshot: $NOSU_KERNEL_SNAPSHOT"
  curl "$NOSU_KERNEL_SNAPSHOT" | tar -xz --strip 1 -C "$KERNEL_BUILDDIR"
  [[ $? == 0 ]] || fail "Kernel snapshot downloading failed"
elif [ -n "$NOSU_KERNEL_GIT" ] && [ ! -d "$KERNEL_BUILDDIR" ]; then
  if [ -n "$NOSU_KERNEL_GIT_BRANCH" ]; then
    CLONE="$NOSU_KERNEL_GIT -b $NOSU_KERNEL_GIT_BRANCH $KERNEL_BUILDDIR"
  else
    CLONE="$NOSU_KERNEL_GIT $KERNEL_BUILDDIR"
  fi
  git clone $CLONE
  [[ $? == 0 ]] || fail "Kernel git cloning failed"
fi

if [ -n "$NOSU_KERNEL_UBUNTU_PPA" ]; then
  mkdir -p "$NOSU_KERNEL_PATCHDIR"
  echo "== Loading Ubuntu patches into $NOSU_KERNEL_PATCHDIR"
  for file in $(curl -s "$NOSU_KERNEL_UBUNTU_PPA/SOURCES" | grep ".patch"); do
    echo "==== $file"
    curl -s -o "$NOSU_KERNEL_PATCHDIR/$file" "$NOSU_KERNEL_UBUNTU_PPA/$file"
  done
fi

if [ -d "$NOSU_KERNEL_PATCHDIR" ]; then
  echo "== Applying patches from $NOSU_KERNEL_PATCHDIR..."
  find "$ROOTDIR/$NOSU_KERNEL_PATCHDIR" -name "*.patch" -print0 | sort -zn | xargs -0 -I '{}' patch -d "$KERNEL_BUILDDIR" -t -N -p1 -i {}
  echo "== Kernel patched."
fi

if [ -n "$NOSU_KERNEL_CONFIG" ]; then
  cp -f "$NOSU_KERNEL_CONFIG" "$KERNEL_BUILDDIR"/.config
else
  fail "NOSU_KERNEL_CONFIG is not set"
fi

echo "== Building kernel $NOSU_KERNEL_VERSION"
cd "$KERNEL_BUILDDIR"
yes '' | make oldconfig
scripts/config --disable DEBUG_INFO
if [ "$CLEAN" = true ]; then
  make -j`nproc` deb-pkg LOCALVERSION=-"$NOSU_KERNEL_LOCALVER"
else
  make -j`nproc` bindeb-pkg LOCALVERSION=-"$NOSU_KERNEL_LOCALVER"
fi

[[ $? == 0 ]] ||  fail "Kernel build failed"

cd "$ROOTDIR"
mv -f "$BUILDDIR"/*.deb "$DEBSDIR"/
echo "== Kernel successfully built! DEB files moved to $DEBSDIR"
