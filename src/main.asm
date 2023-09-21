org		0x7C00
bits	16


%define ENDLINE	0x0D, 0x0A

start:
	jmp main

;
; Prints characters to the screen
; Params:
;	- ds:si pointer to string
puts:
	push si
	push ax

.puts_loop:
	lodsb					; Loads next character in al
	or al, al				; Is next character is \0
	jz .puts_done

	mov ah, 0x0e
	int 0x10

	jmp .puts_loop

.puts_done:
	pop ax
	pop si
	ret

main:
	; Setup data segments
	mov ax, 0				; Can't mutate ds & es directly
	mov ds, ax
	mov es, ax

	; Setup stack
	mov ss, ax
	mov sp, 0x7C00			; Stack will grows downwards

	; Print hello world
	mov si, msg_hello
	call puts

	hlt

.halt:
	jmp	.halt

msg_hello:	db 'Hello world', ENDLINE, 0

times	510-($-$$)	db	0
dw		0AA55H


