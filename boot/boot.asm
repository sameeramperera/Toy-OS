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

    call switch_to_pm   ; Phase 2: hand off to protected mode
    jmp hang            ; safety net, should never actually reach here

; ─── Functions (Real Mode) ───
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

; ─── GDT ───
gdt_null:
    dq 0x0000000000000000      ; required null descriptor

gdt_code:
    dw 0xFFFF                  ; limit (low 16 bits)
    dw 0x0000                  ; base  (low 16 bits)
    db 0x00                    ; base  (next 8 bits)
    db 0x9A                    ; access byte: present, ring0, code, readable
    db 0xCF                    ; flags (4K gran, 32-bit) + limit (high 4 bits)
    db 0x00                    ; base  (final 8 bits)

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92                    ; access byte: present, ring0, data, writable
    db 0xCF
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_null - 1  ; size of GDT - 1
    dd gdt_null                 ; linear address of GDT start

CODE_SEG equ gdt_code - gdt_null
DATA_SEG equ gdt_data - gdt_null

; ─── Switch to Protected Mode ───
switch_to_pm:
    cli                          ; 1. disable interrupts
    lgdt [gdt_descriptor]        ; 2. tell CPU where the GDT is

    mov eax, cr0                 ; 3. flip the PE bit in CR0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_SEG:init_pm         ; 4. far jump: flush pipeline, reload CS

; ─── Protected Mode (32-bit) ───
[BITS 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000
    mov esp, ebp

    call print_pm_string
    jmp $                         ; hang here, 32-bit style

print_pm_string:
    pusha
    mov edx, 0xB8000               ; VGA text buffer, no BIOS needed
    mov esi, msg_pm
.loop:
    mov al, [esi]
    mov ah, 0x0F                   ; white text on black background
    cmp al, 0
    je .done
    mov [edx], ax
    add esi, 1
    add edx, 2                     ; 2 bytes per screen character (char+attr)
    jmp .loop
.done:
    popa
    ret

; ─── Data ───
msg_boot db 'ToyOS v0.1 Booting...', 0x0D, 0x0A, 0
msg_pm   db 'ToyOS: Now in 32-bit Protected Mode!', 0

; ─── Real Mode hang (unused now, kept as safety net) ───
hang:
    cli
    hlt
    jmp hang

; ─── Boot Sector Padding ───
times 510 - ($ - $$) db 0
dw 0xAA55