ORG 0x7c00

;{CONSTANTS}

start:
   xor ax, ax
   mov ds, ax
   mov es, ax
   mov ss, ax
   mov sp, 0x7c00

   mov si, VALUE_hello
   call print_log
   mov si, VALUE_newline
   call print_log
   mov si, VALUE_0
   call print_log
    call  Bootloader_WaitForKeyPress
    call  Bootloader_EnableVideoMode
    call  Bootloader_JumpToSectorTwo
;{CODE}

   jmp $

Bootloader_PrepSectorTwo:
   mov ah, 0x02    ; BIOS read sector
   mov al, 6       ; Number of sectors
   mov ch, 0       ; Cylinder number
   mov dh, 0       ; Head number
   mov cl, 2       ; Sector number
   mov bx, 0x7E00  ; Load address
   int 0x13
   ret
Bootloader_JumpToSectorTwo:
   call Bootloader_PrepSectorTwo
   jmp 0x7E00 ; jump to sector two
   ret
prep_convert:
   mov cl, 0
   mov [VALUE_int_to_str_index], cl
   ret
convert_int_to_str:
   cmp eax, 10
   jge .div_num

   jmp .store_value
.div_num:
   xor edx, edx
   mov ebx, 10
   div ebx
   push edx
   call convert_int_to_str
   pop edx
   mov al, dl

.store_value:
   add al, '0' 

   push ebx 
   mov ebx, VALUE_int_to_str_buffer
   mov cl, [VALUE_int_to_str_index]
   add ebx, ecx
   mov byte [ebx], al
   inc cl
   mov [VALUE_int_to_str_index], cl
   pop ebx
    
.done:
   mov ebx, VALUE_int_to_str_buffer
   mov cl, [VALUE_int_to_str_index]
   add ebx, ecx
   mov byte [ebx], 0
   ret
print_log:
   mov ah, 0x0E
.loop:
   lodsb
   cmp al, 0
   je .done
   int 0x10
   jmp .loop
.done:
   ret

convert_to_base:
   cmp dword [Convert_base_val], 2
   jl .done
.check_max:
   cmp dword [Convert_base_val], 64
   jg .done
.check:
   cmp eax, dword [Convert_base_val]
   jl .mov_bx
.div_num:
   xor edx, edx
   div dword [Convert_base_val]
   call .mov_dl
   jmp .check
   jmp .mov_bx
.mov_dl:
   xor ebx, ebx
   mov ebx, edx
   jmp .to_buffer
.mov_bx:
   xor ebx, ebx
   mov ebx, eax
.to_buffer:
   mov cl, [Convert_str_to_base_values + ebx]
   mov ebx, dword [VALUE_buffer_depth]
   mov byte [Convert_str_to_base_buffer + ebx], cl
   sub ebx, 1
   mov dword [VALUE_buffer_depth], ebx
.done:
    ret
get_input:
   xor cx, cx
.loop:
    mov ah, 0
    int 0x16
    cmp al, 0x0D
    je .done
    stosb   
    inc cx  
    mov ah, 0x0E
    int 0x10
    jmp .loop

.done:
    mov byte [di], 0 
    ret
Bootloader_WaitForKeyPress:
   mov ah, 0x00
   int 0x16
   ret
Bootloader_EnableVideoMode:
   mov ax, 0x13
   int 0x10
   ret
;{INCLUDE}

VALUE_int_to_str_buffer db 0,0,0,0,0,0,0,0,0,0,0
VALUE_int_to_str_index db 0
Convert_str_to_base_buffer: times 41 db 0
VALUE_buffer_depth dw 40
VALUE_buffer_len dw 40
Convert_base_val dw 16
Convert_str_to_base_values db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_'
VALUE_hello db 'Hello, World!',13,10,0
VALUE_newline db 13,10,0
VALUE_0 db 'Press any key to continue...',0
;{VARIABLE}
times 510-($-$$) db 0
dw 0xaa55
