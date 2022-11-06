; symbols for special registers
Page        EQU 0xf0
Clock       EQU 0xf1
  F_250_kHz EQU 0
  F_100_kHz EQU 1
  F_30_kHz  EQU 2
  F_10_kHz  EQU 3
  F_3_kHz   EQU 4
  F_1_kHz   EQU 5
  F_500_Hz  EQU 6
  F_200_Hz  EQU 7
  F_100_Hz  EQU 8
  F_50_Hz   EQU 9
  F_20_Hz   EQU 10
  F_10_Hz   EQU 11
  F_5_Hz    EQU 12
  F_2_Hz    EQU 13
  F_1_Hz    EQU 14
  F_1_2_Hz  EQU 15
Sync        EQU 0xf2
WrFlags     EQU 0xf3
  LedsOff   EQU 3
  MatrixOff EQU 2
  InOutPos  EQU 1
  RxTxPos   EQU 0
RdFlags     EQU 0xf4
  Vflag     EQU 1
  UserSync  EQU 0       ; cleared after read
SerCtl      EQU 0xf5
  RxError   EQU 3       ; cleared after read
SerLow      EQU 0xf6
SerHigh     EQU 0xf7
Received    EQU 0xf8
AutoOff     EQU 0xf9
OutB        EQU 0xfa
InB         EQU 0xfb
KeyStatus   EQU 0xfc
  AltPress  EQU 3
  AnyPress  EQU 2
  LastPress EQU 1
  JustPress EQU 0       ; cleared after read
KeyReg      EQU 0xfd
Dimmer      EQU 0xfe
Random      EQU 0xff

; init
init: 
mov r5, 4 ; page
mov r2, 0 ; storage for the ball's bit

mov r0,r5  ; go to display page
mov [Page], r0

mov r0, F_1_kHz; slow down a bit
mov [Clock], r0

mov r5, 5
main:
gosub check_keys
gosub generate_row
mov r0, r1 ; set_bottom_row uses r0/r1 as the nibbles to display
mov r1, r2
gosub set_bottom_row
gosub shift_screen_up
mov r0, r5
cp r0, 0
skip nz, 1
mov R5, 5
goto main

check_keys:
mov R0, [0xFC] ; get keypress status
bit R0,0; ; tests if not pressed, in Z
skip z,3
mov R0, [0xF3]
btg R0,3
mov [0xF3], R0
ret r0, 0

set_bottom_row:
MOV R4,15 ; initial dest row
MOV R2,4  ; original page 1
MOV R3,5  ; original page 2
MOV [R2:R4],R0
MOV R0, R1
MOV [R3:R4],R0
RET R0, 0

shift_screen_up:
; shift all rows down by one
EXR 0
MOV R6,1  ; initial src row
MOV R7,0  ; initial dest row
MOV R1,4  ; original page 1
MOV R2,5  ; original page 2
MOV R8,15 ; number of rows to copy
loop:
MOV R0,[R1:R6] 
MOV [R1:R7],R0
MOV R0,[R2:R6]
MOV [R2:R7],R0
INC R6
INC R7
DSZ R8
JR loop

EXR 0
RET R0, 0

generate_row:
DEC R5
MOV R0,R5
CP R0, 0    
SKIP Z, 1  
JR gr_nz
and r0, 0 ; clear carry
mov r0,[Random]
rrc r0  ; logical shift right
mov r1, 1
mov r2, 0
shift: ; 8-bit left shift by r0 bits
add R1, R1
adc R2, R2
dsz r0
jr shift
MOV R0, R1 ; complement r1
XOR R0, 0xF
MOV R1, R0
MOV R0, R2 ; complement r2
XOR R0, 0xF
MOV R2, R0
RET R0, 0
gr_nz:
MOV R1, 0   
MOV R2, 0   
RET R0, 0
