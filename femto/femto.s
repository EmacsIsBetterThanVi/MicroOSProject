	bits 16
	org 7C00h
	jmp BOOT
	times $$ + 3 - $ nop
INPUT_BUFFER:	times 32 db 0
IWHEAD:	db 0
IRHEAD:	db 0
Char:	db 0, 0
	;; DISK CONFIG
DISK:	db 0
BSPT:	dw 18
pBH:	dw 2
DIR:	dw 50h
KernelFile:	db "femto", 0
SRC:	db 0
SysFlags:	db 0	; 00000,Shift,Ctrl,Alt
	;; VGA CONFIG
VGA_BASE:	dw 0B000h
VAddr:		dw 0
Color:		db 03h
COLS:		db 160
	;; BOOT STRINGS
BootLRD:	db "Loaded Root Directory", 10,0
BootLKF:	db "Loaded Kernel file", 10,0
BOOT:
	cld
	push cs
	pop ds
	mov byte [DISK], dl
	cli
	mov ax, 1000h
	mov ss, ax
	xor sp, sp
	sti
ConfigDisplay:
	mov cx, 2706h
	mov ah, 1
	int 10h
	mov al, 0
	mov ah, 05
	int 10h
	mov ax, [410h]
	and ax, 30h
	cmp ax, 20h
	jne ConfigKeyboard
	mov word [VGA_BASE], 0B800h
LoadRootDirectory:
	push word [DIR]
	pop es	 		; ROOTDIRECTORY START
	push word [ROOT]
	xor bx, bx
	pop di
	mov si, 1
	call READSECTORS	; Load the root directory
	mov bx, BootLRD
	call print
LoadKernelFile:			; The kernel is loaded right after the MBR entries
	;; 	mov si, KernelFile
	;; 	call LOCATE
	mov ax, 7E0h
	mov es, ax
	xor bx, bx
	mov di, 2
	mov si, 1
	call READSECTORS
	mov bx, BootLKF
	call print
	jmp KernelPart2
	;; Interupts:
	;; 	0x21: Read File		; Takes file start in di, length in al, and
	;; 				a buffer in es:bx
	;; 	0x22: Write File	; Same as 0x21
	;; 	0x23: Create File	; Takes a name in ds:bx, permisions in ax,
	;; 				and a buffer in es:si
	;; 	0x24: Delete File	; Takes a file name in ds:bx
	;; 	0x25: Execute File	; Takes a file name in ds:bx
	;; 	0x26: Open File 	; Takes a file name in ds:si, and sets di to
	;; 		the file start block, and si to the length of the file
	;; 	0x27: Output ds:bx to console
	;; 	0x28: Allocate ax bytes of RAM, pointer returned in es:bx
	;; 	0x29: Free pointer es:bx
	;; 	0x2A: Set directory to es:bx
	;; 	0x2B: Return to root directory
	;; 	0x2C: Switch to drive al
	;; 	0x2D: Change the color of the console to al
	;;
	;; Signals:
	;; 	EXIT: Raised by CTRL+C	Quits program
	;; 	TERMinate: Rasied by CTRL+X Force quits program
	;; 	PAUSe: Raised by CTRL+Z  Sets a program resume vector and pauses
	;; 	CONTinue: Raised by CTRL+{number key N}, set by CTRL+Z
	;; 
;; Helper functions/interupts
	;;  femto ignores the EXTRA DATA section, the EXECUTABLE permision, and
	;;  the low four bits of the permisions byte

	;; TODO: Fix Locate
LOCATE:
    push ax
    push bx
    push cx
    push dx
    push es
    mov ax, [DIR]
    mov es, ax
    mov bx, 0FFDFh
.next:
    mov si, 0
    add bx, 32
    mov di, bx
.loop:
    mov al, [ds:si]
    cmp al, 0
    je .end
    cmp al, [es:di]
    jne .next
    inc si
    inc di
    jmp .loop
.end:
    mov di, bx
    add di, 25
    mov al, [es:di]
    mov si, ax
    and si, 0FFh	
    inc di
    mov ah, byte [es:di]
    inc di
    mov al, byte [es:di]
    mov di, ax
    pop es
    pop dx
    pop cx
    pop bx
    pop ax	
    ret
	;; Read {al} sectors starting at {di} into {es:bx}
READSECTORS:
	;; 	mov byte [cs:SRC], al
.start:
    pusha
    push es
    mov ax, di	
    call LBA_to_CHS
    mov ah, 2
    mov al, 1	
    int 13h
    pop es
    popa
    jc .end
    add bx, 512
    inc di
    dec si
    jnz .start
    clc
.end:
	ret
LBA_to_CHS:
    push ax
    xor dx, dx
    div word [BSPT]
    inc dl
    mov cl, dl
    pop ax
    xor dx, dx
    div word [BSPT]
    xor dx, dx
    div word [pBH]
    mov dh, dl
    mov ch, al
    mov dl, byte [DISK]
    ret
	;; Prints {ds:bx} to the console in {color}
print:
	pusha
	push es
	mov ax, [cs:VGA_BASE]
	mov es, ax
	mov di, [cs:VAddr]
	mov dl, [cs:Color]
.loop:
	mov al, [ds:bx]
	cmp al, 10
	je .newline
	cmp al, 13
	je .cr
	cmp al, 0
	je .end
	mov byte [es:di], al
	inc di
	mov byte [es:di], dl
	inc di
	inc bx
	jmp .loop
.newline:
	add di, 160
.cr:
	mov ax, di
	div byte [cs:COLS]
	mul byte [cs:COLS]
	mov di, ax
	inc bx
	jmp .loop
.scroll:
	mov bx, 160
	push di
	mov di, 0
.scroll_loop:
	mov al, [es:bx]
	inc bx
	mov [es:di], al
	inc di
	cmp di, 4000
	jle .scroll_loop
	pop di
	sub di, 160
.end:
	cmp di, 4000
	jg .scroll
	mov word [cs:VAddr], di
	pop es
	popa
	ret
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
	;; Partition entry one.
db 80h
db 0	
db 1
db 0
db 31h
db 1	
db 18
db 79
ROOT:	dd 1
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
Version:	db "Femto 0.1", 10, 0
Prompt:	db "FEMTO>", 0	
KernelPart2:
	mov bx, Version
	call print
ConfigKeyboard:
	mov al, 0xAD
	out 64h, al
	in al, 60h
	mov al, 20h
	out 64h, al
	in al, 60h
	and al, 0b01111100
	or al, 1
	mov ah, al
	mov al, 60h
	out 64h, al
	mov al, ah
	out 60h, al
	mov al, 0xAE
	out 64h, al
SetupInterupts:
	push cs
	pop es
	mov al, 27h
	mov dx, PrintInt
	call CreateInterupt
	mov al, 9
	mov dx, KeyPressInt
	;; 	call CreateInterupt
CLI:
	mov bx, Prompt
	call print
.prompt:
	mov ah, 0
	int 16h
	cmp ah, 1Ch
	je .exec
	cmp al, 8
	je .bs
	mov byte [Char], al
	mov bx, Char
	call print
	jmp .prompt
.exec:
	mov byte [Char], 10
	mov bx, Char
	int 27h
	jmp CLI
.bs:
	sub word [VAddr], 2
	mov byte [Char], " "
	mov bx, Char
	call print
	sub word [VAddr], 2
	jmp .prompt
	;; Sets interupt al to address es:dx
CreateInterupt:
	cli
	push es
	push word 0h
	pop es
	pop cx
	push cx
	mov ah, 0
	shl ax, 2
	mov bx, ax
	mov word [es:bx], cx
	add bx, 2
	mov word [es:bx], dx
	pop es
	sti
	ret
ColorCHangeInt:	
	mov byte [cs:Color], al
	iret
PrintInt:
	call print
	iret
	;; Keyboard data:
SCAN: db 0x1c, 0x32, 0x21, 0x23, 0x24, 0x2B, 0x34, 0x33, 0x43, 0x3B, 0x42, 0x4B, 0x3A, 0x31, 0x44, 0x4D, 0x15, 0x2D, 0x1B, 0x2C, 0x3C, 0x2A, 0x1D, 0x22, 0x35, 0x1A, 0x16, 0x1E, 0x26, 0x25, 0x2E, 0x36, 0x3D, 0x3E, 0x46, 0x45, 0x4E, 0x55, 0x4A, 0x49, 0x41, 0x4C, 0x52, 0x54, 0x5B, 0x5D, 0x0E, 0x29, 0x5A, 0
LOWER:	db "abcdefghijklmnopqrstuvwxyz1234567890-=/.,;'[]\` ", 10
UPPER:	db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+?><:"{}|~ ', 10
	;;" Converts the scan code {ah} to the ascii char {al}, upercase if 
ScanCodeToChar:	
	push bx
	mov bx, SCAN
.loop:
	cmp ah, 0
	je .null
	cmp ah, [cs:bx]
	je .end
	inc bx
	jmp .loop
.end:
	sub bx, SCAN
	mov al, [cs:SysFlags]
	and al, 0b100
	cmp al, 0b100
	je .UP
	add bx, LOWER
	mov al, [cs:bx]
	pop bx
	ret
.UP:
	add bx, UPPER
	mov al, [cs:bx]
	pop bx
	ret
.null:
	mov al, ah
	ret
KeyPressInt:
	pusha
	in al, 60h
	mov ah, al
	call ScanCodeToChar
	mov bx, INPUT_BUFFER
	add bl, [cs:IWHEAD]
	mov byte [cs:bx], al
	inc byte [cs:IWHEAD]
	cmp byte [cs:IWHEAD], 32
	je .reset
.end:
	mov al,20h
	out 20h,al
	popa
	iret
.reset:
	mov byte [cs:IWHEAD], 0
	jmp .end
ReadInput:
	push bx
	mov bx, INPUT_BUFFER
	add bl, [cs:IRHEAD]
	mov al, [cs:bx]
	inc byte [cs:IRHEAD]
	cmp byte [cs:IRHEAD], 32
	je .reset
	pop bx
	ret
.reset:
	mov byte [cs:IRHEAD], 0
	pop bx
	ret
