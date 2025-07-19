ORG 0x7E00

;{CONSTANTS}

start:

   mov si, VALUE_3
   call print_log
   mov si, VALUE_Greetings
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

prep_convert_hex:
   mov cl, 0
   mov [VALUE_hex_to_str_index], cl
   ret
convert_hex_to_str:
   cmp eax, 16
   jge .div_num

   jmp .store_value
.div_num:
   xor edx, edx
   mov ebx, 16
   div ebx
   push edx
   call convert_hex_to_str
   pop edx
   mov al, dl

.store_value:
   mov ebx, 0
   mov bl, al
   mov bl, [VALUE_hexdecimal_chars + bx]
   mov al, bl

   push ebx 
   mov ebx, VALUE_hex_to_str_index
   mov cl, [VALUE_hex_to_str_index]
   add ebx, ecx
   mov byte [ebx], al
   inc cl
   mov [VALUE_hex_to_str_index], cl
   pop ebx
    
.done:
   mov ebx, VALUE_hex_to_str_index
   mov cl, [VALUE_hex_to_str_index]
   add ebx, ecx
   mov byte [ebx], 0
   ret
;{INCLUDE}

VALUE_int_to_str_buffer db 0,0,0,0,0,0,0,0,0,0,0
VALUE_int_to_str_index db 0
VALUE_hex_to_str_buffer db 0,0,0,0,0,0,0,0,0,0,0
VALUE_hex_to_str_index db 0
VALUE_hexdecimal_chars db '0123456789ABCDEF'
VALUE_hello db 'Hello, World!',13,10,0
VALUE_newline db 13,10,0
VALUE_name: times 40 db 0
VALUE_vlaue dd 20
VALUE_Greetings db 'Welcome to PHI language!',0
VALUE_3 db 13,10,0
;{VARIABLE}

