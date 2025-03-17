	bits 16
	org 0
	push bx
	mov bl, 0
	mov cl, 3
	int 2Eh
	pop bx
	cmp byte [es:bx], '1'
	je Page1
	cmp byte [es:bx], '2'
	je Page2
	cmp byte [es:bx], '3'
	je Page3
	cmp byte [es:bx], '4'
	je Page4
	mov bx, MSG
Print:	
	int 27h
	int 32h
end:	
	jmp end
Page1:
	mov bx, MSG1
	jmp Print
Page2:
	mov bx, MSG2
	jmp Print
Page3:
	mov bx, MSG3
	jmp Print
Page4:
	mov bx, MSG4
	jmp Print
MSG:	db "Usage: help [page]", 10, "Page can be one of:", 10, "1 - Keyboard Shortcuts", 10, "2 - Interupts", 10, "3 - Commands", 10, "4 - Welcome", 10, 0
MSG1: 	db "Femto usage guide: Use ctrl-c to return to femto console, or ctrl-x if that is", 10, "intercepted by the program. Ctrl-z pauses the current program to return to the", 10, "console without lossing progress, these programs can be resumed with Ctrl-N to", 10, "resume process N. Ctrl-Space starts selecting a region, Ctrl-Shift-C copies", 10, "Ctrl-Shift-X copies then deleting the selected region, Ctrl-Shift-V pastes the", 10, "contents of the copy buffer, and Ctrl-Backspace deletes selected region. Use", 10, "Ctrl-Alt-Shift-Backspace to shutdown the computer"
MSG2:	db "Interupt List not writen", 10, 0
MSG3:	db "e[SectorStart] [Length] [Args] - Executes the program starting at sector block", 10, "                                 SectorStart and contining Length blocks", 10, "                                 passing Args to the program.", 10, "d                              - Dumps the contents of the current directory to                                  allow one to see the available commands", 10, 0
MSG4:   db "Welcome to FEMTOS: Fully Extensible Micro Terminal Operating System", 10, "This is currently incomplete, however development will most likly continue and  can be tracked at https://github.com/EmacsIsBetterThanVi/MicroOSProject." , 10, 0
