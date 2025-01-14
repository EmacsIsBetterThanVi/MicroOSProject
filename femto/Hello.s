	bits 16
	org 0
	mov bl, 0
	mov cl, 3
	int 2Eh
	mov bx, MSG
	int 27h
	int 32h
end:	
	jmp end
MSG:	db "Welcome to FEMTOS: Fully Extensible Micro Terminal Operating System", 10, "This is currently incomplete, however development will most likly continue and  can be tracked at https://github.com/EmacsIsBetterThanVi/MicroOSProject." , 10, 0
