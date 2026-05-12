; Toy-OS Bootloader

[BITS 16]
[ORG 0x7C00]

; ─── Entry Point ───
start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov sp, 0x7C00

    call clear_screen

    mov si, msg_boot
    call print_string

    jmp hang

; ─── Functions ───
clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

print_string:
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x04
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

; ─── Data ───
msg_boot db 'ToyOS v0.1 Booting...', 0x0D, 0x0A, 0

; ─── Boot Sector Padding ───
hang:
    cli
    hlt
    jmp hang

times 510 - ($ - $$) db 0

dw 0xAA55