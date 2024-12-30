; ROOT DIRECTORY ENTRIES
times 32 db 0 ; Empty for now, probobly bin?
db "femto"
times %eval(25 - %strlen("femto")) db 0 ; stop string
db 01h ; SIZE
dw 0002h ; LOCATION, TEMPROARY
db 00000000b ; PERMISIONS, NONE FOR KERNEL
times 3 db 0; Extra Data, NONE FOR KERNEL
times 512 - ($ - $$) db 0 ; ends the file, ensures it is exactly one sector
