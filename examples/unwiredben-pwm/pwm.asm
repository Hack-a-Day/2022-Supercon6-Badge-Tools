; pwm
; 
; a test of how effective simple PWM control of the LEDS in the memory
; display can be. In my testing, I only got an effective brightness
; reduction at 1/8, but at the cost of a flickery line.  I don't think
; this is an effective technique.

init:		; Ben Combee, 2022 

	mov r0, 2	; Set matrix page
	mov [0xF0], r0

	mov r0, 1 	; Set CPU speed to 100 kHz
	mov [0xF1], r0

main:

	XOR R2, R2 ; R2 has current cycle (0-3)
	MOV R0, 2  ; R3 has right page
	MOV R3, R0
	MOV R0, 3  ; R4 has left page
	MOV R4, R0

loop_start:
	XOR R5, R5 ; R5 has row

	MOV PC, [0x10]
	MOV JSR, R2
	GOSUB draw_row

	MOV PC, [0x11]
	MOV JSR, R2
	GOSUB draw_row

	MOV PC, [0x12]
	MOV JSR, R2
	GOSUB draw_row

	MOV PC, [0x13]
	MOV JSR, R2
	GOSUB draw_row

	MOV PC, [0x14]
	MOV JSR, R2
	GOSUB draw_row

	MOV PC, [0x15]
	MOV JSR, R2
	GOSUB draw_row

	MOV PC, [0x16]
	MOV JSR, R2
	GOSUB draw_row

	MOV PC, [0x17]
	MOV JSR, R2
	GOSUB draw_row

	INC R2		; go to next cycle
	BCLR R2,3 	; limit range to 0-7
	GOTO loop_start

draw_row:
	MOV [R3:R5], R0
	MOV [R4:R5], R0
	INC R5
	MOV [R3:R5], R0
	MOV [R4:R5], R0
	INC R5
	RET R0, 0

ORG 0x100
light_1_8_table:
	RET R0, 0b0000
	RET R0, 0b0001
	RET R0, 0b0000
	RET R0, 0b0010
	RET R0, 0b0000
	RET R0, 0b0100
	RET R0, 0b0000
	RET R0, 0b1000

ORG 0x110
light_1_4_table:
	RET R0, 0b0001
	RET R0, 0b0010
	RET R0, 0b0100
	RET R0, 0b1000
	RET R0, 0b0001
	RET R0, 0b0010
	RET R0, 0b0100
	RET R0, 0b1000

ORG 0x120
light_3_8_table:
	RET R0, 0b0101
	RET R0, 0b1010
	RET R0, 0b0100
	RET R0, 0b1001
	RET R0, 0b0010
	RET R0, 0b0100
	RET R0, 0b1001
	RET R0, 0b0010

ORG 0x130
light_1_2_table:
	RET R0, 0b1010
	RET R0, 0b0101
	RET R0, 0b1010
	RET R0, 0b0101
	RET R0, 0b1010
	RET R0, 0b0101
	RET R0, 0b1010
	RET R0, 0b0101

ORG 0x140
light_5_8_table:
	RET R0, 0b1010
	RET R0, 0b0101
	RET R0, 0b1011
	RET R0, 0b0110
	RET R0, 0b1101
	RET R0, 0b1011
	RET R0, 0b0110
	RET R0, 0b1101

ORG 0x150
light_3_4_table:
	RET R0, 0b1110
	RET R0, 0b1101
	RET R0, 0b1011
	RET R0, 0b0111
	RET R0, 0b1110
	RET R0, 0b1101
	RET R0, 0b1011
	RET R0, 0b0111

ORG 0x160
light_7_8_table:
	RET R0, 0b1111
	RET R0, 0b1110
	RET R0, 0b1111
	RET R0, 0b1101
	RET R0, 0b1111
	RET R0, 0b1011
	RET R0, 0b1111
	RET R0, 0b0111

ORG 0x170
light_full_table:
	RET R0, 0b1110
	RET R0, 0b1111
	RET R0, 0b1111
	RET R0, 0b1111
	RET R0, 0b1110
	RET R0, 0b1111
	RET R0, 0b1111
	RET R0, 0b1111
