## Installation

1. Clone the [Linux source](https://github.com/torvalds/linux) to the `linux` directory
2. Clone the [BusyBox](https://github.com/mirror/busybox) source to the `busybox` directory

## Build

### All

```sh
make clean
make build
```

## Usage

### Run qemu 

```sh
make qemu
```

### Debug

NOTE: This starts gdb in singlestep mode

```sh
make qemu-gdb
```

```sh
make gdb
```
