FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
RUN apt -yqq update --no-install-recommends >/dev/null && apt build-dep -yqq --no-install-recommends linux-image-generic && apt install -yqq --no-install-recommends ca-certificates curl git patch flex bison dpkg-dev fakeroot libelf-dev bc kmod cpio libelf-dev libssl-dev rsync python3 dwarves && curl -sL -o /tmp/dwarves_1.17-1_amd64.deb  http://archive.ubuntu.com/ubuntu/pool/universe/d/dwarves-dfsg/dwarves_1.17-1_amd64.deb  && dpkg -i /tmp/dwarves_1.17-1_amd64.deb
