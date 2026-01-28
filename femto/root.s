; ROOT DIRECTORY ENTRIES
db "/"
times %eval(25 - %strlen("/")) db 0 ; The extra root directory entries, the sector after this is the free chain
db 02h
dw 0002h
db 00100000b 	; A directory
times 3 db 0
db "femto"
times %eval(25 - %strlen("femto")) db 0 ; stop string
db 08h ; SIZE
dw 0005h ; LOCATION
db 00000000b ; PERMISIONS, NONE FOR KERNEL, and unused by femto except for the directory flag anyways
times 3 db 0; Extra Data, NONE FOR KERNEL, and unused by femto anyways
db "welcome"
times %eval(25 - %strlen("Welcome")) db 0
db 1
dw 14
db 0
times 3 db 0
db "clear"
times %eval(25 - %strlen("Clear")) db 0
db 1	
dw 15
db 0
times 3 db 0
db "help"
times %eval(25 - %strlen("help")) db 0
db 3	
dw 16
db 0	
times 3 db 0
%warning %eval(($ - $$)/32)/16 files used
times 1536 - ($ - $$) db 0 ; ends the file, ensures it is exactly three sectors
db 0xFF			   ; The free table is fairly simple, a one in a location means that sector is filled, a zero means it is empty
db 0xFF			   ; The bits are aranged with the lowest bit representing the lowest sector
db 0b00000111	
times 2048 - ($ - $$) db 0 ; ends the free table and ensures it is exactly one sector
