
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
	mov	r5,0x5	        ; 6  text pointer r345, start at 0xc00
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
; r1,2 x 10 ---> r6,7,8
	add	r1,r1	        ; 14  x2
	adc	r2,r2	        ; 15  x2
	mov	r6,r1	        ; 16  r6 <--- r1 (r678 text pointer) 
	mov	r7,r2	        ; 17  r7 <--- r2 (r678 text pointer) 
	mov	r8,0	        ; 18  r8 <--- 0  (r678 text pointer) 
	add	r6,r6	        ; 19  x4
	adc	r7,r7	        ; 1A  x4
	adc	r8,r8	        ; 1B  x4
	add	r6,r6	        ; 1C  x8
	adc	r7,r7		; 1D  x8
	adc	r8,r8	        ; 1E  x8
	add	r6,r1	        ; 1F  x10 (10 nibbles per character)
	adc	r7,r2	        ; 20  x10 (10 nibbles per character)
	adc	r8,pch	        ; 21  x10 (addc,0)
; r6,7,8 + 0x100 ---> r6,7,8
	mov	r0,1	        ; 22
	add	r8,r0	        ; 23

	mov	r9,5	        ; 24  x 5
	mov 	pc,[3]	        ; 25  subroutine @ 0x036
	mov	jsr,6	        ; 26  call  0x036 -----------> (shift 5 columns from char gen)
	dsz	r9	        ; 27
	jr	-4	        ; 28  loop

	mov	r6,0	        ; 29
	mov	r7,0	        ; 2A
	mov	r8,1	        ; 2B  point to blank (between chars)
	mov 	pc,[3]	        ; 2C  subroutine @ 0x036
	mov	jsr,6	        ; 2D  call  0x036 -----------> (shift 1 column, space between chars)

	inc	r3	        ; 2E  next char (one char = 2 nibbles)
	inc	r3	        ; 2F  next char (one char = 2 nibbles)
	skip	NZ,0b11	        ; 30  if nibble overflow, then nz,3
	inc	r4	        ; 31
	skip	NZ,0b01	        ; 32  if nibble overflow, then nz,1
	inc	r5	        ; 33

	mov 	pc,[0]	        ; 34
	mov	pcl,7	        ; 35  jump to 007 (loop)  ----------->

; adr 036
; (subroutine) shifts and loads one column (pointer r6r7r8)
; wait sync
	mov 	r0,[15:4]	; 36  RdFlags
	and	r0,0b0001	; 37  Bit #0 = UserSync
	skip	NZ,0b01	        ; 38  nz,1
	jr	-4	        ; 39  loop

	mov	pch,r8	        ; 3A
	mov	pcm,r7	        ; 3B
	mov	jsr,r6	        ; 3C  call (read from char gen)  ----------->
	mov 	[2:15],r0	; 3D
	inc	jsr	        ; 3E  call (read from char gen)  ----------->
	mov 	[3:15],r0	; 3F

	mov	r0,2
	add	r6,r0
	skip	NZ,0b11	        ; 40  nz,3
	inc	r7	        ; 41
	skip	NZ,0b01	        ; 42  nz,1
	inc	r8	        ; 43
; shift screen down
	exr	0	        ; 44  exchange registers (save)

	mov	r6,14	        ; 45  rd ptr
	mov	r7,15	        ; 46  wr ptr
	mov	r1,4	        ; 47  hi nib ptr page 4
	mov	r2,5	        ; 48  hi nib ptr page 5
	mov	r8,15	        ; 49  loop counter

	mov	r0,[r1:r6]	; 4A  rd
	mov	[r1:r7],r0	; 4B  wr
	mov	r0,[r2:r6]	; 4C  rd
	mov	[r2:r7],r0	; 4D  wr

	dec	r6	        ; 4E  decrement rd ptr
	dec	r7	        ; 4F  decrement wr ptr
	dsz	r8	        ; 50  decrement loop counter
	jr	-8	        ; 51  if counter>0, loop

	exr	0	        ; 52  exchange registers (restore)

	mov 	r0,[2:15]	; 53  get new 4 pixels...
	mov 	[4:0],r0	; 54  ...and put them on visible page
	mov 	r0,[3:15]	; 55  get new 4 pixels...
	mov 	[5:0],r0	; 56  ...and put them on visible page

	ret	r0,0	; 57  (.87)	; ----------->

org 0x100
chargen:	; 480 bytes (960 nibbles)        @ 0x100
	BYTE	0b00000000	; sp
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000000	; !
	BYTE	0b00000000
	BYTE	0b11111010
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000000	; "
	BYTE	0b11000000
	BYTE	0b00000000
	BYTE	0b11000000
	BYTE	0b00000000

	BYTE	0b00101000	; #
	BYTE	0b11111110
	BYTE	0b00101000
	BYTE	0b11111110
	BYTE	0b00101000

	BYTE	0b00100100	; $
	BYTE	0b01010100
	BYTE	0b11111110
	BYTE	0b01010100
	BYTE	0b01001000

	BYTE	0b01000110	; %
	BYTE	0b00100110
	BYTE	0b00010000
	BYTE	0b11001000
	BYTE	0b11000100

	BYTE	0b01101100	; &
	BYTE	0b10010010
	BYTE	0b01101010
	BYTE	0b00001100
	BYTE	0b00010010

	BYTE	0b00000000	; '
	BYTE	0b00010000
	BYTE	0b01100000
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000000	; (
	BYTE	0b00111000
	BYTE	0b01000100
	BYTE	0b10000010
	BYTE	0b00000000

	BYTE	0b00000000	; )
	BYTE	0b10000010
	BYTE	0b01000100
	BYTE	0b00111000
	BYTE	0b00000000

	BYTE	0b01000100	; *
	BYTE	0b00101000
	BYTE	0b11111110
	BYTE	0b00101000
	BYTE	0b01000100

	BYTE	0b00010000	; +
	BYTE	0b00010000
	BYTE	0b01111100
	BYTE	0b00010000
	BYTE	0b00010000

	BYTE	0b00000000	; ,
	BYTE	0b00000001
	BYTE	0b00000110
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00010000	; -
	BYTE	0b00010000
	BYTE	0b00010000
	BYTE	0b00010000
	BYTE	0b00010000

	BYTE	0b00000000	; .
	BYTE	0b00000000
	BYTE	0b00000110
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b01000000	; /
	BYTE	0b00100000
	BYTE	0b00010000
	BYTE	0b00001000
	BYTE	0b00000100

	BYTE	0b01111100	; 0
	BYTE	0b10001010
	BYTE	0b10010010
	BYTE	0b10100010
	BYTE	0b01111100

	BYTE	0b00000000	; 1
	BYTE	0b01000010
	BYTE	0b11111110
	BYTE	0b00000010
	BYTE	0b00000000

	BYTE	0b01000010	; 2
	BYTE	0b10000110
	BYTE	0b10001010
	BYTE	0b10010010
	BYTE	0b01100010

	BYTE	0b01000100	; 3
	BYTE	0b10000010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b01101100

	BYTE	0b00111000	; 4
	BYTE	0b01001000
	BYTE	0b10001000
	BYTE	0b00011110
	BYTE	0b00001000

	BYTE	0b11110010	; 5
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10001100

	BYTE	0b00111100	; 6
	BYTE	0b01010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b00001100

	BYTE	0b10000110	; 7
	BYTE	0b10001000
	BYTE	0b10010000
	BYTE	0b10100000
	BYTE	0b11000000

	BYTE	0b01101100	; 8
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b01101100

	BYTE	0b01100000	; 9
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010100
	BYTE	0b01111000

	BYTE	0b00000000	; :
	BYTE	0b00000000
	BYTE	0b01100110
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000000	; ;
	BYTE	0b00000001
	BYTE	0b01100110
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00010000	; <
	BYTE	0b00101000
	BYTE	0b01000100
	BYTE	0b10000010
	BYTE	0b00000000

	BYTE	0b00101000	; =
	BYTE	0b00101000
	BYTE	0b00101000
	BYTE	0b00101000
	BYTE	0b00101000

	BYTE	0b00000000	; >
	BYTE	0b10000010
	BYTE	0b01000100
	BYTE	0b00101000
	BYTE	0b00010000

	BYTE	0b01000000	; ?
	BYTE	0b10000000
	BYTE	0b10001010
	BYTE	0b10010000
	BYTE	0b01100000
;	
	BYTE	0b01111100	; @
	BYTE	0b10010010
	BYTE	0b10101010
	BYTE	0b10101010
	BYTE	0b01110010

	BYTE	0b00111110	; A
	BYTE	0b01001000
	BYTE	0b10001000
	BYTE	0b01001000
	BYTE	0b00111110

	BYTE	0b11111110	; B
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b01101100

	BYTE	0b01111100	; C
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b01000100

	BYTE	0b11111110	; D
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b01000100
	BYTE	0b00111000

	BYTE	0b11111110	; E
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10000010

	BYTE	0b11111111	; F
	BYTE	0b10010000
	BYTE	0b10010000
	BYTE	0b10010000
	BYTE	0b10000000

	BYTE	0b01111100	; G
	BYTE	0b10000010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10011110

	BYTE	0b11111110	; H
	BYTE	0b00010000
	BYTE	0b00010000
	BYTE	0b00010000
	BYTE	0b11111110

	BYTE	0b00000000	; I
	BYTE	0b10000010
	BYTE	0b11111110
	BYTE	0b10000010
	BYTE	0b00000000

	BYTE	0b10000100	; J
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b11111100

	BYTE	0b11111110	; K
	BYTE	0b00010000
	BYTE	0b00101000
	BYTE	0b01000100
	BYTE	0b10000010

	BYTE	0b11111110	; L
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b00000010

	BYTE	0b11111110	; M
	BYTE	0b01000000
	BYTE	0b00100000
	BYTE	0b01000000
	BYTE	0b11111110

	BYTE	0b11111110	; N
	BYTE	0b00010000
	BYTE	0b00001000
	BYTE	0b00000100
	BYTE	0b11111110

	BYTE	0b01111100	; O
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b10000010
	BYTE	0b01111100

	BYTE	0b11111110	; P
	BYTE	0b10010000
	BYTE	0b10010000
	BYTE	0b10010000
	BYTE	0b01100000

	BYTE	0b01111100	; Q
	BYTE	0b10000010
	BYTE	0b10001010
	BYTE	0b10000100
	BYTE	0b01111010

	BYTE	0b11111110	; R
	BYTE	0b10010000
	BYTE	0b10011000
	BYTE	0b10010100
	BYTE	0b01100010

	BYTE	0b01100100	; S
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b10010010
	BYTE	0b01001100

	BYTE	0b10000000	; T
	BYTE	0b10000000
	BYTE	0b11111110
	BYTE	0b10000000
	BYTE	0b10000000

	BYTE	0b11111100	; U
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b11111100

	BYTE	0b11111000	; V
	BYTE	0b00000100
	BYTE	0b00000010
	BYTE	0b00000100
	BYTE	0b11111000

	BYTE	0b11111110	; W
	BYTE	0b00000100
	BYTE	0b00001000
	BYTE	0b00000100
	BYTE	0b11111110

	BYTE	0b11000110	; X
	BYTE	0b00101000
	BYTE	0b00010000
	BYTE	0b00101000
	BYTE	0b11000110

	BYTE	0b11100000	; Y
	BYTE	0b00010000
	BYTE	0b00001110
	BYTE	0b00010000
	BYTE	0b11100000

	BYTE	0b10000110	; Z
	BYTE	0b10001010
	BYTE	0b10010010
	BYTE	0b10100010
	BYTE	0b11000010

	BYTE	0b00000000	; [
	BYTE	0b10000010
	BYTE	0b11111110
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b01000000	; \
	BYTE	0b00100000
	BYTE	0b00010000
	BYTE	0b00001000
	BYTE	0b00000100

	BYTE	0b00000000	; ]
	BYTE	0b00000000
	BYTE	0b11111110
	BYTE	0b10000010
	BYTE	0b00000000

	BYTE	0b00100000	; ^
	BYTE	0b01000000
	BYTE	0b10000000
	BYTE	0b01000000
	BYTE	0b00100000

	BYTE	0b00000001	; _
	BYTE	0b00000001
	BYTE	0b00000001
	BYTE	0b00000001
	BYTE	0b00000001
;	
	BYTE	0b00000000	; `
	BYTE	0b10000000
	BYTE	0b01000000
	BYTE	0b00100000
	BYTE	0b00000000

	BYTE	0b00000100	; a
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00011110

	BYTE	0b11111110	; b
	BYTE	0b00010010
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00011100

	BYTE	0b00011100	; c
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00100010

	BYTE	0b00011100	; d
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00010010
	BYTE	0b11111110

	BYTE	0b00011100	; e
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00011000

	BYTE	0b00000000	; f
	BYTE	0b00001000
	BYTE	0b01111111
	BYTE	0b10001000
	BYTE	0b01000000

	BYTE	0b00011000	; g
	BYTE	0b00100101
	BYTE	0b00100101
	BYTE	0b00100101
	BYTE	0b00011110

	BYTE	0b11111110	; h
	BYTE	0b00010000
	BYTE	0b00100000
	BYTE	0b00100000
	BYTE	0b00011110

	BYTE	0b00000000	; i
	BYTE	0b00100010
	BYTE	0b10111110
	BYTE	0b00000010
	BYTE	0b00000000

	BYTE	0b00000000	; j
	BYTE	0b00000001
	BYTE	0b00000001
	BYTE	0b10111110
	BYTE	0b00000000

	BYTE	0b00000000	; k
	BYTE	0b11111110
	BYTE	0b00001000
	BYTE	0b00010100
	BYTE	0b00100010

	BYTE	0b00000000	; l
	BYTE	0b10000010
	BYTE	0b11111110
	BYTE	0b00000010
	BYTE	0b00000000

	BYTE	0b00111110	; m
	BYTE	0b00100000
	BYTE	0b00011110
	BYTE	0b00100000
	BYTE	0b00011110

	BYTE	0b00111110	; n
	BYTE	0b00010000
	BYTE	0b00100000
	BYTE	0b00100000
	BYTE	0b00011110

	BYTE	0b00011100	; o
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00100010
	BYTE	0b00011100

	BYTE	0b00111111	; p
	BYTE	0b00100100
	BYTE	0b00100100
	BYTE	0b00100100
	BYTE	0b00011000

	BYTE	0b00011000	; q
	BYTE	0b00100100
	BYTE	0b00100100
	BYTE	0b00100100
	BYTE	0b00111111

	BYTE	0b00111110	; r
	BYTE	0b00010000
	BYTE	0b00100000
	BYTE	0b00100000
	BYTE	0b00010000

	BYTE	0b00010010	; s
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00101010
	BYTE	0b00100100

	BYTE	0b00100000	; t
	BYTE	0b11111100
	BYTE	0b00100010
	BYTE	0b00000010
	BYTE	0b00000100

	BYTE	0b00111100	; u
	BYTE	0b00000010
	BYTE	0b00000010
	BYTE	0b00000100
	BYTE	0b00111110

	BYTE	0b00111000	; v
	BYTE	0b00000100
	BYTE	0b00000010
	BYTE	0b00000100
	BYTE	0b00111000

	BYTE	0b00111110	; w
	BYTE	0b00000100
	BYTE	0b00001000
	BYTE	0b00000100
	BYTE	0b00111110

	BYTE	0b00100010	; x
	BYTE	0b00010100
	BYTE	0b00001000
	BYTE	0b00010100
	BYTE	0b00100010

	BYTE	0b00110001	; y
	BYTE	0b00001001
	BYTE	0b00000110
	BYTE	0b00000100
	BYTE	0b00111000

	BYTE	0b00100010	; z
	BYTE	0b00100110
	BYTE	0b00101010
	BYTE	0b00110010
	BYTE	0b00100010

	BYTE	0b00000000	; {
	BYTE	0b00010000
	BYTE	0b01101100
	BYTE	0b10000010
	BYTE	0b00000000

	BYTE	0b00000000	; |
	BYTE	0b00000000
	BYTE	0b11111110
	BYTE	0b00000000
	BYTE	0b00000000

	BYTE	0b00000000	; }
	BYTE	0b10000010
	BYTE	0b01101100
	BYTE	0b00010000
	BYTE	0b00000000

	BYTE	0b01000000	; ~
	BYTE	0b10000000
	BYTE	0b01000000
	BYTE	0b00100000
	BYTE	0b01000000

	BYTE	0b00000000	; sp
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000
	BYTE	0b00000000

org 0x500
disptext:	; 394 bytes (788 nibbles)        @ 0x500
;	.ascii	"I am HAL 9000 computer. I became operational at the HAL plant in Urbana,"
;	.ascii	" Illinois, on January 12th, 1991. My first instructor was Mr. Arkany. He"
;	.ascii	" taught me to sing a song... it goes like this... Daisy, Daisy, give me "
;	.ascii	"your answer do. I'm half crazy all for the love of you. It won't be a st"
;	.ascii	"ylish marriage. I can't afford a carriage. But you'll look sweet Upon th"
;	.ascii	"e seat of a bicycle built for two.  "

ASCII "Though yet of Hamlet our dear brother's death The memory be green, and that it us befitted  To bear our hearts in grief and our whole kingdom To be contracted in one brow of woe, Yet so far hath discretion fought with nature That we with wisest sorrow think on him, Together with remembrance of ourselves. Therefore our sometime sister, now our queen, The imperial jointress to this warlike state, Have we, as 'twere with a defeated joy, With an auspicious and a dropping eye, With mirth in funeral and with dirge in marriage, In equal scale weighing delight and dole, Taken to wife: nor have we herein barr'd Your better wisdoms, which have freely gone With this affair along. For all, our thanks. Now follows, that you know, young Fortinbras, Holding a weak supposal of our worth, Or thinking by our late dear brother's death Our state to be disjoint and out of frame, Colleagued with the dream of his advantage, He hath not fail'd to pester us with message, Importing the surrender of those lands Lost by his father, with all bonds of law, To our most valiant brother. So much for him. Now for ourself and for this time of meeting: Thus much the business is: we have here writ To Norway, uncle of young Fortinbras >> "

	ret	r0,0b1111	; terminator
	ret	r0,0b1111
pgm_end:	; this is supposed to be the last INC. file
