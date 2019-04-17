# nosu-kernel
Build scripts for NOSU Linux Kernel

### Prerequisites
- docker
- docker-compose

### Usage

* Clone this repo: `git clone https://github.com/switchdev-nos/nosu-kernel`
* `cd nosu-kernel`
* `docker-compose --build nosu-kernel`
* `docker-compose run --rm nosu-kernel`
* NOSU Linux Kernel packages are ready: `ls ./debs`
