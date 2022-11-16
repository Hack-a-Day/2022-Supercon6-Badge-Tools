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

; badge key aliases
KeyLeft  EQU	0	  ; MODE
KeyB     EQU	12	; operand y 1
KeyRight EQU	13	; Data In

; user equs
PlatformRows EQU 4

; init
init: 
; initialize high score
MOV R0, 0
MOV [2:2],R0
MOV [2:3],R0

; disable other LEDs
mov R0, [WrFlags]
btg R0,3
mov [WrFlags], R0

mov r0, F_3_kHz; slow down a bit
mov [Clock], r0

game_start:
;initialize score
MOV R0, 0
MOV [2:0],R0
MOV [2:1],R0

mov r5, 4 ; page
mov r2, 0 ; storage for the ball's bit

mov r0,r5  ; go to display page
mov [Page], r0

mov r6, 3
mov r7, 13
mov r8, PlatformRows
mov r5, r8
mov r9, r6 ; r9 = last position

main:
gosub check_keys
gosub erase_char
mov r9, r6 ; update last x-pos
gosub update_char
cp r0, 1
skip nz, 2 ; skip 2 because `goto` is actually two instructions
goto game_start
gosub draw_char

; generate next row
gosub generate_row
mov r0, r1 ; set_bottom_row uses r0/r1 as the nibbles to display
mov r1, r2
gosub set_bottom_row

gosub shift_screen_up
gosub update_score

mov r0, r5 ; r5 = how often to generate new row
cp r0, 0
skip z, 1
jr main
mov r5, r8
jr main

get_badge_key:
	mov	r0,[KeyStatus]
	and	r0,0x6
	skip	nz,1
	ret	r0,0xf
	mov	r0,[KeyReg]
	cp	r0,KeyLeft
	skip	nz,1
	ret	r0,1	 ; left
	cp	r0,KeyB
	skip	nz,1
	ret	r0,2	 ; b
	cp	r0,KeyRight
	skip	nz,1
	ret	r0,3	 ; right
	ret	r0,0xf ; some other key

check_keys:
	gosub get_badge_key
	cp r0, 0xf ; no key pressed
	skip nz, 1 ; some key is pressed, so skip
	jr check_in  ; no badge key pressed, so now try IN port (Nintendo Super System)
; check which badge key
	cp r0, 1 ; left 
	skip nz, 1
	jr ck_left
	cp r0, 3 ; right
	skip nz, 1
	jr ck_right
	cp r0, 2 ; b
	skip nz, 1
	jr ck_b

check_in:
bit r3, 0  ; r3 is actually "in" reg
skip nz, 1
jr ck_left
bit r3, 1
skip nz, 1
jr ck_right
bit r3, 2
skip nz, 1
jr ck_b
ret r0, 0

ck_b:
mov r0, PlatformRows
mov r8, r0
ret r0, 0

ck_right:
mov r0, r6
cp r0, 7
skip z, 1
inc r6
ret r0, 0

ck_left:
mov r0, r6
cp r0, 0
skip z, 1
dec r6
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
SKIP Z, 1  
JR gr_nz
and r0, 0 ; clear carry
mov r0,[Random]
rrc r0  ; logical shift right
mov r1, 1
mov r2, 0
cp r0, 0
skip nz, 1
jr gr_rnd_z
gr_shift: ; 8-bit left shift by r0 bits
add R1, R1
adc R2, R2
dsz r0
jr gr_shift
gr_rnd_z:
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

calculate_pos:
EXR 6
MOV R5, R6
MOV R4, 0b1000
MOV R3, 0b0000
mov r0, r5
cp r0, 0
skip nz, 1
jr cp_xpos_z
cp_shiftloop:
AND R0, 0
RRC R4
RRC R3
DSZ R5
JR cp_shiftloop
cp_xpos_z:
MOV R0, R4
MOV [1:0],R0 ; write left-side to [1:0]
INC R2
MOV R0, R3
MOV [1:1],R0 ; write right-side to [1:1]
EXR 6
RET R0, 0

draw_char:
EXR 6
MOV R5, R6
MOV R1, 4
MOV R2, 5
MOV R4, 0b1000
MOV R3, 0b0000
mov r0, r5
cp r0, 0
skip nz, 1
jr dc_xpos_z
dc_shiftloop:
AND R0, 0
RRC R4
RRC R3
DSZ R5
JR dc_shiftloop
dc_xpos_z:
MOV R0,[R2:R7]
OR R0,R4
MOV [R2:R7],R0
MOV R0,[R1:R7]
OR R0,R3
MOV [R1:R7],R0
EXR 6
RET R0, 0

erase_char:
EXR 6
MOV R5, R9
MOV R1, 4
MOV R2, 5
MOV R4, 0b1000
MOV R3, 0b0000
mov r0, r5
cp r0, 0
skip nz, 1
jr ec_xpos_z
ec_shiftloop:
AND R0, 0
RRC R4
RRC R3
DSZ R5
JR ec_shiftloop
ec_xpos_z:
MOV R5,R7
DEC R5
MOV R0,[R2:R5]
XOR R0,R4
MOV [R2:R5],R0
MOV R0,[R1:R5]
XOR R0,R3
MOV [R1:R5],R0
EXR 6
RET R0, 0

update_char:
	EXR 6
	MOV R5, R6
	MOV R1, 4
	MOV R2, 5
	MOV R4, 0b1000
	MOV R3, 0b0000
	mov r0, r5
	cp r0, 0
	skip nz, 1
	jr uc_xpos_z
uc_shiftloop:
	AND R0, 0
	RRC R4
	RRC R3
	DSZ R5
	JR uc_shiftloop
uc_xpos_z:
	MOV R5,R7
	INC R5

; get left side, and invert
	MOV R0,R4
	CP R0, 0
	SKIP NZ, 1
	JR uc_testright
	MOV R0,[R2:R5] ;0000
	XOR R0, 0xF    ;1111
	AND R0,R4      ;0100 = 0000 = z = collision
	SKIP NZ, 1    
	JR collision

uc_testright:
; get right side and invert
	MOV R0,R3
	CP R0, 0
	SKIP NZ, 1
	JR no_collision
	MOV R0,[R1:R5]
	XOR R0, 0xF
	AND R0,R3
	SKIP NZ, 1
	JR collision

no_collision:
	MOV R0,R7
	CP R0, 13
	SKIP Z, 1
	INC R7
	EXR 6
	RET R0, 0

collision:
	DEC R7
	MOV R0, R7
	CP R0, 15 ; wrapped, so dead
	SKIP NZ, 1
	JR dead
	EXR 6
	RET R0, 0

dead:
	mov r8, 15
	gosub save_high_score
	cp r0, 1
	skip nz, 1
	jr hs_loop
d_loop:
	mov r0, 15 ; set to full bar
	mov r1, 15 
	gosub set_bottom_row
	gosub shift_screen_up
	dsz r8
	JR d_loop
	jr d_check_button
hs_loop:
	mov r6, 10 ; set to checkboard pattern
hs_inner:
	mov r0, r6
	mov r1, r0
	gosub set_bottom_row
	gosub shift_screen_up
	mov r0, r6
	xor r0, 0xF
	mov r6, r0
	dsz r8
	JR hs_inner
d_check_button:
	gosub get_badge_key
	cp r0, 0xf ; no key pressed
	skip nz, 1 ; some key is pressed, so skip
	jr d_check_in  ; no badge key pressed, so now try IN port (Nintendo Super System)
; check which badge key
	cp r0, 2 ; b
	skip nz, 1
	jr d_button_pushed
d_check_in:
bit r3, 2
skip z, 1
JR d_check_button
d_button_pushed:
; clear screen before restarting
mov r8, 15
d_clearscreen_loop:
mov r0, 00 ; set to empty
mov r1, 00
gosub set_bottom_row
gosub shift_screen_up
dsz r8
JR d_clearscreen_loop
EXR 6
RET R0,1

update_score:
EXR 0
mov r0, 0
mov r3, r0
MOV r0, [2:0] ; low nibble
MOV r1, r0 
MOV r0, [2:1] ; high nibble
INC r1
ADC r0, r3 ; 8-bit increment (add zero, with carry)
; score = (r0:r1)
MOV [2:1], r0
MOV r0, r1
MOV [2:0], r0
EXR 0
RET r0, 0

save_high_score:
EXR 0
MOV r0, [2:0] ; load curr score into r3:r4
MOV r4, r0
MOV r0, [2:1]
MOV r3, r0
MOV r0, [2:2] ; load high score into r1:r2
MOV r2, r0
MOV r0, [2:3]
MOV r1, r0

sub r2,r4
skip c, 3
sbb r1,r3
skip c, 1
JR set_high_score
EXR 0
RET r0, 0

set_high_score:
MOV r0, [2:0] ; load curr score into r4:r3
MOV r1, r0
MOV r0, [2:1]
MOV [2:3], r0
MOV r0, r1
MOV [2:2], r0
EXR 0
RET r0, 1
