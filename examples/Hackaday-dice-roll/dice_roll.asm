init:		; Tom Nardi, 2022 
mov r0, 2	; Set matrix page
mov [0xF0], r0

mov r0, 5 	; Set CPU speed
mov [0xF1], r0

main:
gosub getroll	; Put random number in R1
mov r2, 1	; Subtract 1 from result to get mem address
sub r1, r2
gosub drawdie	; Start drawing routine
jr -1		; Loop forever

getroll:	; Get random number between 1 and 6 
mov r0, [0xff]	; Read from PRNG
cp r0, 7	; Check if R0 less than or equal to 9
skip nc, 1	; Skip jump if previous is true
jr -4		; Skip back to PRNG read
cp r0, 0	; Check if R0 equal 0
skip nz, 1	; Skip jump is previous is true
jr -7		; Jump back to PRNG read
mov r1, r0	; Copy R0 to R1
ret r0, 0	; Return from sub

drawdie:
mov pch, 1	; Set high jump coord
mov pcm, r1	; Mid address maps to die face
mov jsr, 0	; Execute jump with lowest nibble, R0 now loaded with 4 bits

mov r7, 0	; Init counter
mov r5, 0	; Set initial row
mov r3, 2	; Set right matrix page
mov r4, 3	; Set left matrix page

mov [r3:r5], r0 ; Draw right-side nibble
inc jsr		; Inc lowest bit reads next nibble
mov [r4:r5], r0	; Draw left-side nibble
inc r7 		; Inc counter
mov r0, r7	; Move counter, can only compare to R0
cp r0, 8	; Check if we've looped 8 times
skip z, 3	; Skip next 3 lines if true 
inc r5		; Move to next row
inc jsr		; Read next nibble
jr -10		; Loop around
ret r0, 0	; Return from sub

org 0x100
dicegfx:	; Graphics data
	BYTE	0b00000000	; 1
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00011000
	BYTE	0b00011000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000011	; 2
	BYTE	0b00000011
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b11000000
	BYTE	0b11000000

	BYTE	0b00000011	; 3
	BYTE	0b00000011
	BYTE	0b00000000
	BYTE	0b00011000
	BYTE	0b00011000
	BYTE	0b00000000
	BYTE	0b11000000
	BYTE	0b11000000

	BYTE	0b11000011	; 4
	BYTE	0b11000011
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b11000011
	BYTE	0b11000011

	BYTE	0b11000011	; 5
	BYTE	0b11000011
	BYTE	0b00000000
	BYTE	0b00011000
	BYTE	0b00011000
	BYTE	0b00000000
	BYTE	0b11000011
	BYTE	0b11000011

	BYTE	0b11000011	; 6
	BYTE	0b11000011
	BYTE	0b00000000
	BYTE	0b11000011
	BYTE	0b11000011
	BYTE	0b00000000
	BYTE	0b11000011
	BYTE	0b11000011	

; EOF
