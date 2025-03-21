	org 0
	bits 16
	mov di, 17
	mov si, 1
	push cs
	pop es
	mov bx, buffer
	int 22h
	int 32h
buffer:	db "THIS IS A TEST BUFFER FOR FILE WRITING. IF THIS IS ON THE DISK TWICE, THEN THE PROGRAM WORKS"
	times 512 db 0
