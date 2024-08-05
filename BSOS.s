; BSOS: Boot Sector Operating System
; BSOS is an open source OS writing in NASM for x86_16
; disigned to fit entirly in the MBR
	bits 16
	org 7C00h
jmp BSOS ; skip our data segement
times $$ + 3 - $ nop		; padding for security
BOOTDISK:	db 0
BOOTSTR: db 0ah, 0dh, "BSOS>", 0
VERSION:	db VERSIONNUM, 0
CMDNOTFOUNDSTR:	 db "?", 0
;COLOR:	db 04h			; Color for output
SECTORCOUNT:	db 0
BSPT:	dw 18
pBH:	dw 2
BUFFERPOS:	dw 0
%ifdef AUTOEXTEND
%ifdef BIGFS
%ifdef LARGEFILES
CMD:	"fe@A1" times 11 db 0
%else
CMD:	"fe@A" times 12 db 0
%endif
%else
%ifdef LARGEFILES
CMD:	"feA1" times 12 db 0
%else
CMD:	"feA" times 13 db 0
%endif
%endif
%else
CMD:	times 16 db 0
%endif
STACK equ 1000h
BUFFER equ 1000h
BSOS:
	cld
	push cs
	pop ds
	mov byte [BOOTDISK], dl	; Save what disk this is, required to boot
	cli
	mov ax, STACK 		; move the stack
	mov ss, ax		; unsafe operation, so we prevent interupts
	xor sp, sp		; reset the stack pointer
	mov word [84h], 0h
	mov word [86h], RDISK
	mov word [88h], 0h
	mov word [8Ah], WDISK
	mov word [8Ch], 0h
	mov word [8Eh], OUT
	sti
	mov ax, BUFFER
	mov es, ax
	mov si, VERSION
	call OUT
 	%ifdef EXECFILE
 	%ifdef AUTOEXTEND
  	jmp SHELL
  	%endif
   	%endif
.reset:
	mov si, BOOTSTR
	call OUT
	mov si, CMD
.reset_loop:			; wipe the command string
	mov byte [si], 0
	inc si
	cmp si, CMD+15
	jne .reset_loop
	mov si, CMD		; return to start of command buffer
.loop:
	mov ah, 0h
	int 16h
	cmp ah, 1Ch		; execute the command when enter is pressed
	je SHELL
	mov bh, 0h
	mov bl, 07h
	mov ah, 0Eh
	cmp al, 08h
	je .bs
	int 10h
	mov byte [si], al
	inc si
	cmp si, CMD+15		; end command if it exceeds 15 bytes, one byte is required to end the string
	je SHELL
	jmp .loop
.bs:
	cmp si, CMD
	je .loop
	dec si
	int 10h
	mov byte [si], 0
	jmp .loop
	;; Takes a string located in {CMD}
SHELL:
	mov si, CMD
	cmp byte [si], 'f'
	je .file
	cmp byte [si], 'e'
	je .exec
	%ifndef NOBUFFER
	cmp word [si], 'bp'
	je .buffer_p
	cmp word [si], 'bw'
	je .buffer_w
	cmp word [si], 'br'
	je .buffer_r
	%ifdef BUFFERCONTROLS
	cmp word [si], 'bf'
	je .buffer_f
	cmp word [si], 'bb'
	je .buffer_b
	%endif
	%endif
	mov si, CMDNOTFOUNDSTR
	int 23h
	jmp BSOS.reset
.file:
	add si, 2h
	%ifdef BIGFS
	mov ah, [si]
	inc si
	%else
	xor ah, ah
	%endif
	mov al, [si]
	call LOCATE
	%ifdef LARGEFILES
	inc si
	mov al, [cs:si]
	sub al, 48
	mov byte [cs:SECTORCOUNT], al
	%endif
	xor bx, bx
	cmp byte [cs:CMD+1], 'w'
	je .write
	int 21h
 	%ifdef EXECFILE
  	cmp byte [cs:CMD+1], 'e'
   	je .exec
 	%endif
	jmp BSOS.reset
.write:
	int 22h
	jmp BSOS.reset
%ifndef NOBUFFER
.buffer_p:
	mov ax, BUFFER
	push ds
	mov ds, ax
	xor si, si
	int 23h
	pop ds
	jmp BSOS.reset
%ifdef BUFFERCONTROLS
.buffer_f:
	add bx, 16
	mov word [BUFFERPOS], bx
	jmp BSOS.reset
.buffer_b:
	sub bx, 16
	mov word [BUFFERPOS], bx
	jmp BSOS.reset
%endif
.buffer_w:
	mov bx, [BUFFERPOS]
	add si, 2
.BWloop:
	mov al, [cs:si]
	mov [es:bx], al
	inc si
	inc bx
	cmp byte [cs:si], 0
	jne .BWloop
	mov word [BUFFERPOS], bx
	jmp BSOS.reset
.buffer_r:
	;; 	add si, 2
	;; 	call STR2INT
	;; 	mov ah, al
	;; 	call STR2INT
	mov word [BUFFERPOS], 0000h
	jmp BSOS.reset
%endif
.exec:
	mov ah, BOOTDISK
	call BUFFER:0000
	jmp BSOS.reset
	;; GET LOCATION OF FILE PASSED IN {AH AL} to {di} 
LOCATE:
	%ifdef BIGFS
	sub ah, 64
	%endif
	sub al, 64
	ret
	;; WRITE {cs:SECTORCOUNT} SECTORS STARTING AT {ES:BX} TO {DI}
WDISK:
%ifdef LARGEFILES
	push es
	push bx
	mov ax, di
	call GCHS
	mov ah, 3
	mov al, 1
	pop bx
	pop es
	int 13h
	jc .end
	add bx, 512
	inc di
	dec byte [cs:SECTORCOUNT]
	jnz WDISK
	clc
.end:
	popa
	iret
%else
	pusha
	call GCHS
	mov ah, 3
	mov al, 1
	xor bx, bx
	int 13h
	popa
	iret
%endif
	;; READ {SECTORCOUNT} SECTORS STARTING AT {DI} INTO {ES:BX}
RDISK:
	pusha
	call GCHS
	mov ah, 2
	mov al, 1
	int 13h
	popa
%ifdef LARGEFILES
	jc .end
	add bx, 512
	inc di
	dec byte [cs:SECTORCOUNT]
	jnz RDISK
	clc
.end:
%endif
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
	;; Takes a string located in {DS:SI} and outputs it to the console
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
	iret
%if %eval(440 - ($ - $$)) > 0
%warning %eval(440 - ($ - $$)) bytes remaining
%elif %eval(440 - ($ - $$)) < 0
%fatal "OUT OF SPACE"
%else
%warning "no bytes remaining."
%endif
times 440 - ($ - $$) db 0
; Reserved post boot loader bytes
dw 1337h, 1337h
dw 0
	;; Partition entry one for functionality, maybe I don't need this?
db 80h
db 0	
db 1
db 0
db 01h
db 1	
db 18
db 79	
dd 0	
dd 2880
	;; Partition entries, all of which are garbage
db 7Fh
times 15 db 0
db 7Fh
times 15 db 0
db 7Fh
times 15 db 0
; Boot sector ending, IT HAS TO BE THIS WAY
dw 0AA55h
%ifdef EXTEND
%include "EXTEND"
%endif
