	bits 16
	jmp EDIT
times $$ + 3 - $ nop
BSPT:	dw 18
pBH:	dw 2
BOOTDISK:	db 0
FILE:	dw 0
BUFFER equ 1200h
EDIT:
	push cs
	pop ds
	mov byte [BOOTDISK], ah
	mov bx, 512
	push bx
	mov ah, 0h
        int 16h
	sub ah, 64 
        mov al, ah
	xor ah, ah
	mov word [FILE], ax
	call RDISK
	pop bx
.loop:
	pusha
	call CLEAR
	popa
	mov si, 512
	call OUT
	mov ah, 0h
	int 16h
	cmp ah, 4Dh
	je .right
	cmp ah, 50h
	je .quit
	cmp ah, 48h
	je .save
	cmp ah, 4Bh
	je .left
	cmp ah, 0Eh
	je .bs
	mov byte [bx], al
	inc bx
.right:
	inc bx
	jmp .loop
.left:
	dec bx
	jmp .loop
.bs:	
	cmp bx, 512
        je .loop
        dec bx
        int 10h
        mov byte [bx], 0
        jmp .loop
.save:
	push bx
	mov bx, 512
	mov ax, word [FILE]
	call WDISK
	jmp .loop
	pop bx
.quit:
	jmp 0000:7c42h
OUT:
        pusha
        mov ah, 0Eh
        mov bl, 07h
.loop:
        lodsb
        cmp al, 0
        je .end
        int 10h
        je .end
        jmp .loop
.end:
        popa
        ret
CLEAR:
        mov ah, 02h
        mov dx, 0000h
        int 10h
        mov cx, 1920
.loop:
        mov al, 20h
        mov ah, 0Eh
        int 10h
        dec cx
        jnz .loop
        mov ah, 02h
        mov dx, 0000h
        int 10h
        ret
WDISK:
	pusha
        call GCHS
        mov ah, 3
        mov al, 1
        xor bx, bx
        int 13h
        popa
        ret
RDISK:
        pusha
        call GCHS
        mov ah, 2
        mov al, 1
        int 13h
        popa
        ret
GCHS:
        push ax
        xor dx, dx
        div word [BSPT]
        inc dl
        mov cl, dl
        pop ax
        mov dx, 0
        div word [BSPT]
        mov dx, 0
        div word [pBH]
        mov dh, dl
        mov ch, al
        mov dl, byte [BOOTDISK]
        ret
%warning %eval(512 - ($ - $$))
