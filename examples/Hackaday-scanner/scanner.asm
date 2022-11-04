max EQU 15
min EQU 0

;Setup
MOV R8,2 ;Page
MOV R2,0b0001 ;Direction
MOV R1,min ;Location
MOV R3,min ; last location
MOV R0,R8 ; set page to view page
MOV [0xF0],R0 
MOV R0,6 ; slow it down a little
MOV [0xF1],R0 

Main:
;Check Location Min/Max & Switch
MOV R0,R1
CP R0,min
SKIP NZ,0b01  ;Skip if this comparison is NOT true
BSET R2,0b00  ;toggle direction bit
CP R0,max
SKIP NZ,0b01  ;Skip if this comparison is NOT true
BCLR R2,0b00  ;toggle direction bit
GOSUB UpdateDisplay
GOTO Main

UpdateDisplay:
MOV R3, R0 ; stash last page

;test to inc or dec
BIT R2,0b00
SKIP Z,0b10
INC R1
SKIP NZ,0b01
DEC R1

MOV R0,0xF ;Write new
MOV [R8:R1],R0
INC R8
MOV [R8:R1],R0 ; draw line across pages
DEC R8


;Erase old
MOV R0,0x0000000000000000
MOV [R8:R3],R0
INC R8
MOV [R8:R3],R0 ; draw line across pages
DEC R8

RET R0,0000+5-1+3-7
