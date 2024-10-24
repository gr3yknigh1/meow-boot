
; @breaf BIOS interupt call list.
; @see https://en.wikipedia.org/wiki/BIOS_interrupt_call
%define INT_KEYBOARD 09h
%define INT_VIDEO    10h
%define INT_DISK     13h   ; @see https://en.wikipedia.org/wiki/INT_13H

; INT_VIDEO 
; AH - register
%define INT_VIDEO_TTY_WRITE_CHAR 0eh
%define INT_VIDEO_SET_MODE       00h

; AH - register
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
; void bios_tty_clear(void);
;
; @breaf Clears the TTY screen.
;
bios_tty_clear:
    push ax
    mov ah, INT_VIDEO_SET_MODE
    mov al, 0x03                        ; @research
    int INT_VIDEO
    pop ax
    ret
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
; void bios_puts(char *s);
;
; @breaf Prints characters to the TTY.
; @param ds:si Pointer to string to put in TTY
;
bios_puts:
	push si
	push ax
    jmp .bios_puts_loop
.bios_puts_loop:
	lodsb					; Loads next character in al
	or al, al				; Is next character is \0
	jz .bios_puts_done

	mov ah, INT_VIDEO_TTY_WRITE_CHAR
	int INT_VIDEO

	jmp .bios_puts_loop
.bios_puts_done:
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

    ; Hello there!
    mov si, message_hello_world

    ; Loading kernel 
    mov ah, INT_DISK_READ_SECTORS    ; Subroutine code
    mov al, 7                        ; Count of sectors to read
    mov ch, 0x00                     ; Cylinder number @research
    mov cl, 0x02                     ; Sector number (1 - bootloader, 2 - kernel) @research
    mov dh, 0x00                     ; Head @research
    mov dl, 0x80                     ; Drive number
    mov bx, KERNEL_SECTOR_ADDR
    int INT_DISK
    jc .bootloader_entry_kernel_load_error
    jmp .bootloader_entry_kernel_load_ok
.bootloader_entry_kernel_load_error:
	mov si, message_boot_kernel_load_error
	call bios_puts
    ret
.bootloader_entry_kernel_load_ok:
    mov si, message_boot_kernel_load_ok
    call bios_puts
    jmp KERNEL_SECTOR_ADDR
    ret

message_boot_hello_world:	
    db "BOOT: Hello there!", ENDLINE, 0
message_boot_kernel_load_ok:
    db "BOOT: Loaded the kernel!", ENDLINE, 0
message_boot_kernel_load_error:
    db "BOOT: Failed to load the kernel", ENDLINE, 0

times	510-($-$$)	db	0
dw		BOOT_SECTOR_MAGIC

jmp kernel_boot

;
; [[noreturn]] void kernel_boot(void);
;
; @breaf Kernel boot startup code.
;
kernel_boot:
    call bios_tty_clear

    mov si, message_kernel_welcome
    call bios_puts



    call bios_halt

message_kernel_welcome:
    db "KERNEL: Hello sailor!", ENDLINE, 0
