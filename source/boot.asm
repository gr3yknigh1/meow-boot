
; @breaf BIOS interupt call list.
; @see https://en.wikipedia.org/wiki/BIOS_interrupt_call
%define INT_KEYBOARD 09h
%define INT_VIDEO    10h
%define INT_DISK     13h   ; @see https://en.wikipedia.org/wiki/INT_13H
%define INT_MISC     15h

; INT_VIDEO 
; AH - register
%define INT_VIDEO_TTY_WRITE_CHAR 0eh
%define INT_VIDEO_SET_MODE       00h

; INT_DISK
; AH - register
%define INT_DISK_READ_SECTORS    02h

; INT_MISC
; AH - register
%define INT_MISC_WAIT            86h

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
    ret

;
; void bios_wait(int milliseconds);
;
; @breaf Sleeps for N milliseconds
; @param si
bios_wait:
    push si
    push ax
    mov ax, INT_MISC_WAIT   ; Wait subroutine
    mov dx, si              ; Milliseconds
    int INT_MISC    
    pop ax
    pop si
    ret

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
	push ax
    jmp .bios_puts__loop
.bios_puts__loop:
	lodsb					; Loads next character in al
	or al, al				; Is next character is \0
	jz .bios_puts__done

	mov ah, INT_VIDEO_TTY_WRITE_CHAR
	int INT_VIDEO

	jmp .bios_puts__loop
.bios_puts__done:
	pop ax
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
    mov si, message_boot_hello_world

    ; Loading kernel 
    mov ah, INT_DISK_READ_SECTORS    ; Subroutine code
    mov al, 7                        ; Count of sectors to read
    mov ch, 0x00                     ; Cylinder number @research
    mov cl, 0x02                     ; Sector number (1 - bootloader, 2 - kernel) @research
    mov dh, 0x00                     ; Head @research
    mov dl, 0x80                     ; Drive number
    mov bx, KERNEL_SECTOR_ADDR
    int INT_DISK
    jc .bootloader_entry__kernel_load_error
    jmp .bootloader_entry__kernel_load_ok
.bootloader_entry__kernel_load_error:
	mov si, message_boot_kernel_load_error
	call bios_puts
    ret
.bootloader_entry__kernel_load_ok:
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

%define KERNEL_INPUT_BUFFER_SIZE 255

;
; void memory_zero(void *buffer, int buffer_size);
;
; @breaf Zeroing the buffer.
; @param si Buffer address
; @param bx Buffer size
memory_zero:
    push si
    push cx

    mov cx, 0
.memory_zero__loop:
    cmp cx, bx
    je .memory_zero__end
    mov byte [si], 0
    inc si
    inc cx
    jmp .memory_zero__loop
.memory_zero__end:

    pop cx
    pop si
    ret

;
; void bios_read_input(void *buffer)
; 
; @breaf Write input to specified buffer
;
; @param si Address of the buffer in which routine should write user input.
;
bios_read_input:
    ret

;
; [[noreturn]] void kernel_boot(void);
;
; @breaf Kernel boot startup code.
;
kernel_boot:
    push si

    call bios_tty_clear

    mov si, message_kernel_welcome
    call bios_puts

    call kernel_shell_loop

    mov si, message_kernel_exiting
    call bios_puts

    call bios_halt

    pop si
    ret

;
; void kernel_shell_handle_command(void *input_buffer);
;
; @breaf Handles what to do when user types commands.
;
kernel_shell_handle_command:
    ret

;
; void kernel_shell_loop(void);
;
; @breaf Shell mainloop, which waits new commands to be typed.
;
kernel_shell_loop:
    ; TODO(gr3yknigh1): Make it not infinite [2024/10/24]
    jmp .kernel_shell_loop__begin

.kernel_shell_loop__begin:
    push si
    push bx

    ; Clear input buffer
    mov si, kernel_shell_input_buffer
    mov bx, KERNEL_INPUT_BUFFER_SIZE
    call memory_zero

    ; Printing the prompt prefix
    mov si, kernel_shell_prompt
    call bios_puts

    ; Reading user input
    mov si, kernel_shell_input_buffer
    call bios_read_input

    mov si, kernel_shell_input_buffer
    call kernel_shell_handle_command

    jmp .kernel_shell_loop__begin
 
    pop bx
    pop si
    ret

message_kernel_welcome:
    db "KERNEL: Hello sailor!", ENDLINE, 0
message_kernel_exiting:
    db "KERNEL: Quiting...", ENDLINE, 0

kernel_shell_input_buffer times KERNEL_INPUT_BUFFER_SIZE db 0
kernel_shell_prompt db "> ", 0
