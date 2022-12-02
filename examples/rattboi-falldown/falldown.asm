;;;;;;;;;;;;;;;;;;;;;;;;;
; Falldown
; by Bradon Kanyid / Rattboi
; MIT License 2022
;
; Falldown game
; 
; Badge Controls:
;   mode        : Left
;   data in     : Right
;   operand y 1 : Restart
; 
; Also can be controlled via inputs on IN port (like the NSS controller)
;   bit 0: Left
;   bit 1: Right
;   bit 2: Restart
;
; Demo video: https://www.youtube.com/watch?v=X-XJmlMLx7k&t=2900s
;
; https://github.com/rattboi/2022-Supercon6-Badge-Tools
;;;;;;;;;;;;;;;;;;;;;;;;;

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
ScrollSpeed EQU 6
ScorePage  EQU 2
ScoreLo    EQU 0
ScoreUp    EQU 1
HiScoreLo  EQU 2
HiScoreUp  EQU 3
Speed      EQU 4

; init
init: 
	; initialize high score
	MOV R0, 0
	MOV [ScorePage:HiScoreLo],R0
	MOV [ScorePage:HiScoreUp],R0


	; disable other LEDs
	MOV R0, [WrFlags]
	BTG R0, LedsOff
	MOV [WrFlags], R0

	MOV R0, F_250_kHz ; run at fastest speed (using usersync)
	MOV [Clock], R0

game_start:
	;initialize score
	MOV R0, 0
	MOV [ScorePage:ScoreLo],R0
	MOV [ScorePage:ScoreUp],R0

	; set initial speed
	MOV R0, 14 
	MOV [ScorePage:Speed], R0

	MOV R0, 4 ; go to display page
	MOV [Page], R0

	MOV R0, 5
	MOV	[Sync],R0

	MOV R6, 3
	MOV R7, 13
	MOV R8, PlatformRows
	MOV R5, R8
	MOV R9, R6 ; R9 = LAST POSITION

main:
	GOSUB check_keys
	MOV R9, R6 ; update last x-pos
	GOSUB update_char
	CP R0, 1 ; game over?
	SKIP NE, .keep_going ;no game over
	GOTO game_start
.keep_going:
	GOSUB draw_char

	; generate next row
	GOSUB generate_row
	MOV R0, R1 ; set_bottom_row uses r0/r1 as the nibbles to display
	MOV R1, R2
	GOSUB set_bottom_row

	; wait for (speed) user syncs
	MOV R0, [ScorePage:Speed]
	MOV R1, R0
	GOSUB user_sync

	GOSUB shift_screen_up
	GOSUB erase_char

	MOV R0, R5 ; r5 = how often to generate new row
	CP R0, 0
	SKIP Z, .reset_row_count
	JR main
.reset_row_count:
	GOSUB update_score
	MOV R5, R8
	JR main

get_badge_key:
	MOV R0,[KeyStatus]
	AND R0,0x6
	SKIP NE,.key_pressed
	RET R0,0xF
.key_pressed:
	MOV R0,[KeyReg]
	CP R0,KeyLeft
	SKIP NE,.not_left
	RET R0,1 ; left
.not_left:
	CP R0,KeyB
	SKIP NE,.not_b
	RET R0,2 ; b
.not_b:
	CP R0,KeyRight
	SKIP NE,.not_right
	RET R0,3 ; right
.not_right:
	RET R0,0xf ; some other key

check_keys:
	GOSUB get_badge_key
	CP  R0, 0xf ; no key pressed
	SKIP NE, .which_badge_key ; some key is pressed, so skip
	JR .check_in  ; no badge key pressed, so now try IN port (Nintendo Super System)
; check which badge key
.which_badge_key:
	CP  R0, 1 ; left 
	SKIP NE, .not_badge_left
	JR .ck_left
.not_badge_left:
	CP R0, 3 ; right
	SKIP NE, .not_badge_right
	JR .ck_right
.not_badge_right:
	CP R0, 2 ; b
	SKIP NE, .check_in
	JR .ck_b
.check_in:
	BIT RS, 0  ; r3 is actually "in" reg
	SKIP NE, .not_left
	JR .ck_left
.not_left:
	BIT RS, 1
	SKIP NE, .not_right
	JR .ck_right
.not_right:
	BIT RS, 2
	SKIP NE, .not_b
	JR .ck_b
.not_b:
	RET R0, 0
.ck_b:
	MOV R0, PlatformRows
	MOV R8, R0
	RET R0, 0
.ck_right:
	MOV R0, R6
	CP  R0, 7
	SKIP EQ, 1
	INC R6
	RET R0, 0
.ck_left:
	MOV R0, R6
	CP  R0, 0
	SKIP EQ, 1
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
.loop:
	MOV R0,[R1:R6]
	MOV [R1:R7],R0
	MOV R0,[R2:R6]
	MOV [R2:R7],R0
	INC R6
	INC R7
	DSZ R8
	JR .loop
	EXR 0
	RET R0, 0

generate_row:
	DEC R5
	SKIP EQ, 3 ; .not_empty
	; empty row, return zeros
	MOV R1, 0
	MOV R2, 0
	RET R0, 0
.not_empty:
	MOV R0, [Random]
	LSR R0
	MOV R1, 1
	MOV R2, 0
	CP  R0, 0
	SKIP NE, 1
	JR .shift_done
.shift: ; 8-bit left shift by r0 bits
	ADD R1, R1
	ADC R2, R2
	DSZ R0
	JR .shift
.shift_done:
	CPL R0, R1
	MOV R1, R0
	CPL R0, R2
	MOV R2, R0
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
	SKIP NZ, .shiftloop
	JR .noshift
.shiftloop:
	AND R0, 0
	RRC R4
	RRC R3
	DSZ R5
	JR .shiftloop
.noshift:
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
	MOV R0, R6
	MOV R1, 4
	MOV R2, 5
	MOV R4, 0b1000
	MOV R3, 0b0000
	CP  R0, 0
	SKIP NE, 1
	JR .noshift
.shiftloop:
	AND R0, 0xF
	RRC R4
	RRC R3
	DSZ R0
	JR .shiftloop
.noshift:
	MOV R5, R7
	INC R5
	; get left side, and invert
	MOV R0, R4
	CP  R0, 0
	SKIP NE, 1
	JR .testright
	MOV R0, [R2:R5] ;0000
	CPL R0          ;1111
	AND R0, R4      ;0100 = 0000 = z = collision
	SKIP NE, 1
	JR .collision
.testright:
	; get right side and invert
	MOV R0, R3
	CP  R0, 0
	SKIP NZ, 1
	JR .no_collision
	MOV R0, [R1:R5]
	CPL R0
	AND R0, R3
	SKIP NZ, 1
	JR .collision
.no_collision:
	MOV R0, R7
	CP  R0, 13
	SKIP EQ, 1
	INC R7
	EXR 6
	RET R0, 0
.collision:
	DEC R7
	SKIP NC, .dead ; NC mean R7 is now 15, so we wrapped, and are thus dead
	EXR 6
	RET R0, 0
.dead:
	MOV R8, 0  ; # of rows to scroll/display (effectively 16, with DSZ)
	GOSUB check_high_score
	CP  R0, 1
	SKIP NE, .loop
	JR .checkerboard
.loop:
	MOV R0, 15 ; set to full bar
	MOV R1, 15
	GOSUB set_bottom_row
	GOSUB shift_screen_up
	MOV R0, ScrollSpeed
	MOV R1, R0
	GOSUB user_sync
	DSZ R8
	JR .loop
	JR .wait_for_button
.checkerboard:
	MOV R6, 10 ; set to checkboard pattern
.checkerboard_loop:
	CPL R0, R6
	MOV R6, R0
	GOSUB shift_screen_up
	MOV R0, R6
	MOV R1, R0
	GOSUB set_bottom_row
	MOV R0, ScrollSpeed
	MOV R1, R0
	GOSUB user_sync
	DSZ R8
	JR .checkerboard_loop
	MOV R4, 15
.wait_for_button:
	MOV R0, ScrollSpeed
	MOV R1, R0
	GOSUB user_sync
	MOV R0, R4
	MOV [Dimmer], R0
	DEC R0
	MOV R4, R0
	GOSUB get_badge_key
	CP R0, 0xf    ; no key pressed
	SKIP NE, 1    ; some key is pressed, so skip
	JR .check_in  ; no badge key pressed, so now try IN port (Nintendo Super System)
  ; check which badge key
	CP R0, 2 ; b
	SKIP NZ, 1
	JR .button_pushed
.check_in:
	BIT RS, 2 ; check for IN port bit 2 (b button)
	SKIP EQ, .button_pushed
	JR .wait_for_button
.button_pushed:
	MOV R0, 15
	MOV [Dimmer], R0
	; clear screen before restarting
	MOV R8, 0
.clearscreen_loop:
	MOV R0, 00 ; set to empty
	MOV R1, 00
	GOSUB set_bottom_row
	GOSUB shift_screen_up
	MOV R0, ScrollSpeed
	MOV R1, R0
	GOSUB user_sync
	DSZ R8
	JR .clearscreen_loop
	EXR 6
	RET R0,1

update_score:
	EXR 0
	MOV R0, 0
	MOV R3, R0
	MOV R0, [ScorePage:ScoreLo] ; low nibble
	MOV R1, R0
	MOV R0, [ScorePage:ScoreUp] ; high nibble
	INC R1
	ADC R0, R3 ; 8-bit increment (add zero, with carry)
	; score = (r0:r1)
	MOV [ScorePage:ScoreUp], R0
	MOV R0, R1
	MOV [ScorePage:ScoreLo], R0
	CP R0, 0
	SKIP NZ, .return
	MOV R0, [ScorePage:Speed]
	DEC R0
	MOV [ScorePage:Speed], R0
.return:
	EXR 0
	RET R0, 0

check_high_score:
	EXR 0
	MOV R0, [ScorePage:ScoreLo] ; load curr score into r3:r4
	MOV R4, R0
	MOV R0, [ScorePage:ScoreUp]
	MOV R3, R0
	MOV R0, [ScorePage:HiScoreLo] ; load high score into r1:r2
	MOV R2, R0
	MOV R0, [ScorePage:HiScoreUp]
	MOV R1, R0

	; R1:R2 = hiscore
	; R3:R4 = score

	SUB R3, R1 ; MSB(score - hiscore)
	SKIP  Z, .maybe_highscore
	SKIP NC, .no_highscore ; MSB(hiscore >= score)
	JR .set_highscore
.maybe_highscore:
	SUB R4, R2 ; LSB(hiscore - score)
	SKIP Z, .no_highscore
	SKIP C, .set_highscore
.no_highscore:
	EXR 0
	RET r0, 0
.set_highscore:
	MOV R0, [ScorePage:ScoreLo] ; load curr score into r1:r0
	MOV R1, R0
	MOV R0, [ScorePage:ScoreUp]
	MOV [ScorePage:HiScoreUp], R0 ; store r1:r0 -> hiscore
	MOV R0, R1
	MOV [ScorePage:HiScoreLo], R0
	EXR 0
	RET R0, 1

user_sync:
	MOV	R0,[RdFlags]
	BIT	R0, 0	; Bit 0 is UserSync.
	SKIP NE,.sync
	JR	user_sync
.sync:
	DSZ r1
	JR  user_sync
	RET	R0, 0

