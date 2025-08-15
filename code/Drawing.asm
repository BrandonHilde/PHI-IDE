ORG 0x7E00

MOUSE_CURSOR_WIDTH equ 10
; interupt timer constants
PIT_COMMAND    equ 0x43
PIT_CHANNEL_0  equ 0x40
PIT_FREQUENCY  equ 1193180  ; Base frequency
DESIRED_FREQ   equ 60      ; Desired interrupt frequency 
DIVISOR        equ PIT_FREQUENCY / DESIRED_FREQ
; drawing constants
DRAW_START equ 0xA0000
SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
BUFFER_SIZE equ DRAW_START + (SCREEN_WIDTH * SCREEN_HEIGHT)
;color array
VALUE_Colors.Black equ 0x0  ;Black
VALUE_Colors.Blue equ 0x1  ;Blue
VALUE_Colors.Green equ 0x2  ;Green
VALUE_Colors.Cyan equ 0x3  ;Cyan
VALUE_Colors.Red equ 0x4  ;Red
VALUE_Colors.Magenta equ  0x5  ;Magenta
VALUE_Colors.Brown equ  0x6  ;Brown
VALUE_Colors.LightGray equ  0x7  ;Light Gray
VALUE_Colors.Gray equ  0x8  ;Gray
VALUE_Colors.LightBlue equ  0x9  ;Light Blue
VALUE_Colors.LightGreen equ 0xA  ;Light Green
VALUE_Colors.LightCyan   equ 0xB  ;Light Cyan
VALUE_Colors.LightRed   equ 0xC  ;Light Red
VALUE_Colors.LightMagenta   equ 0xD  ;Light Magenta
VALUE_Colors.Yellow equ 0xE  ;Yellow 
VALUE_Colors.White equ 0xF  ;White

;{CONSTANTS}

start:

    call  OS_SetupInteruptTimer
    call  OS_SetupKeyboardInterupt
    call  OS_SetupMouse
;{CODE}

   jmp $

OS_SetupMouse:
    ; Step 1: Enable auxiliary device
    mov al, 0xA8        ; Enable auxiliary device
    out 0x64, al
    
    ; Step 2: Get controller configuration
    mov al, 0x20        ; Get controller config
    out 0x64, al
    in al, 0x60
    
    ; Enable mouse clock (clear bit 5)
    and al, 0xDF        ; Clear mouse clock disable
    push ax
    
    ; Step 3: Set controller configuration
    mov al, 0x60        ; Set controller config
    out 0x64, al
    pop ax
    out 0x60, al
    
    ; Step 4: Send reset to mouse
    mov al, 0xD4        ; Send to auxiliary device
    out 0x64, al
    mov al, 0xFF        ; Reset mouse
    out 0x60, al
    
    ; Step 5: Enable mouse streaming
    mov al, 0xD4        ; Send to auxiliary device
    out 0x64, al
    mov al, 0xF4        ; Enable data reporting
    out 0x60, al
    
    ; Initialize packet state
    mov byte [mouse_packet_byte], 0
    
    ret
OS_GetMouseData:
    ; Check if data is available
    in al, 0x64
    test al, 0x01       ; Output buffer full?
    jz .no_data
    
    test al, 0x20       ; Mouse data?
    jz .no_data
    
    ; Read the byte
    in al, 0x60
    
    ; Process based on packet byte number
    mov bl, [mouse_packet_byte]
    cmp bl, 0
    je .byte1
    cmp bl, 1
    je .byte2
    cmp bl, 2
    je .byte3
    jmp .reset_packet
    
.byte1:
    ; First byte - button states and overflow flags
    ; Validate packet (bit 3 should be set)
    test al, 0x08
    jz .reset_packet
    mov [mouse_byte_states], al
    inc byte [mouse_packet_byte]
    jmp .no_data
    
.byte2:
    ; Second byte - X movement
    mov [mouse_byte_xmove], al
    inc byte [mouse_packet_byte]
    jmp .no_data
    
.byte3:
    ; Third byte - Y movement
    mov [mouse_byte_ymove], al
    call process_mouse_packet
    mov byte [mouse_packet_byte], 0
    jmp .no_data
    
.reset_packet:
    mov byte [mouse_packet_byte], 0
    
.no_data:
    ret
process_mouse_packet:
    ; Check for overflow - discard packet if overflow bits are set
    mov al, [mouse_byte_states]
    test al, 0xC0       ; Check bits 6 and 7 (overflow bits)
    jnz .done
    
    ; Process X movement with proper sign handling
    mov al, [mouse_byte_xmove]   ; Get X delta
    cbw                     ; Sign extend AL to AX
    mov bl, [mouse_byte_states]   ; Get flags
    test bl, 0x10           ; Test X sign bit
    jz .positive_x
    
    ; Negative X movement (left) - AL is already the delta
    neg ax                  ; Make it positive for subtraction
    sub [mouse_cursor_x], ax      ; Move left
    jmp .check_x_bounds
    
.positive_x:
    ; Positive X movement (right)
    add [mouse_cursor_x], ax      ; Move right
    
.check_x_bounds:
    ; Keep X in bounds (0 to 310)
    cmp word [mouse_cursor_x], 0
    jge .x_not_negative
    mov word [mouse_cursor_x], 0
.x_not_negative:
    cmp word [mouse_cursor_x], SCREEN_WIDTH - MOUSE_CURSOR_WIDTH
    jle .process_y
    mov word [mouse_cursor_x], SCREEN_WIDTH - MOUSE_CURSOR_WIDTH
    
.process_y:
    ; Process Y movement with proper sign handling
    mov al, [mouse_byte_ymove]   ; Get Y delta
    cbw                     ; Sign extend AL to AX
    mov bl, [mouse_byte_states]   ; Get flags
    test bl, 0x20           ; Test Y sign bit
    jz .positive_y_ps2      ; PS/2 positive Y = move up on screen
    
    ; PS/2 negative Y (down toward user) = move down on screen
    neg ax                  ; Make positive for addition
    add [mouse_cursor_y], ax      ; Move down on screen
    jmp .check_y_bounds
    
.positive_y_ps2:
    ; PS/2 positive Y (away from user) = move up on screen
    sub [mouse_cursor_y], ax      ; Move up on screen
    
.check_y_bounds:
    ; Keep Y in bounds (0 to 190)
    cmp word [mouse_cursor_y], 0
    jge .y_not_negative
    mov word [mouse_cursor_y], 0
.y_not_negative:
    cmp word [mouse_cursor_y], SCREEN_HEIGHT - MOUSE_CURSOR_WIDTH
    jle .done
    mov word [mouse_cursor_y], SCREEN_HEIGHT - MOUSE_CURSOR_WIDTH
    
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

keyboard_handler:
   push ax
   push bx
   in al, 0x60             ; Read scan code
   test al, 0x80
   jz .key_down
   ;key up event
   and al, 0x7F            ; Clear the key release bit
   xor bx, bx
   mov bl, al
   mov al, [scan_code_table + bx]  ; Convert scan code to ASCII

   mov [KeyCodeValue], al

   xor bx, bx
   mov bl, byte [KeyCodeValue]
   ;add bx, key_down_table
   mov byte [key_down_table + bx], 0x00

   jmp .done
   
   cmp al, 0               ; Check if it's a valid key
   je .done

.key_down:
   xor bx, bx
   mov bl, al
   ; Convert scan code to ASCII (simplified)
   mov al, [scan_code_table + bx]

   mov [KeyCodeValue], al

   xor bx, bx
   mov bl, byte [KeyCodeValue]
   ;add bx, key_down_table
   mov byte [key_down_table + bx], 0x01
.done:
   call OS_KeyboardEvent
   mov al, 0x20            ; Send End of Interrupt
   out 0x20, al
   pop bx
   pop ax
   iret
OS_SetupKeyboardInterupt:
   ; Set up the interrupt handler
   cli                     ; Disable interrupts
   mov word [0x0024], keyboard_handler
   mov [0x0026], cs
   sti                     ; Enable interrupts
   ret
OS_timer_interrupt:
   call OS_TimerEvent
   mov al, 0x20
   out 0x20, al
   iret
OS_SetupInteruptTimer:
   cli    ; Set up the PIT
   mov al, 00110100b    ; Channel 0, lobyte/hibyte, rate generator
   out PIT_COMMAND, al
       ; Set the divisor
   mov ax, DIVISOR
   out PIT_CHANNEL_0, al    ; Low byte
   mov al, ah
   out PIT_CHANNEL_0, al    ; High byte
   ; Set up the timer ISR
   mov word [0x0020], OS_timer_interrupt
   mov word [0x0022], 0x0000    ; Enable interrupts
   sti
   ret
OS_DrawRectangle:
   mov edi, DRAW_START; Start of VGA memory
   mov eax, [DrawRectY]
   mov ecx, SCREEN_WIDTH
   mul ecx
   add eax, [DrawRectX]
   add edi, eax
   mov edx, 0
.draw_row:
   mov ecx, 0
.draw_pixel:
   cmp edi, BUFFER_SIZE
   jl .continue_draw
   mov edi, DRAW_START
.continue_draw:
   mov al, [DrawRectColor]
   mov byte [edi], al
   inc edi
   inc ecx
   cmp ecx, [DrawRectW]
   jl .draw_pixel
   add edi, SCREEN_WIDTH
   sub edi, [DrawRectW]
   inc edx
   cmp edx, [DrawRectH]
   jl .draw_row
   ret
IF_0:
   mov eax, [VALUE_ballspeed]
   cmp eax, [VALUE_maxspeed]
   jg IF_0_CONTENT

;{ELSE CONTENT}

   ret
IF_0_CONTENT:

   mov eax, [VALUE_maxspeed]
   mov [VALUE_ballspeed], eax

;{IF CONTENT}
   ret
IF_1:
   mov al, [VALUE_downW]
   cmp al, 1
   je IF_1_CONTENT

;{ELSE CONTENT}

   ret
IF_1_CONTENT:

   mov eax, [VALUE_lefty]
   sub eax,[VALUE_paddleSpeed]
   mov [VALUE_lefty], eax

;{IF CONTENT}
   ret
IF_2:
   mov eax, [VALUE_lefty]
   cmp eax, 0
   jg IF_2_CONTENT

   mov eax, 0
   mov [VALUE_lefty], eax
;{ELSE CONTENT}

   ret
IF_2_CONTENT:
   call IF_1
;{IF CONTENT}
   ret
IF_3:
   mov eax, [VALUE_botL]
   cmp eax, [VALUE_ScreenH]
   jl IF_3_CONTENT

;{ELSE CONTENT}

   ret
IF_3_CONTENT:

   mov eax, [VALUE_lefty]
   add eax,[VALUE_paddleSpeed]
   mov [VALUE_lefty], eax

;{IF CONTENT}
   ret
IF_4:
   mov al, [VALUE_downS]
   cmp al, 1
   je IF_4_CONTENT

;{ELSE CONTENT}

   ret
IF_4_CONTENT:
   call IF_3
;{IF CONTENT}
   ret
IF_5:
   mov al, [VALUE_downO]
   cmp al, 1
   je IF_5_CONTENT

;{ELSE CONTENT}

   ret
IF_5_CONTENT:

   mov eax, [VALUE_righty]
   sub eax,[VALUE_paddleSpeed]
   mov [VALUE_righty], eax

;{IF CONTENT}
   ret
IF_6:
   mov eax, [VALUE_righty]
   cmp eax, 0
   jg IF_6_CONTENT

   mov eax, 0
   mov [VALUE_righty], eax
;{ELSE CONTENT}

   ret
IF_6_CONTENT:
   call IF_5
;{IF CONTENT}
   ret
IF_7:
   mov eax, [VALUE_botR]
   cmp eax, [VALUE_ScreenH]
   jl IF_7_CONTENT

;{ELSE CONTENT}

   ret
IF_7_CONTENT:

   mov eax, [VALUE_righty]
   add eax,[VALUE_paddleSpeed]
   mov [VALUE_righty], eax

;{IF CONTENT}
   ret
IF_8:
   mov al, [VALUE_downL]
   cmp al, 1
   je IF_8_CONTENT

;{ELSE CONTENT}

   ret
IF_8_CONTENT:
   call IF_7
;{IF CONTENT}
   ret
IF_9:
   mov eax, [VALUE_ballyDir]
   cmp eax, 0
   je IF_9_CONTENT

   mov eax, [VALUE_bally]
   add eax,[VALUE_ballspeedy]
   mov [VALUE_bally], eax
;{ELSE CONTENT}

   ret
IF_9_CONTENT:

   mov eax, [VALUE_bally]
   sub eax,[VALUE_ballspeedy]
   mov [VALUE_bally], eax

;{IF CONTENT}
   ret
IF_10:
   mov eax, [VALUE_Bot]
   cmp eax, 20
   jg IF_10_CONTENT

;{ELSE CONTENT}

   ret
IF_10_CONTENT:

   mov eax, [VALUE_Bot]
   sub eax,5
   mov [VALUE_Bot], eax

;{IF CONTENT}
   ret
IF_11:
   mov eax, [VALUE_bally]
   cmp eax, [VALUE_leftColx]
   jl IF_11_CONTENT

;{ELSE CONTENT}

   ret
IF_11_CONTENT:

   mov eax, 1
   mov [VALUE_directr], eax


   mov eax, [VALUE_ballspeed]
   add eax,1
   mov [VALUE_ballspeed], eax

   call IF_10
;{IF CONTENT}
   ret
IF_12:
   mov eax, [VALUE_ballyh]
   cmp eax, [VALUE_lefty]
   jg IF_12_CONTENT

;{ELSE CONTENT}

   ret
IF_12_CONTENT:

   mov eax, [VALUE_lefty]


   mov ebx, [VALUE_Bot]


   add eax,ebx


   push eax


   pop eax


   mov ebx, 10


   add eax,ebx


   push eax


   pop eax


   mov [VALUE_leftColx], eax

   call IF_11
;{IF CONTENT}
   ret
IF_13:
   mov eax, [VALUE_ballx]
   cmp eax, 20
   jl IF_13_CONTENT

;{ELSE CONTENT}

   ret
IF_13_CONTENT:
   call IF_12
;{IF CONTENT}
   ret
IF_14:
   mov eax, [VALUE_BotRight]
   cmp eax, 20
   jg IF_14_CONTENT

;{ELSE CONTENT}

   ret
IF_14_CONTENT:

   mov eax, [VALUE_BotRight]
   sub eax,5
   mov [VALUE_BotRight], eax

;{IF CONTENT}
   ret
IF_15:
   mov eax, [VALUE_bally]
   cmp eax, [VALUE_rightColx]
   jl IF_15_CONTENT

;{ELSE CONTENT}

   ret
IF_15_CONTENT:

   mov eax, 0
   mov [VALUE_directr], eax


   mov eax, [VALUE_ballspeed]
   add eax,1
   mov [VALUE_ballspeed], eax

   call IF_14
;{IF CONTENT}
   ret
IF_16:
   mov eax, [VALUE_ballyh]
   cmp eax, [VALUE_righty]
   jg IF_16_CONTENT

;{ELSE CONTENT}

   ret
IF_16_CONTENT:

   mov eax, [VALUE_righty]


   mov ebx, [VALUE_BotRight]


   add eax,ebx


   push eax


   pop eax


   mov ebx, 10


   add eax,ebx


   push eax


   pop eax


   mov [VALUE_rightColx], eax

   call IF_15
;{IF CONTENT}
   ret
IF_17:
   mov eax, [VALUE_ballx]
   cmp eax, 290
   jg IF_17_CONTENT

;{ELSE CONTENT}

   ret
IF_17_CONTENT:
   call IF_16
;{IF CONTENT}
   ret
IF_18:
   mov eax, [VALUE_directr]
   cmp eax, 0
   je IF_18_CONTENT

   mov eax, [VALUE_ballx]
   add eax,[VALUE_ballspeed]
   mov [VALUE_ballx], eax
   call IF_17
;{ELSE CONTENT}

   ret
IF_18_CONTENT:

   mov eax, [VALUE_ballx]
   sub eax,[VALUE_ballspeed]
   mov [VALUE_ballx], eax

   call IF_13
;{IF CONTENT}
   ret
IF_19:
   mov eax, [VALUE_bally]
   cmp eax, 0
   jl IF_19_CONTENT

;{ELSE CONTENT}

   ret
IF_19_CONTENT:

   mov eax, 1
   mov [VALUE_ballyDir], eax

;{IF CONTENT}
   ret
IF_20:
   mov eax, [VALUE_bally]
   cmp eax, 190
   jg IF_20_CONTENT

;{ELSE CONTENT}

   ret
IF_20_CONTENT:

   mov eax, 0
   mov [VALUE_ballyDir], eax

;{IF CONTENT}
   ret
IF_21:
   mov eax, [VALUE_ballx]
   cmp eax, 0
   jl IF_21_CONTENT

;{ELSE CONTENT}

   ret
IF_21_CONTENT:

   mov eax, 160
   mov [VALUE_ballx], eax


   mov eax, 1
   mov [VALUE_directr], eax


   mov eax, [VALUE_rightPoints]
   add eax,1
   mov [VALUE_rightPoints], eax


   mov eax, 1
   mov [VALUE_ballspeed], eax


   mov eax, 90
   mov [VALUE_Bot], eax


   mov eax, 90
   mov [VALUE_BotRight], eax


   mov eax, 55
   mov [VALUE_righty], eax


   mov eax, 55
   mov [VALUE_lefty], eax

;{IF CONTENT}
   ret
IF_22:
   mov eax, [VALUE_ballx]
   cmp eax, 310
   jg IF_22_CONTENT

;{ELSE CONTENT}

   ret
IF_22_CONTENT:

   mov eax, 160
   mov [VALUE_ballx], eax


   mov eax, 0
   mov [VALUE_directr], eax


   mov eax, [VALUE_leftPoints]
   add eax,1
   mov [VALUE_leftPoints], eax


   mov eax, 1
   mov [VALUE_ballspeed], eax


   mov eax, 90
   mov [VALUE_Bot], eax


   mov eax, 90
   mov [VALUE_BotRight], eax


   mov eax, 55
   mov [VALUE_righty], eax


   mov eax, 55
   mov [VALUE_lefty], eax

;{IF CONTENT}
   ret
OS_TimerEvent:

   mov eax, 0
   mov [DrawRectX], eax


   mov eax, 0
   mov [DrawRectY], eax


   mov eax, 320
   mov [DrawRectW], eax


   mov eax, 200
   mov [DrawRectH], eax


   mov al, VALUE_Colors.Black
   mov [DrawRectColor], al

    call  OS_DrawRectangle
   call IF_0
   call IF_2

   mov eax, [VALUE_lefty]


   mov ebx, [VALUE_Bot]


   add eax,ebx


   push eax


   pop eax


   mov [VALUE_botL], eax

   call IF_4
   call IF_6

   mov eax, [VALUE_righty]


   mov ebx, [VALUE_BotRight]


   add eax,ebx


   push eax


   pop eax


   mov [VALUE_botR], eax

   call IF_8
   call IF_9

   mov eax, [VALUE_bally]


   mov ebx, 10


   add eax,ebx


   push eax


   pop eax


   mov [VALUE_ballyh], eax

   call IF_18
   call IF_19
   call IF_20
   call IF_21
   call IF_22
    call  OS_GetMouseData
   mov ax, [mouse_cursor_x]
   mov word [VALUE_MouseX], ax
   mov ax, [mouse_cursor_y]
   mov word [VALUE_MouseY], ax

   mov eax, [VALUE_MouseX]
   mov [DrawRectX], eax


   mov eax, [VALUE_MouseY]
   mov [DrawRectY], eax


   mov eax, 10
   mov [DrawRectW], eax


   mov eax, 10
   mov [DrawRectH], eax


   mov al, VALUE_Colors.Blue
   mov [DrawRectColor], al

    call  OS_DrawRectangle

   mov eax, [VALUE_ballx]
   mov [DrawRectX], eax


   mov eax, [VALUE_bally]
   mov [DrawRectY], eax


   mov eax, 10
   mov [DrawRectW], eax


   mov eax, 10
   mov [DrawRectH], eax


   mov al, VALUE_Colors.White
   mov [DrawRectColor], al

    call  OS_DrawRectangle

   mov eax, 10
   mov [DrawRectX], eax


   mov eax, [VALUE_lefty]
   mov [DrawRectY], eax


   mov eax, 10
   mov [DrawRectW], eax


   mov eax, [VALUE_Bot]
   mov [DrawRectH], eax


   mov al, VALUE_Colors.LightGreen
   mov [DrawRectColor], al

    call  OS_DrawRectangle

   mov eax, 300
   mov [DrawRectX], eax


   mov eax, [VALUE_righty]
   mov [DrawRectY], eax


   mov eax, 10
   mov [DrawRectW], eax


   mov eax, [VALUE_BotRight]
   mov [DrawRectH], eax


   mov al, VALUE_Colors.LightGreen
   mov [DrawRectColor], al

    call  OS_DrawRectangle

   ret
OS_KeyboardEvent:
   mov al, [KeyCodeValue]
   mov byte [VALUE_key], al
   xor bx, bx
   mov bl, byte 'w'
   add bx, key_down_table
   mov ax, [bx]
   xor ah, ah
   mov byte [VALUE_downW], al
   xor bx, bx
   mov bl, byte 's'
   add bx, key_down_table
   mov ax, [bx]
   xor ah, ah
   mov byte [VALUE_downS], al
   xor bx, bx
   mov bl, byte 'o'
   add bx, key_down_table
   mov ax, [bx]
   xor ah, ah
   mov byte [VALUE_downO], al
   xor bx, bx
   mov bl, byte 'l'
   add bx, key_down_table
   mov ax, [bx]
   xor ah, ah
   mov byte [VALUE_downL], al

   ret
;{INCLUDE}

mouse_packet_byte     db 0
mouse_byte_states     db 0
mouse_byte_xmove     db 0
mouse_byte_ymove     db 0
mouse_cursor_x        dw 0
mouse_cursor_y        dw 0
key_down_table:
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
   db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

scan_code_table:
   db 0, 0, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 0, 0
   db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 0, 0
   db 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\'
   db 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' '
KeyCodeValue db 0
; drawing variables
DrawRectX dd 0
DrawRectY dd 0
DrawRectW dd 10
DrawRectH dd 10
DrawRectColor db 0xA
VALUE_hello db 'Hello, World!',13,10,0
VALUE_newline db 13,10,0
VALUE_downW db 0
VALUE_downS db 0
VALUE_downO db 0
VALUE_downL db 0
VALUE_ScreenW dd 320
VALUE_ScreenH dd 200
VALUE_MouseX dd 100
VALUE_MouseY dd 100
VALUE_lefty dd 50
VALUE_Bot dd 90
VALUE_BotRight dd 90
VALUE_botR dd 0
VALUE_botL dd 0
VALUE_direction dd 0
VALUE_ballspeed dd 1
VALUE_ballspeedy dd 1
VALUE_maxspeed dd 8
VALUE_paddleSpeed dd 2
VALUE_ballx dd 160
VALUE_bally dd 100
VALUE_ballyh dd 110
VALUE_ballyDir dd 0
VALUE_leftColx dd 50
VALUE_rightColx dd 50
VALUE_directr dd 1
VALUE_righty dd 50
VALUE_key dd 0
VALUE_leftPoints dd 0
VALUE_rightPoints dd 0
;{VARIABLE}

