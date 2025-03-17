; ROOT DIRECTORY ENTRIES
db "root/"
times $eval(25 - %strlen("/")) db 0
db 00h
dw 0002h
db 00100000b 	; A directory
times 3 db 0
db "femto"
times %eval(25 - %strlen("femto")) db 0 ; stop string
db 04h ; SIZE
dw 0004h ; LOCATION, TEMPROARY
db 00000000b ; PERMISIONS, NONE FOR KERNEL
times 3 db 0; Extra Data, NONE FOR KERNEL
db "welcome"
times %eval(25 - %strlen("Welcome")) db 0
db 1
dw 10
db 0
times 3 db 0
db "clear"
times %eval(25 - %strlen("Clear")) db 0
db 1	
dw 11
db 0
times 3 db 0
db "help"
times %eval(25 - %strlen("help")) db 0
db 3	
dw 12
db 0
times 3 db 0
times 512 - ($ - $$) db 0 ; ends the file, ensures it is exactly one sector
