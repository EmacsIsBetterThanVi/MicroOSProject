# BSOS
Boot Sector OS(BSOS) is a open source operating system writen in NASM designed to fit in the boot sector.
BSOS is writen for x86-16, and is 349 bytes total, however there are some extensions which can be enabled to increase usabilty by passing -dNAME to the disk image builder.
At BSOS's minimum settings it uses 276 bytes, however it requieres additional files for buffer interactions.
# Extensions
Extensions are activated by passing -dNAME where NAME is one of the following.\
BUFFERCONTROLS      Adds the bf command, which advances the buffer pointer forward by 16 bytes, and bb, which moves the buffe pointer back by 16 bytes\
BIGFS               Expands the file system to containe additional sectors, extending the file command proccessor to take two letters for the name insted of one(Untested)\
LARGEFILES          Adds a sector count to the end of the file command, which is how many 512 byte blocks the system will read and write(Untested)\
NOBUFFER            Disables buffer commands, allowing more space for other extensions\
EXECFILE            Adds the fe? command, which loads and executes a file\
AUTOEXTEND          Requires EXECFILE, automatical loads the file in A and executes it.
# Commands
A ? represents a passed byte for data, a * represents any number of pased bytes for data.\
fw?                 Writes the buffer to a sector(? represents a character which's ascii code is 64 greater than the block)\
f ?                 Loads a sector to the buffer(? represents a character which's ascii code is 64 greater than the block)\
e                   Executes the machine code loaded in the buffer\
bw*                 Writes the data to the buffer at BUFFERPOS, incrementing BUFFERPOS by one for each character\
bp                  Prints the BUFFER\
br                  Resets BUFFERPOS to zero
# Instalation instuctions
run ./BSOS.sh build [size]
then flash the resulting image to a disk, or run ./BSOS.sh run to execute it in qemu
# Credits
http://sebastianmihai.com/snowdrop/src for some pieces of code.
