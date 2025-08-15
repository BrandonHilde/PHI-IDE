ORG 0x7E00

;{CONSTANTS}

start:

   mov si, VALUE_test
   call print_log
;{CODE}

   jmp $

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
;{INCLUDE}

VALUE_int_to_str_buffer db 0,0,0,0,0,0,0,0,0,0,0
VALUE_int_to_str_index db 0
Convert_str_to_base_buffer: times 41 db 0
VALUE_buffer_depth dw 40
VALUE_buffer_len dw 40
Convert_base_val dw 16
Convert_str_to_base_values db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_'
VALUE_Greetings db 'hello, world, fdsfdsfsdfsf',0
VALUE_test db 'test',0
;{VARIABLE}

