#!/bin/bash
nasm -f bin femto.s -o femto.bin
nasm -f bin root.s -o root.bin
nasm -f bin Hello.s -o Hello.bin
nasm -f bin Clear.s -o Clear.bin
nasm -f bin help.s -o help.bin
dd bs=512 if=femto.bin count=1 of=femto.img conv=noerror,sync
dd bs=512 if=root.bin of=femto.img oseek=1 conv=noerror,sync
dd bs=512 if=femto.bin of=femto.img oseek=2 iseek=1 conv=noerror,sync
dd bs=512 if=Hello.bin of=femto.img oseek=6 conv=noerror,sync
dd bs=512 if=Clear.bin of=femto.img oseek=7 conv=noerror,sync
dd bs=512 if=help.bin of=femto.img oseek=8 conv=noerror,sync
[[ $1 == "qemu" ]] && qemu-system-i386 -machine pc-i440fx-2.10 femto.img
