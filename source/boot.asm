
; @breaf BIOS interupt call list.
; @see https://en.wikipedia.org/wiki/BIOS_interrupt_call
%define INT_KEYBOARD 09h
%define INT_VIDEO    10h
%define INT_DISK     13h   ; @see https://en.wikipedia.org/wiki/INT_13H

; INT_VIDEO (`ah` register)
%define INT_VIDEO_TTY_WRITE_CHAR 0eh

; INT_DISK (`ah` register)
%define INT_DISK_READ_SECTORS    02h

; Other macros
%define ENDLINE	0x0D, 0x0A

%define BOOT_SECTOR_MAGIC    0xaa55
%define BOOT_SECTOR_ADDR     0x7c00
%define KERNEL_SECTOR_ADDR   0x7e00
;                            ^^^^^^
; BOOT_SECTOR_ADDR + 512

org		BOOT_SECTOR_ADDR
bits	16

start:
	call bootloader_entry
    call bios_halt

;
; [[noreturn]] void bios_halt(void);
;
; @breaf Halts core and enters infinite loop
;
bios_halt:
	hlt
.bios_halt_loop:
	jmp	.bios_halt_loop

;
; void puts(char *s);
;
; @breaf Prints characters to the TTY.
; @param ds:si Pointer to string to put in TTY
;
puts:
	push si
	push ax
    jmp .puts_loop
.puts_loop:
	lodsb					; Loads next character in al
	or al, al				; Is next character is \0
	jz .puts_done

	mov ah, INT_VIDEO_TTY_WRITE_CHAR
	int INT_VIDEO

	jmp .puts_loop
.puts_done:
	pop ax
	pop si
	ret

;
; void bootloader_entry(void);
;
; @breaf Bootloader entrypoint. Loads kernel into the RAM.
;
bootloader_entry:
	; Setup data segments
    cli                     ; Clearing `EFLAGS` register
	xor ax, ax				; Can't mutate ds & es directly
    mov ds, ax
    mov es, ax

	; Setup stack
	mov ss, ax
	mov sp, BOOT_SECTOR_ADDR	; Stack will grows downwards

%if 0
	; Print hello world
	mov si, hello_world_message 
	call puts
%endif

    ; Loading kernel 
    mov ah, INT_DISK_READ_SECTORS    ; Subroutine code
    mov al, 7                        ; Count of sectors to read
    mov ch, 0x00                     ; Cylinder number @research
    mov cl, 0x02                     ; Sector number (1 - bootloader, 2 - kernel) @research
    mov dh, 0x00                     ; Head @research
    mov dl, 0x80                     ; Drive number
    mov bx, KERNEL_SECTOR_ADDR
    int INT_DISK
    jc .kernel_load_error
    jmp .kernel_load_ok
.kernel_load_error:
	mov si, message_kernel_load_error
	call puts
    ret
.kernel_load_ok:
    mov si, message_kernel_load_ok
    call puts
    jmp KERNEL_SECTOR_ADDR
    ret

message_hello_world:	
    db 'Hello world', ENDLINE, 0
message_kernel_load_ok:
    db 'Kernel is loaded!', ENDLINE, 0
message_kernel_load_error:
    db 'Failed to load kernel', ENDLINE, 0

times	510-($-$$)	db	0
dw		BOOT_SECTOR_MAGIC

jmp kernel_boot

kernel_boot:
    call bios_halt

