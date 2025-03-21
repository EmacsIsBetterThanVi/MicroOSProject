	bits 16
	push word 0h
	pop ds
	mov word [7c1eh], 0h
	mov bx, 0h
	push word [7c1ch]
	pop ds
ClearLoop:
	mov word [ds:bx], 0h
	inc bx
	cmp bx, 4000h
	jng ClearLoop
	int 32h
