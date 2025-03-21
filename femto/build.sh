#!/bin/bash
nasm -f bin femto.s -o femto.bin
nasm -f bin root.s -o root.bin
nasm -f bin Hello.s -o Hello.bin
nasm -f bin Clear.s -o Clear.bin
nasm -f bin help.s -o help.bin
nasm -f bin WriteTest.s -o WriteTest.bin
dd bs=512 if=femto.bin count=1 of=femto.img conv=noerror,sync
dd bs=512 if=root.bin of=femto.img oseek=1 conv=noerror,sync
dd bs=512 if=femto.bin of=femto.img oseek=4 iseek=1 conv=noerror,sync
dd bs=512 if=Hello.bin of=femto.img oseek=10 conv=noerror,sync
dd bs=512 if=Clear.bin of=femto.img oseek=11 conv=noerror,sync
dd bs=512 if=help.bin of=femto.img oseek=12 conv=noerror,sync
dd bs=512 if=WriteTest.bin of=femto.img oseek=15 conv=noerror,sync
dd bs=512 if=/dev/zero of=femto.img count=1 oseek=17 conv=noerror,sync
[[ $1 == "qemu" ]] && qemu-system-i386 -machine pc-i440fx-2.10 femto.img
