#!/bin/bash
if [[ $1 == "run" ]]; then
    shift
    qemu-system-x86_64 -drive format=raw,file=BSOS.img,if=floppy,cache=writethrough $@
elif [[ $1 == "chdisk" ]]; then
    echo "BOOT SECTOR"
    dd if=BSOS.img bs=512 count=1 skip=0 | hexdump -C -v
    echo "FILES"
    dd if=BSOS.img bs=512 count=$2 skip=1 | hexdump -C -v
elif [[ $tmp == "build" ]]; then
    size=$2
    shift 2
    nasm -f bin BSOS.s -dVERSIONNUM=\"$(cat VERSION.txt)\" $@
	hdiutil create -sectors 40 -fs "MS-DOS FAT12" -volname "BSOS" -nospotlight ~/BSOS.img
	mv BSOS.img.dmg BSOS.img
	dd if=~/BSOS of=BSOS.img bs=512 count=1 seek=0
	dd if=/dev/zero of=BSOS.img bs=512 count=$size oseek=1
else
    echo "./BSOS.sh [run|chdisk|build]"
    echo "chdisk [size]"
    echo "build [size] [options]"
fi
