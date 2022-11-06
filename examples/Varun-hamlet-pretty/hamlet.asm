
; r1 ascii lo
; r2 ascii hi
; r3 text ptr lo
; r4 text ptr next
; r5 text prt hi
; r6 char gen ptr lo
; r7 char gen ptr next
; r8 char gen ptr hi
; r9 loop count

display:
	mov	r0,10	        ; 0  sync N
	mov 	[15:2],r0	; 1  ---> Sync SFR
	mov	r0,4	        ; 2  page 4
	mov 	[15:0],r0	; 3  ---> Page SFR
; adr 4
	mov	r3,0	        ; 4
	mov	r4,0	        ; 5
	mov	r5,0x6	        ; 6  text pointer r345, start at 0x600
; adr 7
; gets new character from text (pointer r345) and calculates column addr
; read char @ r345 to r12
	mov	pch,r5	        ; 7
	mov	pcm,r4	        ; 8
	mov	jsr,r3	        ; 9  call (read char from ASCII text)  ----------->
	mov	r1,r0	        ; A  r1 ascii char low nib
	inc	jsr	        ; B  call (read char from ASCII text)  ----------->
	mov	r2,r0	        ; C  r2 ascii char high nib
; char in r1 (low) r2 (high)
	and	r0,r1	        ; D  just test for ascii text terminator 0xFF
	inc	r0	        ; E
	mov 	pc,[0]	        ; F
	skip	NZ,0b01	        ; 10  nz,1
	mov	pcl,4	        ; 11  jump to 004 (start)  ----------->


; r1,2-0x20 ---> r1,2
	dec	r2	        ; 12  readjust ASCII chargen table for -0x20
	dec	r2	        ; 13  readjust ASCII chargen table for -0x20
; r1,2 x 12 ---> r6,7,8
	add	r1,r1	        ; 14  x2
	adc	r2,r2	        ; 15  x2
	mov	r6,r1	        ; 16  r6 <--- r1 (r678 text pointer)
	mov	r7,r2	        ; 17  r7 <--- r2 (r678 text pointer)
	mov	r8,0	        ; 18  r8 <--- 0  (r678 text pointer)
	add	r6,r6	        ; 19  x4
	adc	r7,r7	        ; 1A  x4
	adc	r8,r8	        ; 1B  x4
	add	r6,r1	        ; 1C  x6
	adc	r7,r2		; 1D  x6
	adc	r8,pch	        ; 1E  x6????
	add	r6,r6	        ; 1F  x12 (12 nibbles per character)
	adc	r7,r7	        ; 20  x12 (12 nibbles per character)
	adc	r8,r8	        ; 21  x12 (addc,0)

; r6,7,8 + 0x100 ---> r6,7,8
	mov	r0,1	        ; 22
	add	r8,r0	        ; 23

; get the number of columns for the character we need to draw (TODO: renumber addresses and calls)
	mov	pc,[6]		; 24
	mov	jsr,3		; 25 call 0x063 --> (get the width of the char for char gen)
	mov 	r0,[2:15]	; 26 should have the character width(-1) and if not check page 3
	mov	r9, r0		; 27
	inc	r9		; 28 correct the width
	mov	r0,2		; 29
	add	r6,r0		; 2A
	mov	r0,0		; 2B
	adc	r7,r0		; 2C
	adc	r8,r0		; 2D increment by one byte so that we get the first row of real char data
	mov	pc,[3]	        ; 2E  subroutine @ 0x03F
	mov	jsr,15	        ; 2F  call  0x03F -----------> (shift 5 columns from char gen)
	dsz	r9	        ; 30
	jr	-4	        ; 31  loop

	mov	r6,1	        ; 32
	mov	r7,0	        ; 33
	mov	r8,1	        ; 34  point to blank (between chars)
	mov 	pc,[3]	        ; 35  subroutine @ 0x03F
	mov	jsr,15	        ; 36  call  0x03F -----------> (shift 1 column, space between chars)

	inc	r3	        ; 37  next char (one char = 2 nibbles)
	inc	r3	        ; 38  next char (one char = 2 nibbles)
	skip	NZ,0b11	        ; 39  if nibble overflow, then nz,3
	inc	r4	        ; 3A
	skip	NZ,0b01	        ; 3B  if nibble overflow, then nz,1
	inc	r5	        ; 3C

	mov 	pc,[0]	        ; 3D
	mov	pcl,7	        ; 3E  jump to 007 (loop)  ----------->

; adr 03F
; (subroutine) shifts and loads one column (pointer r6r7r8)
; wait sync
	mov 	r0,[15:4]	; 3F  RdFlags
	and	r0,0b0001	; 40  Bit #0 = UserSync
	skip	NZ,0b01	        ; 41  nz,1
	jr	-4	        ; 42  loop

	mov	pch,r8	        ; 43
	mov	pcm,r7	        ; 44
	mov	jsr,r6	        ; 45  call (read from char gen)  ----------->
	mov 	[2:15],r0	; 46
	inc	jsr	        ; 47  call (read from char gen)  ----------->
	mov 	[3:15],r0	; 48

	mov	r0,2		; 49
	add	r6,r0		; 4A
	skip	NZ,0b11	        ; 4B  nz,3
	inc	r7	        ; 4C
	skip	NZ,0b01	        ; 4D  nz,1
	inc	r8	        ; 4E
; shift screen down
	exr	0	        ; 4F  exchange registers (save)

	mov	r6,14	        ; 50  rd ptr
	mov	r7,15	        ; 51  wr ptr
	mov	r1,4	        ; 52  hi nib ptr page 4
	mov	r2,5	        ; 53  hi nib ptr page 5
	mov	r8,15	        ; 54  loop counter

	mov	r0,[r1:r6]	; 55  rd
	mov	[r1:r7],r0	; 56  wr
	mov	r0,[r2:r6]	; 57  rd
	mov	[r2:r7],r0	; 58  wr

	dec	r6	        ; 59  decrement rd ptr
	dec	r7	        ; 5A  decrement wr ptr
	dsz	r8	        ; 5B  decrement loop counter
	jr	-8	        ; 5C  if counter>0, loop

	exr	0	        ; 5D  exchange registers (restore)

	mov 	r0,[2:15]	; 5E  get new 4 pixels...
	mov 	[4:0],r0	; 5F  ...and put them on visible page
	mov 	r0,[3:15]	; 60  get new 4 pixels...
	mov 	[5:0],r0	; 61  ...and put them on visible page

	ret	r0,0	; 62  (.87)	; ----------->

;adr 63 lolidk
;read the char gen data but don't actually write anything to our display memory, used for reading the width of the character
	;read char just like 036 does, stash the info into page 2 and page 3
	mov	pch,r8	        ; 66
	mov	pcm,r7	        ; 67
	mov	jsr,r6	        ; 68  call (read from char gen)  ----------->
	mov 	[2:15],r0	; 69
	inc	jsr	        ; 6A  call (read from char gen)  ----------->
	mov 	[3:15],r0	; 6B
	ret	r0,0		; 6C


; FONT data format: every characte rin the font is 6 bytes.
; BYTE 0 is the width of the character minus 1. So a full-width character
; will have byte 0 of 0b00000100 (4) because the character is 5 columns wide.
; The letters in the font look backwards (right to left) because they scroll down
; from the top of the display.
org 0x100
chargen:	; 480 bytes (960 nibbles)        @ 0x080
	BYTE	0b00000010
	BYTE	0b00000000	; sp
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000000
	BYTE	0b11111010	; !
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000010
	BYTE	0b11000000	; "
	BYTE	0b00000000
	BYTE	0b11000000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b00101000	; #
	BYTE	0b11111110
	BYTE	0b00101000
	BYTE	0b11111110
	BYTE	0b00101000

	BYTE	0b00000100
	BYTE	0b00100100	; $
	BYTE	0b01010100
	BYTE	0b11111110
	BYTE	0b01010100
	BYTE	0b01001000

	BYTE	0b00000100
	BYTE	0b01000110	; %
	BYTE	0b00100110
	BYTE	0b00010000
	BYTE	0b11001000
	BYTE	0b11000100

	BYTE	0b00000100
	BYTE	0b01101100	; &
	BYTE	0b10010010
	BYTE	0b01101010
	BYTE	0b00001100
	BYTE	0b00010010

	BYTE	0b00000001
	BYTE	0b00010000
	BYTE	0b01100000
	BYTE	0b00000000	; '
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000010
	BYTE	0b00111000
	BYTE	0b01000100
	BYTE	0b10000010
	BYTE	0b00000000	; (
	BYTE	0b00000000

	BYTE	0b00000010
	BYTE	0b10000010
	BYTE	0b01000100
	BYTE	0b00111000
	BYTE	0b00000000	; )
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b01000100	; *
	BYTE	0b00101000
	BYTE	0b11111110
	BYTE	0b00101000
	BYTE	0b01000100

	BYTE	0b00000100
	BYTE	0b00010000	; +
	BYTE	0b00010000
	BYTE	0b01111100
	BYTE	0b00010000
	BYTE	0b00010000

	BYTE	0b00000010
	BYTE	0b00000001
	BYTE	0b00000110
	BYTE	0b00000000	; ,
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000010
	BYTE	0b00010000	; -
	BYTE	0b00010000
	BYTE	0b00010000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000000
	BYTE	0b00000110	; .
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b01000000	; /
	BYTE	0b00100000
	BYTE	0b00010000
	BYTE	0b00001000
	BYTE	0b00000100

	BYTE	0b00000100
	BYTE	0b01111100	; 0
	BYTE	0b10001010
	BYTE	0b10010010
	BYTE	0b10100010
	BYTE	0b01111100

	BYTE	0b00000010
	BYTE	0b01000010
	BYTE	0b11111110
	BYTE	0b00000010
	BYTE	0b00000000
	BYTE	0b00000000	; 1

	BYTE	0b00000100
	BYTE	0b01000010	; 2
	BYTE	0b10000110
	BYTE	0b10001010
	BYTE	0b10010010
	BYTE	0b01100010

	BYTE	0b00000100
	BYTE	0b01000100	; 3
	BYTE	0b10000010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b01101100

	BYTE	0b00000100
	BYTE	0b00111000	; 4
	BYTE	0b01001000
	BYTE	0b10001000
	BYTE	0b00011110
	BYTE	0b00001000

	BYTE	0b00000100
	BYTE	0b11110010	; 5
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10001100

	BYTE	0b00000100
	BYTE	0b00111100	; 6
	BYTE	0b01010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b00001100

	BYTE	0b00000100
	BYTE	0b10000110	; 7
	BYTE	0b10001000
	BYTE	0b10010000
	BYTE	0b10100000
	BYTE	0b11000000

	BYTE	0b00000100
	BYTE	0b01101100	; 8
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b01101100

	BYTE	0b00000100
	BYTE	0b01100000	; 9
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010100
	BYTE	0b01111000

	BYTE	0b00000000
	BYTE	0b01100110
	BYTE	0b00000000	; :
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000001
	BYTE	0b00000001
	BYTE	0b01100110
	BYTE	0b00000000	; ;
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000011
	BYTE	0b00010000	; <
	BYTE	0b00101000
	BYTE	0b01000100
	BYTE	0b10000010
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b00101000	; =
	BYTE	0b00101000
	BYTE	0b00101000
	BYTE	0b00101000
	BYTE	0b00101000

	BYTE	0b00000011
	BYTE	0b10000010
	BYTE	0b01000100
	BYTE	0b00101000
	BYTE	0b00010000
	BYTE	0b00000000	; >

	BYTE	0b00000100
	BYTE	0b01000000	; ?
	BYTE	0b10000000
	BYTE	0b10001010
	BYTE	0b10010000
	BYTE	0b01100000
;
	BYTE	0b00000100
	BYTE	0b01111100	; @
	BYTE	0b10010010
	BYTE	0b10101010
	BYTE	0b10101010
	BYTE	0b01110010

	BYTE	0b00000100
	BYTE	0b00111110	; A
	BYTE	0b01001000
	BYTE	0b10001000
	BYTE	0b01001000
	BYTE	0b00111110

	BYTE	0b00000100
	BYTE	0b11111110	; B
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b01101100

	BYTE	0b00000100
	BYTE	0b01111100	; C
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b01000100

	BYTE	0b00000100
	BYTE	0b11111110	; D
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b01000100
	BYTE	0b00111000

	BYTE	0b00000100
	BYTE	0b11111110	; E
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10000010

	BYTE	0b00000100
	BYTE	0b11111111	; F
	BYTE	0b10010000
	BYTE	0b10010000
	BYTE	0b10010000
	BYTE	0b10000000

	BYTE	0b00000100
	BYTE	0b01111100	; G
	BYTE	0b10000010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10011110

	BYTE	0b00000100
	BYTE	0b11111110	; H
	BYTE	0b00010000
	BYTE	0b00010000
	BYTE	0b00010000
	BYTE	0b11111110

	BYTE	0b00000010
	BYTE	0b10000010
	BYTE	0b11111110
	BYTE	0b10000010
	BYTE	0b00000000	; I
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b10000100	; J
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b11111100

	BYTE	0b00000100
	BYTE	0b11111110	; K
	BYTE	0b00010000
	BYTE	0b00101000
	BYTE	0b01000100
	BYTE	0b10000010

	BYTE	0b00000100
	BYTE	0b11111110	; L
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b00000010

	BYTE	0b00000100
	BYTE	0b11111110	; M
	BYTE	0b01000000
	BYTE	0b00100000
	BYTE	0b01000000
	BYTE	0b11111110

	BYTE	0b00000100
	BYTE	0b11111110	; N
	BYTE	0b00010000
	BYTE	0b00001000
	BYTE	0b00000100
	BYTE	0b11111110

	BYTE	0b00000100
	BYTE	0b01111100	; O
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b01111100

	BYTE	0b00000100
	BYTE	0b11111110	; P
	BYTE	0b10010000
	BYTE	0b10010000
	BYTE	0b10010000
	BYTE	0b01100000

	BYTE	0b00000100
	BYTE	0b01111100	; Q
	BYTE	0b10000010
	BYTE	0b10001010
	BYTE	0b10000100
	BYTE	0b01111010

	BYTE	0b00000100
	BYTE	0b11111110	; R
	BYTE	0b10010000
	BYTE	0b10011000
	BYTE	0b10010100
	BYTE	0b01100010

	BYTE	0b00000100
	BYTE	0b01100100	; S
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b01001100

	BYTE	0b00000100
	BYTE	0b10000000	; T
	BYTE	0b10000000
	BYTE	0b11111110
	BYTE	0b10000000
	BYTE	0b10000000

	BYTE	0b00000100
	BYTE	0b11111100	; U
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b11111100

	BYTE	0b00000100
	BYTE	0b11111000	; V
	BYTE	0b00000100
	BYTE	0b00000010
	BYTE	0b00000100
	BYTE	0b11111000

	BYTE	0b00000100
	BYTE	0b11111110	; W
	BYTE	0b00000100
	BYTE	0b00001000
	BYTE	0b00000100
	BYTE	0b11111110

	BYTE	0b00000100
	BYTE	0b11000110	; X
	BYTE	0b00101000
	BYTE	0b00010000
	BYTE	0b00101000
	BYTE	0b11000110

	BYTE	0b00000100
	BYTE	0b11100000	; Y
	BYTE	0b00010000
	BYTE	0b00001110
	BYTE	0b00010000
	BYTE	0b11100000

	BYTE	0b00000100
	BYTE	0b10000110	; Z
	BYTE	0b10001010
	BYTE	0b10010010
	BYTE	0b10100010
	BYTE	0b11000010

	BYTE	0b00000001
	BYTE	0b10000010
	BYTE	0b11111110
	BYTE	0b00000000	; [
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b01000000	; \
	BYTE	0b00100000
	BYTE	0b00010000
	BYTE	0b00001000
	BYTE	0b00000100

	BYTE	0b00000001
	BYTE	0b11111110
	BYTE	0b10000010
	BYTE	0b00000000	; ]
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b00100000	; ^
	BYTE	0b01000000
	BYTE	0b10000000
	BYTE	0b01000000
	BYTE	0b00100000

	BYTE	0b00000100
	BYTE	0b00000001	; _
	BYTE	0b00000001
	BYTE	0b00000001
	BYTE	0b00000001
	BYTE	0b00000001
;
	BYTE	0b00000010
	BYTE	0b10000000
	BYTE	0b01000000
	BYTE	0b00100000
	BYTE	0b00000000	; `
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b00000100	; a
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00011110

	BYTE	0b00000100
	BYTE	0b11111110	; b
	BYTE	0b00010010
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00011100

	BYTE	0b00000100
	BYTE	0b00011100	; c
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00100010

	BYTE	0b00000100
	BYTE	0b00011100	; d
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00010010
	BYTE	0b11111110

	BYTE	0b00000100
	BYTE	0b00011100	; e
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00011000

	BYTE	0b00000011
	BYTE	0b00001000
	BYTE	0b01111111
	BYTE	0b10001000
	BYTE	0b01000000
	BYTE	0b00000000	; f

	BYTE	0b00000100
	BYTE	0b00011000	; g
	BYTE	0b00100101
	BYTE	0b00100101
	BYTE	0b00100101
	BYTE	0b00011110

	BYTE	0b00000100
	BYTE	0b11111110	; h
	BYTE	0b00010000
	BYTE	0b00100000
	BYTE	0b00100000
	BYTE	0b00011110

	BYTE	0b00000010
	BYTE	0b00100010
	BYTE	0b10111110
	BYTE	0b00000010
	BYTE	0b00000000	; i
	BYTE	0b00000000

	BYTE	0b00000010
	BYTE	0b00000001
	BYTE	0b00000001
	BYTE	0b10111110
	BYTE	0b00000000	; j
	BYTE	0b00000000

	BYTE	0b00000011
	BYTE	0b11111110
	BYTE	0b00001000
	BYTE	0b00010100
	BYTE	0b00100010
	BYTE	0b00000000	; k

	BYTE	0b00000010
	BYTE	0b10000010
	BYTE	0b11111110
	BYTE	0b00000010
	BYTE	0b00000000	; l
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b00111110	; m
	BYTE	0b00100000
	BYTE	0b00011110
	BYTE	0b00100000
	BYTE	0b00011110

	BYTE	0b00000100
	BYTE	0b00111110	; n
	BYTE	0b00010000
	BYTE	0b00100000
	BYTE	0b00100000
	BYTE	0b00011110

	BYTE	0b00000100
	BYTE	0b00011100	; o
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00011100

	BYTE	0b00000100
	BYTE	0b00111111	; p
	BYTE	0b00100100
	BYTE	0b00100100
	BYTE	0b00100100
	BYTE	0b00011000

	BYTE	0b00000100
	BYTE	0b00011000	; q
	BYTE	0b00100100
	BYTE	0b00100100
	BYTE	0b00100100
	BYTE	0b00111111

	BYTE	0b00000100
	BYTE	0b00111110	; r
	BYTE	0b00010000
	BYTE	0b00100000
	BYTE	0b00100000
	BYTE	0b00010000

	BYTE	0b00000100
	BYTE	0b00010010	; s
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00100100

	BYTE	0b00000100
	BYTE	0b00100000	; t
	BYTE	0b11111100
	BYTE	0b00100010
	BYTE	0b00000010
	BYTE	0b00000100

	BYTE	0b00000100
	BYTE	0b00111100	; u
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b00000100
	BYTE	0b00111110

	BYTE	0b00000100
	BYTE	0b00111000	; v
	BYTE	0b00000100
	BYTE	0b00000010
	BYTE	0b00000100
	BYTE	0b00111000

	BYTE	0b00000100
	BYTE	0b00111110	; w
	BYTE	0b00000100
	BYTE	0b00001000
	BYTE	0b00000100
	BYTE	0b00111110

	BYTE	0b00000100
	BYTE	0b00100010	; x
	BYTE	0b00010100
	BYTE	0b00001000
	BYTE	0b00010100
	BYTE	0b00100010

	BYTE	0b00000100
	BYTE	0b00110001	; y
	BYTE	0b00001001
	BYTE	0b00000110
	BYTE	0b00000100
	BYTE	0b00111000

	BYTE	0b00000100
	BYTE	0b00100010	; z
	BYTE	0b00100110
	BYTE	0b00101010
	BYTE	0b00110010
	BYTE	0b00100010

	BYTE	0b00000010
	BYTE	0b00010000
	BYTE	0b01101100
	BYTE	0b10000010
	BYTE	0b00000000	; {
	BYTE	0b00000000

	BYTE	0b00000001
	BYTE	0b11111110
	BYTE	0b00000000	; |
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000010
	BYTE	0b10000010
	BYTE	0b01101100
	BYTE	0b00010000
	BYTE	0b00000000	; }
	BYTE	0b00000000

	BYTE	0b00000100
	BYTE	0b01000000	; ~
	BYTE	0b10000000
	BYTE	0b01000000
	BYTE	0b00100000
	BYTE	0b01000000

	BYTE	0b00000010
	BYTE	0b00000000	; sp
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

org 0x600
disptext:	; 394 bytes (788 nibbles)        @ 0x600
;	.ascii	"I am HAL 9000 computer. I became operational at the HAL plant in Urbana,"
;	.ascii	" Illinois, on January 12th, 1991. My first instructor was Mr. Arkany. He"
;	.ascii	" taught me to sing a song... it goes like this... Daisy, Daisy, give me "
;	.ascii	"your answer do. I'm half crazy all for the love of you. It won't be a st"
;	.ascii	"ylish marriage. I can't afford a carriage. But you'll look sweet Upon th"
;	.ascii	"e seat of a bicycle built for two.  "

ASCII "Though yet of Hamlet our dear brother's death The memory be green, and that it us befitted  To bear our hearts in grief and our whole kingdom To be contracted in one brow of woe, Yet so far hath discretion fought with nature That we with wisest sorrow think on him, Together with remembrance of ourselves. Therefore our sometime sister, now our queen, The imperial jointress to this warlike state, Have we, as 'twere with a defeated joy, With an auspicious and a dropping eye, With mirth in funeral and with dirge in marriage, In equal scale weighing delight and dole, Taken to wife: nor have we herein barr'd Your better wisdoms, which have freely gone With this affair along. For all, our thanks. Now follows, that you know, young Fortinbras, Holding a weak supposal of our worth, Or thinking by our late dear brother's death Our state to be disjoint and out of frame, Colleagued with the dream of his advantage, He hath not fail'd to pester us with message, Importing the surrender of those lands Lost by his father, with all bonds of law, To our most valiant brother. So much for him. Now for ourself and for this time of meeting: Thus much the business is: we have here writ To Norway, uncle of young Fortinbras >> "
;abcdefghijklmnopqrstuvwxyz 0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ
	ret	r0,0b1111	; terminator
	ret	r0,0b1111
pgm_end:	; this is supposed to be the last INC. file
