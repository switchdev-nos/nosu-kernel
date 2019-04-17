FROM ubuntu:bionic

RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
RUN apt -yqq update --no-install-recommends >/dev/null
RUN apt build-dep -yqq linux-image-generic
RUN apt install -yqq curl patch flex bison dpkg-dev fakeroot libelf-dev bc kmod cpio libelf-dev libssl-dev