ORG 0x7E00

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

    call  OS16BIT_SetupInteruptTimer
;{CODE}

   jmp $

OS16BIT_timer_interrupt:
   call OS16BIT_TimerEvent
   mov al, 0x20
   out 0x20, al
   iret
OS16BIT_SetupInteruptTimer:
   cli    ; Set up the PIT
   mov al, 00110100b    ; Channel 0, lobyte/hibyte, rate generator
   out PIT_COMMAND, al
       ; Set the divisor
   mov ax, DIVISOR
   out PIT_CHANNEL_0, al    ; Low byte
   mov al, ah
   out PIT_CHANNEL_0, al    ; High byte
   ; Set up the timer ISR
   mov word [0x0020], OS16BIT_timer_interrupt
   mov word [0x0022], 0x0000    ; Enable interrupts
   sti
   ret
OS16BITVideo_EnableVideoMode:
   mov ax, 0x13
   int 0x10
   ret
OS16BITVideo_DrawRectangle:
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
   mov eax, [VALUE_direction]
   cmp eax, 0
   je IF_0_CONTENT
   ret
IF_0_CONTENT:

   mov eax, [VALUE_lefty]
   sub eax,1
   mov [VALUE_lefty], eax

;{IF CONTENT}
   ret
IF_1:
   mov eax, [VALUE_direction]
   cmp eax, 1
   je IF_1_CONTENT
   ret
IF_1_CONTENT:

   mov eax, [VALUE_lefty]
   add eax,1
   mov [VALUE_lefty], eax

;{IF CONTENT}
   ret
IF_2:
   mov eax, [VALUE_lefty]
   cmp eax, 0
   jg IF_2_CONTENT
   ret
IF_2_CONTENT:
   call IF_0
   call IF_1
;{IF CONTENT}
   ret
IF_3:
   mov eax, [VALUE_lefty]
   cmp eax, 1
   je IF_3_CONTENT
   ret
IF_3_CONTENT:

   mov eax, 1
   mov [VALUE_direction], eax

;{IF CONTENT}
   ret
IF_4:
   mov eax, [VALUE_lefty]
   cmp eax, [VALUE_leftBot]
   je IF_4_CONTENT
   ret
IF_4_CONTENT:

   mov eax, 0
   mov [VALUE_direction], eax

;{IF CONTENT}
   ret
OS16BIT_TimerEvent:

   mov eax, 10
   mov [DrawRectX], eax


   mov eax, [VALUE_lefty]
   mov [DrawRectY], eax


   mov eax, 10
   mov [DrawRectW], eax


   mov eax, 100
   mov [DrawRectH], eax


   mov al, VALUE_Colors.Black
   mov [DrawRectColor], al

    call  OS16BITVideo_DrawRectangle
   call IF_2
   call IF_3
   call IF_4

   mov eax, 10
   mov [DrawRectX], eax


   mov eax, [VALUE_lefty]
   mov [DrawRectY], eax


   mov eax, 10
   mov [DrawRectW], eax


   mov eax, 100
   mov [DrawRectH], eax


   mov al, VALUE_Colors.LightGreen
   mov [DrawRectColor], al

    call  OS16BITVideo_DrawRectangle

   ret
;{INCLUDE}

; drawing variables
DrawRectX dd 0
DrawRectY dd 0
DrawRectW dd 10
DrawRectH dd 10
DrawRectColor db 0xA
VALUE_hello db 'Hello, World!',13,10,'',0
VALUE_newline db '',13,10,'',0
VALUE_lefty dd 50
VALUE_leftBot dd 100
VALUE_direction dd 0
VALUE_key dd 0
;{VARIABLE}

