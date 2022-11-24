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
	MOV R0, [WrFlags]
	BTG R0,3
	MOV [WrFlags], R0

	MOV R0, F_3_kHz; slow down a bit
	MOV [Clock], R0

game_start:
	;initialize score
	MOV R0, 0
	MOV [2:0],R0
	MOV [2:1],R0

	MOV R5, 4 ; page
	MOV R2, 0 ; storage for the ball's bit

	MOV R0,R5  ; go to display page
	MOV [Page], R0

	MOV R6, 3
	MOV R7, 13
	MOV R8, PlatformRows
	MOV R5, R8
	MOV R9, R6 ; R9 = LAST POSITION

main:
	GOSUB check_keys
	GOSUB erase_char
	MOV R9, R6 ; update last x-pos
	GOSUB update_char
	CP R0, 1
	SKIP NZ, 2 ; skip 2 because `goto` is actually two instructions
	GOTO game_start
	GOSUB draw_char

	; generate next row
	GOSUB generate_row
	MOV R0, R1 ; set_bottom_row uses r0/r1 as the nibbles to display
	MOV R1, R2
	GOSUB set_bottom_row

	GOSUB shift_screen_up
	GOSUB update_score

	MOV R0, R5 ; r5 = how often to generate new row
	CP R0, 0
	SKIP Z, 1
	JR main
	MOV R5, R8
	JR main

get_badge_key:
	MOV R0,[KeyStatus]
	AND R0,0x6
	SKIP NZ,1
	RET R0,0xF
	MOV R0,[KeyReg]
	CP R0,KeyLeft
	SKIP NZ,1
	RET R0,1 ; left
	CP R0,KeyB
	SKIP NZ,1
	RET R0,2 ; b
	CP R0,KeyRight
	SKIP NZ,1
	RET R0,3 ; right
	RET R0,0xf ; some other key

check_keys:
	GOSUB get_badge_key
	CP R0, 0xf ; no key pressed
	SKIP NZ, 1 ; some key is pressed, so skip
	JR check_in  ; no badge key pressed, so now try IN port (Nintendo Super System)
; check which badge key
	CP R0, 1 ; left 
	SKIP NZ, 1
	JR ck_left
	CP R0, 3 ; right
	SKIP NZ, 1
	JR ck_right
	CP R0, 2 ; b
	SKIP NZ, 1
	JR ck_b

check_in:
	BIT R3, 0  ; r3 is actually "in" reg
	SKIP NZ, 1
	JR ck_left
	BIT R3, 1
	SKIP NZ, 1
	JR ck_right
	BIT R3, 2
	SKIP NZ, 1
	JR ck_b
	RET R0, 0

ck_b:
	MOV R0, PlatformRows
	MOV R8, R0
	RET R0, 0

ck_right:
	MOV R0, R6
	CP R0, 7
	SKIP Z, 1
	INC R6
	RET R0, 0

ck_left:
	MOV R0, R6
	CP R0, 0
	SKIP Z, 1
	DEC R6
	RET R0, 0

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
ssu_loop:
	MOV R0,[R1:R6]
	MOV [R1:R7],R0
	MOV R0,[R2:R6]
	MOV [R2:R7],R0
	INC R6
	INC R7
	DSZ R8
	JR ssu_loop
	EXR 0
	RET R0, 0

generate_row:
	DEC R5
	SKIP Z, 1
	JR gr_nz
	AND R0, 0 ; clear carry
	MOV R0,[Random]
	RRC R0  ; logical shift right
	MOV R1, 1
	MOV R2, 0
	CP R0, 0
	SKIP NZ, 1
	JR gr_rnd_z
gr_shift: ; 8-bit left shift by r0 bits
	ADD R1, R1
	ADC R2, R2
	DSZ R0
	JR gr_shift
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

draw_char:
	EXR 6
	MOV R5, R6
	MOV R1, 4
	MOV R2, 5
	MOV R4, 0b1000
	MOV R3, 0b0000
	MOV R0, R5
	CP R0, 0
	SKIP NZ, 1
	JR dc_xpos_z
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
	MOV R0, R5
	CP R0, 0
	SKIP NZ, 1
	JR ec_xpos_z
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
	MOV R0, R5
	CP R0, 0
	SKIP NZ, 1
	JR uc_xpos_z
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
	MOV R8, 15
	GOSUB save_high_score
	CP R0, 1
	SKIP NZ, 1
	JR hs_loop
d_loop:
	MOV R0, 15 ; set to full bar
	MOV R1, 15
	GOSUB set_bottom_row
	GOSUB shift_screen_up
	DSZ R8
	JR d_loop
	JR d_check_button
hs_loop:
	MOV R6, 10 ; set to checkboard pattern
hs_inner:
	MOV R0, R6
	MOV R1, R0
	GOSUB set_bottom_row
	GOSUB shift_screen_up
	MOV R0, R6
	XOR R0, 0xF
	MOV R6, R0
	DSZ R8
	JR hs_inner
d_check_button:
	GOSUB get_badge_key
	CP R0, 0xf ; no key pressed
	SKIP NZ, 1 ; some key is pressed, so skip
	JR d_check_in  ; no badge key pressed, so now try IN port (Nintendo Super System)
; check which badge key
	CP R0, 2 ; b
	SKIP NZ, 1
	JR d_button_pushed
d_check_in:
	BIT R3, 2
	SKIP Z, 1
	JR d_check_button
d_button_pushed:
	; clear screen before restarting
	MOV R8, 15
d_clearscreen_loop:
	MOV R0, 00 ; set to empty
	MOV R1, 00
	GOSUB set_bottom_row
	GOSUB shift_screen_up
	DSZ R8
	JR d_clearscreen_loop
	EXR 6
	RET R0,1

update_score:
	EXR 0
	MOV R0, 0
	MOV R3, R0
	MOV R0, [2:0] ; low nibble
	MOV R1, R0
	MOV R0, [2:1] ; high nibble
	INC R1
	ADC R0, R3 ; 8-bit increment (add zero, with carry)
	; score = (r0:r1)
	MOV [2:1], R0
	MOV R0, R1
	MOV [2:0], R0
	EXR 0
	RET R0, 0

save_high_score:
	EXR 0
	MOV R0, [2:0] ; load curr score into r3:r4
	MOV R4, R0
	MOV R0, [2:1]
	MOV R3, R0
	MOV R0, [2:2] ; load high score into r1:r2
	MOV R2, R0
	MOV R0, [2:3]
	MOV R1, R0

	SUB R2,R4
	SKIP C, 3
	SBB R1,R3
	SKIP C, 1
	JR set_high_score
	EXR 0
	RET r0, 0

set_high_score:
	MOV R0, [2:0] ; load curr score into r4:r3
	MOV R1, R0
	MOV R0, [2:1]
	MOV [2:3], R0
	MOV R0, R1
	MOV [2:2], R0
	EXR 0
	RET R0, 1
