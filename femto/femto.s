	bits 16
	org 7C00h
	jmp BOOT
	times $$ + 3 - $ nop
IWHEAD:	db 0
IRHEAD:	db 0
DLEN:	dw 512
CDSTART:dw 0
INT9_SEG:	dw 0
INT9_OFF:	dw 0
	;; DISK CONFIG
DISK:	db 0
BSPT:	dw 18
pBH:	dw 2
DIR:	dw 50h
KernelFile:	db "femto", 0
SysFlags:	dw 32	; 00000000-NonBlocking,FileNotFound,SIG,INVERT,Printchar,Shift,Ctrl,Alt
	;; VGA CONFIG
VGA_BASE:	dw 0B000h
VAddr:		dw 0
Color:		db 03h
COLS:		db 160
	;; BOOT STRINGS
BootLRD:	db "Loaded Root", 10,0
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
	jne LoadRootDirectory
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
	mov si, KernelFile
	call LOCATE
	mov ax, 7E0h
	mov es, ax
	xor bx, bx
	;; 	mov di, 2
	;; 	mov si, 4
	call READSECTORS
	mov bx, BootLKF
	call print
	jmp KernelPart2
	;; Interupts:
	;; x	0x21: Read File		; Takes file start in di, length in si, and
	;; 				a buffer in es:bx
	;; x	0x22: Write File	; Same as 0x21
	;; 	0x23: Create File	; Takes a name in ds:bx, permisions in ax,
	;; 				and a buffer in es:si
	;; 	0x24: Delete File	; Takes a file name in ds:bx
	;; 	0x25: Execute File	; Takes a file name in ds:si, and the
	;; 					current process in ax
	;; 	0x26: Open File 	; Takes a file name in ds:si, and sets di to
	;; 		the file start block, and si to the length of the file
	;; x	0x27: Output ds:bx to console
	;; 	0x28: Allocate ax bytes of RAM, pointer returned in es:bx
	;; 	0x29: Free pointer es:bx
	;; 	0x2A: Set directory to es:bx
	;; 	0x2B: Drop last directory
	;; 	0x2C: Switch to drive al
	;; x	0x2D: Change the color of the console to al
	;; x	0x2E: Set sys flag cl to bl=1: high, bl=0: low, else: togle
	;; 	0x2F: Register Signal al, clear with SysFlag 5 set. sets to es:dx
	;; 	0x30: Launch a new process at address bx(Pauses the current process
	;; 		and saves it to be resumed).
	;; 	0x31: Raise Signal al(bl, bh)
	;; x	0x32: Return to Kernel
	;; x	0x33: Read Input
	;; Signals:
	;; x	0 - EXIT: Raised by CTRL+C   Quits program
	;; x	TERMinate: Raised by CTRL+X  Force quits program
	;; 	1 - PAUSe: Raised by CTRL+Z  Sets a program resume vector and pauses
	;; 	2 - SeLeCT: Raised by CTRL+SPACE Creates a mark to read from console
	;; 	3 - COPY: Raised by CTRL+SHIFT+C Copies all selected data to the
	;; 						copy buffer
	;; 	4 - PASTe: Raised by CTRL+SHIFT+V Pastes the content of the copy
	;;						buffer
	;; 	5 - DeLeTE: Raised by CTRL+BACKSPACE Deletes the selected text
	;; 	6 - CoPy & DeLete: Raised by CTRL+SΗIFT+X Combines the COPY and
	;; 						DELETE events
	;; x	7 - KeyBoaRD: Raised by all other CTRL or ALT key combos
	;; x	SHutDowN: Raised by CTRL+ALT+SHIFT+BACKSPACE Shuts down the computer
	;; 	CONTinue: Raised by CTRL+{number key N}, set by CTRL+Z
	;; 
;; Helper functions/interupts
	;;  femto ignores the EXTRA DATA section, the EXECUTABLE permision, and
	;;  the low four bits of the permisions byte

LOCATE:
    push ax
    push bx
    push cx
    push dx
    push es
    push word [DIR]
	pop es
	push si
	xor bx, bx
	xor di, di
    jmp .loop	
.next:
	pop si
	push si
	add bx, 32
	mov di, bx
	cmp bx, word [cs:DLEN]
	je .fail
.loop:
    mov al, [ds:si]
    cmp al, 0
    je .pend
    cmp al, [es:di]
    jne .next
    inc si
    inc di
	jmp .loop
.pend:
	cmp byte [es:di], 0
	jne .next
.end:
    pop si
    mov di, bx
    add di, 25
    mov al, [es:di]
    mov si, ax
    and si, 0FFh	
    inc di
    mov al, byte [es:di]
    inc di
    mov ah, byte [es:di]
	mov di, ax
	mov cl, 6
	mov bl, 0
	int 2Eh
.exit:
    pop es
    pop dx
    pop cx
    pop bx
    pop ax	
    ret
.fail:
	pop si
	mov cl, 6
	mov bl, 1
	int 2Eh
	je .exit
	;; Read {si} sectors starting at {di} into {es:bx}
READSECTORS:
	pusha
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
	popa
	ret
LBA_to_CHS:
    push ax
    xor dx, dx
    div word [cs:BSPT]
    inc dl
    mov cl, dl
    pop ax
    xor dx, dx
    div word [cs:BSPT]
    xor dx, dx
    div word [cs:pBH]
    mov dh, dl
    mov ch, al
    mov dl, byte [cs:DISK]
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
	mov byte [es:di] , dl
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
section .part2	
CMD:	db "welcome"
	times 249 db 0
DSTACK:	 times 64 db 0
CMDp: 	dw 0
Version:	db "Femto 0.5", 10, 0
Prompt:	db 13, "FEMTO>", 0
ERROR:	db "Error: Bad command", 10, 0
INPUT_BUFFER:	times 32 db 0
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
	cli
	mov al, 21h
	mov dx, ReadInt
	call CreateInterupt
	inc al
	mov dx, WriteInt
	call CreateInterupt
	mov al, 27h
	mov dx, PrintInt
	call CreateInterupt
	mov dx, ColorChangeInt
	mov al, 2Dh
	call CreateInterupt
	mov dx, SysFlagInt
	inc al
	call CreateInterupt
	inc al
	mov dx, RegisterSignal
	call CreateInterupt
	mov al, 32h
	mov dx, SIG_EXIT
	call CreateInterupt
	inc al
	mov dx, ReadInputInt
	call CreateInterupt
	mov ax, [es:24h]
	mov word [cs:INT9_OFF], ax
	mov ax, [es:26h]
	mov word [cs:INT9_SEG], ax
	mov al, 9
	mov dx, KeyPressInt
	call CreateInterupt
	sti
	mov bx, CMD
RegisterSignals:
	jmp CLI.ExecFile
CLI:
	mov bl, 1
	mov cl, 4
	int 2Eh
	mov al, 0
	int 2Fh
	mov al, 1
	int 2Fh
	mov cx, 256
	mov bx, CMD
.wipe:
	mov byte [bx], 0
	inc bx
	loop .wipe
	mov bl, 0
	mov cl, 3
	int 2Eh
	mov bx, Prompt
	int 27h
	mov word [CMDp], 0
.prompt:
	mov bl, 1
	mov cl, 3
	int 2Eh
	call ReadInput
	cmp al, 10
	je .exec
	cmp al, 8
	je .bs
	mov bx, CMD
	add bx, [CMDp]
	mov byte [bx], al
	inc byte [CMDp]
	mov bl, al
	int 27h
	jmp .prompt
.exec:
	mov bl, 10
	int 27h
	cmp byte [CMD], 0
	je CLI
	cmp byte [CMD], 'e'
	je .EXECUTE
	cmp byte [CMD], 'd'
	je .DUMP
	mov bx, CMD
.ExecFile:
	inc bx
	cmp byte [bx], ' '
	je .ExecFile2
	cmp byte [bx], 0
	jne .ExecFile
.ExecFile2:
	mov byte [bx], 0
	inc bx
	push bx
	mov si, CMD
	call LOCATE
	test word [SysFlags], 64
	jnz .error
	mov ax, 3000h
	mov es, ax
	xor bx, bx
	int 21h
	mov ds, ax
	pop bx
	jmp .RUNPRG
.error:	
	mov bl, 0
	mov cl, 3
	int 2Eh
	mov bx, ERROR
	int 27h
	jmp CLI
.bs:
	cmp byte [CMDp], 0
	je .prompt
	sub word [VAddr], 2
	mov bl, " "
	int 27h
	sub word [VAddr], 2
	mov bx, CMD
	add bx, CMDp
	mov byte [bx], 0
	dec byte [CMDp]
	jmp .prompt
.EXECUTE:
	mov bx, CMD+1
	call .DECIMAL_TO_WORD
	mov di, ax
	inc bx
	call .DECIMAL_TO_WORD
	mov si, ax
	mov ax, 3000h
	mov es, ax
	xor bx, bx
	int 21h
	mov ds, ax
	mov bx, CMD+12
.RUNPRG:
	mov ax, 1
	mov cx, 0
	mov es, cx
	mov dx, 0
	mov di, 0
	mov si, 0
	call 3000h:0h
	jmp SIG_EXIT
.DUMP:
	mov cx, 512
	push word [DIR]
	pop es
	xor di, di
.DUMP_LOOP:
	mov bl, [es:di]
	int 27h
	inc di
	loop .DUMP_LOOP
	jmp CLI
	;; IN:[bx]; OUT: ax
.DECIMAL_TO_WORD:
	mov ax, 0
	mov cx, 5
.DECIMAL_TO_WORD_LOOP:
	mov dx, 0
	mul word [.TEN]
	mov dl, [bx]
	mov dh, 0
	sub dl, '0'
	add ax, dx
	inc bx
	loop .DECIMAL_TO_WORD_LOOP
	ret
.TEN: dw 10
	;; Sets interupt al to address es:dx
CreateInterupt:
	cli
	pusha
	push es
	push word 0h
	pop es
	pop cx
	push cx
	mov ah, 0
	shl ax, 2
	mov bx, ax
	mov word [es:bx], dx
	add bx, 2
	mov word [es:bx], cx
	pop es
	popa
	sti
	ret
SysFlagInt:
	push ax
	mov ax, 1
	shl ax, cl
	cmp bl, 0
	je .clear
	cmp bl, 1
	je .set
	xor word [cs:SysFlags], ax
	pop ax
	iret
.clear:
	not ax
	and word [cs:SysFlags], ax
	pop ax
	iret
.set:
	or word [cs:SysFlags], ax
	pop ax
	iret
ReadInputInt:
	test word [cs:SysFlags], 128
	jnz .NoBlock
	call ReadInput
	iret
.NoBlock:
	call ReadInputNoBlock
	iret
ColorChangeInt:	
	mov byte [cs:Color], al
	iret
	;; if SysFlag 3 is set, prints one char
PrintInt:
	test word [cs:SysFlags], 8
	jnz .char
	call print
	iret
.char:
	call putchar
	iret
ExecuteFileInt:
	pusha
	call LOCATE
	test word [SysFlags], 64
	jnz .error
	mov ax, 3000h
	mov es, ax
	xor bx, bx
	int 21h
	mov ds, ax
	pop bx
	jmp CLI.RUNPRG
.error:
	popa
	mov ax, 0
	iret
	;; Keyboard data:
	;; SCAN: db 0x1c, 0x32, 0x21, 0x23, 0x24, 0x2B, 0x34, 0x33, 0x43, 0x3B, 0x42, 0x4B, 0x3A, 0x31, 0x44, 0x4D, 0x15, 0x2D, 0x1B, 0x2C, 0x3C, 0x2A, 0x1D, 0x22, 0x35, 0x1A, 0x16, 0x1E, 0x26, 0x25, 0x2E, 0x36, 0x3D, 0x3E, 0x46, 0x45, 0x4E, 0x55, 0x4A, 0x49, 0x41, 0x4C, 0x52, 0x54, 0x5B, 0x5D, 0x0E, 0x29, 0x5A, 0 ; Unused, maps to scan code set one
SCAN:	db 0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26, 0x32, 0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D, 0x15, 0x2C, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x35, 0x34, 0x33, 0x27, 0x28, 0x1A, 0x1B, 0x2B, 0x29, 0x39, 0x1C, 0x0E, 0
LOWER:	db "abcdefghijklmnopqrstuvwxyz1234567890-=/.,;'[]\` ", 10, 8
UPPER:	db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+?><:"{}|~ ', 10, 8
	;;" Converts the scan code {ah} to the ascii char {al}, upercase if 
ScanCodeToChar:	
	push bx
	mov bx, SCAN
.loop:
	cmp byte [cs:bx], 0
	je .null
	cmp ah, [cs:bx]
	je .end
	inc bx
	jmp .loop
.end:
	sub bx, SCAN
	test word [cs:SysFlags], 0b100
	jnz .UP
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
	pop bx
	ret
KeyPressInt:
	pusha
	in al, 60h
	cmp al, 2Ah
	je .shiftSet
	cmp al, 36h
	je .shiftSet
	cmp al, 1Dh
	je .ctrlSet
	cmp al, 38h
	je .altSet
	cmp al, 0xE0
	je .clear
	cmp al, 0xAA
	je .shiftClear
	cmp al, 0xB6
	je .shiftClear
	cmp al, 9Dh
	je .ctrlClear
	cmp al, 0xb8
	je .altClear
	test al, 0x80
	jnz .end
	mov ah, al
	call ScanCodeToChar
	test word [cs:SysFlags], 2
	jnz .ctrl
	test word [cs:SysFlags], 1
	jnz .SIGKBRD
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
.shiftSet:
	mov cl, 2
	mov bl, 1
	int 2Eh
	jmp .end
.shiftClear:
	mov cl, 2
	mov bl, 0
	int 2Eh
	jmp .end
.altSet:
	mov cl, 0
	mov bl, 1
	int 2Eh
	jmp .end
.altClear:
	mov cl, 0
	mov bl, 0
	int 2Eh
	jmp .end
.ctrlSet:
	mov cl, 1
	mov bl, 1
	int 2Eh
	jmp .end
.ctrlClear:
	mov cl, 1
	mov bl, 0
	int 2Eh
	jmp .end
.clear:
	in al, 64h
	test al, 1
	jz .end
	in al, 60h
	jmp .clear
.ctrl:
	test word [cs:SysFlags], 1
	jnz .ctrl_alt
	cmp al, 'c'
	je .SIGEXIT
	cmp al, 'x'
	je .SIGTERM
	cmp al, 'z'
	je .SIGPAUS
	cmp al, 'C'
	je .SIGCOPY
	cmp al, 'V'
	je .SIGPAST
	cmp al, ' '
	je .SIGSLCT
	cmp al, 8
	je .SIGDLTE
	cmp al, 'X'
	je .SIGCPDL
	jmp .SIGKBRD
.ctrl_alt:
	test word [cs:SysFlags], 4
	jnz .ctrl_alt_shift
	jmp .SIGKBRD
.ctrl_alt_shift:
	cmp al, 8
	je .SIGSHDN
.SIGKBRD:
	mov bl, 1
	mov cl, 5
	int 2Eh
	mov cl, 7
	mov byte [cs:SIGNAL_ARG], al
	call INVOKE_SIG
	jmp .end
.SIGPAUS:
	mov cl, 1
	call INVOKE_SIG
	jmp .end
.SIGCOPY:
	mov cl, 3
	call INVOKE_SIG
	jmp .end
.SIGSLCT:
	mov cl, 2
	call INVOKE_SIG
	jmp .end
.SIGPAST:
	mov cl, 4
	call INVOKE_SIG
	jmp .end
.SIGDLTE:
	mov cl, 5
	call INVOKE_SIG
	jmp .end
.SIGCPDL:
	mov cl, 6
	call INVOKE_SIG
	jmp .end
.SIGTERM:
	mov al,20h
	out 20h,al
	int 32h
.SIGEXIT:
	mov al,20h
	out 20h,al
	popa
	push word [cs:SIGNALS.EXITcs]
	push word [cs:SIGNALS.EXITip]
	retf
.SIGSHDN:
	mov al, 20h
	out 20h, al
	mov ax, 5307h
	int 15h
	cli
.kernLock:
	jmp .kernLock
RegisterSignal:
	pusha
	cmp al, 7
	jg .escape
	mov dl, al
	mov ah, 0
	mov bx, SIGNALS
	mov di, SIGNAL_DEFAULTS
	add di, ax
	add di, ax
	shl ax, 2
	add bx, ax
	test word [SysFlags], 32
	jz .Register
.Clear:
	mov ax, [di]
	mov dx, 0
	mov [bx], dx 
	inc bx
	inc bx
	mov [bx], ax
	mov al, 1
	shl al, cl
	not al
	and [cs:SETSIGNALS], al
	popa
	iret
.Register:
	mov dx, es
	mov [bx], es
	inc bx
	inc bx
	mov [bx], dx
	mov al, 1
	shl al, cl
	or [cs:SETSIGNALS], al
.escape:
	popa
	iret
ReadInputNoBlock:
	push bx
	mov bx, INPUT_BUFFER
	add bl, [cs:IRHEAD]
	mov al, cs:bx
	mov byte [cs:bx], 0
	cmp al, 0
	jne ReadInput.inc
	pop bx
	ret
ReadInput:
	push bx
	mov bx, INPUT_BUFFER
	add bl, [cs:IRHEAD]
.block:
	mov al, [cs:bx]
	cmp al, 0
	je .block
	mov byte [cs:bx], 0
.inc:
	inc byte [cs:IRHEAD]
	cmp byte [cs:IRHEAD], 32
	je .reset
	pop bx
	ret
.reset:
	mov byte [cs:IRHEAD], 0
	pop bx
	ret
	;; prints bl
putchar:
	pusha
	push es
	mov ax, [cs:VGA_BASE]
	mov es, ax
	mov di, [cs:VAddr]
	mov dl, [cs:Color]
	cmp bl, 10
	je .newline
	cmp bl, 13
	je .cr
	mov byte [es:di], bl
	inc di
	mov byte [es:di], dl
	inc di
	jmp print.end
.newline:
	add di, 160
.cr:
	mov ax, di
	div byte [cs:COLS]
	mul byte [cs:COLS]
	mov di, ax
	jmp print.end

SIG_PAUSE:
SIG_EXIT:
	cli
	mov ax, 1000h
	mov ss, ax
	xor sp, sp
	push cs
	pop ds
	mov byte [SETSIGNALS], 3
	sti
	jmp 0000:CLI
ReadInt:
	call READSECTORS
	iret
WriteInt:
	call WRITESECTORS
	iret
OpenInt:
	push cx
	push bx
	mov cl, 6
	mov bl, 0
	int 2Eh
	pop bx
	pop cx
	call LOCATE
	iret
INVOKE_SIG:			; Invokes signal cl
	pusha
	mov al, 1
	shl al, cl
	test byte [cs:SETSIGNALS], al
	jz .exit
	mov bx, SIGNALS
	shl cl, 2
	mov ch, 0
	add bx, cx
	pushf
	push cs
	push word .exit
	push word [cs:bx]
	push word [cs:bx]
	mov al, 20h
	out 20h, al
	retf
.exit:
	popa
	ret
WRITESECTORS:
	pusha
	cmp si, 0
	je .end
.start:
	call WRITESECTOR
	add bx, 512
	inc di
	dec si
	jnz .start
.end:
	popa
	ret
WRITESECTOR:	
	pusha
	push es
	push bx
	push es
	mov ax, di
	call LBA_to_CHS
	mov ah, 3
	mov al, 1
	pop es
	pop bx
	int 13h
	jnc .end
	pop es
	popa
	jmp WRITESECTOR
.end:
	pop es
	popa
	ret
SETSIGNALS: db 0b00000011
SIGNAL_ARG: db 0
SIGNAL_DEFAULTS:
.EXIT:	dw SIG_EXIT
.PAUS:	dw SIG_PAUSE
.SLCT:  dw 0
.COPY: 	dw 0
.PAST:  dw 0
.DLTE: 	dw 0
.CPDL:  dw 0
.KBRD:  dw 0
SIGNALS:
.EXITcs: dw 0
.EXITip: dw 0
.PAUScs: dw 0
.PAUSip: dw 0
.SLCTcs: dw 0
.SLCTip: dw 0	
.COPYcs: dw 0
.COPYip: dw 0
.PASTcs: dw 0
.PASTip: dw 0
.DLTEcs: dw 0
.DLTEip: dw 0
.CPDLcs: dw 0
.CPDLip: dw 0
.KBRDcs: dw 0
.KBRDip: dw 0
%warning %eval($ - $$) Bytes Long
