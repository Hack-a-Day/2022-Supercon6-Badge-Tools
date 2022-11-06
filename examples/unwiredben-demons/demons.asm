; demons.asm
; a simple shooter for Hackaday Supercon.6 badge
;
; Copyright (C) 2022, Ben Combee
; released under MIT license

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
  Btn_Mode  EQU 0
  Btn_Opc_8 EQU 1
  Btn_Opc_4 EQU 2
  Btn_Opc_2 EQU 3
  Btn_Opc_1 EQU 4
  Btn_X_8   EQU 5
  Btn_X_4   EQU 6
  Btn_X_2   EQU 7
  Btn_X_1   EQU 8
  Btn_Y_8   EQU 9
  Btn_Y_4   EQU 10
  Btn_Y_2   EQU 11
  Btn_Y_1   EQU 12
  Btn_DtIn  EQU 13
Dimmer      EQU 0xfe
Random      EQU 0xff 

; DEMON is drawn as either *.*    .*.
;                          .*. or *.* depending on animation frame

DF0Top      EQU 0b0101
DF0Bottom   EQU 0b0010
DF1Top      EQU 0b0010
DF1Bottom   EQU 0b0101

; lateral demon movement is based on a few patterns:
;   0 straight down (0)
;   1 slight wiggle (-1 0 +1 0)
;   2 longer wiggle (-2 -1 0 +1 +2 +1 0 -1)
;   3 left wiggle (-2 -1 0 -1 -2 -1 0 +1 +2 +1 0)
;   4 right wiggle (+2 +1 0 +1 +2 +1 0 -1 -2 -1 0)
; vertical movement varies but could be 50% down, 25% stay, 25% up
; we try to have two demons active on screen at any time
; when a demon gets to base row, one life is removed

; BASE is drawn as .*.
;                  *** offset to the current player position

BaseTop     EQU 0b0010
BaseBottom  EQU 0b0111
BaseRow     EQU 12

; SHOTS are just a lit LED.  One shot is active at a time, and the base
; can't move while a SHOT is active.  SHOTs move up one row at a time
; until they hit a demon or go off the top of the screen
;
; BASE POWER is a line of LEDs at the bottom, going from 4 (*.*.*.*.) to 0 (........) (the end)
; after all lifes are used, score is drawn on screen until game restarts

LivesRow    EQU 15

; Score screen is shown when you lose all your lives

ScoreDemon1Row  EQU 1
ScoreDemon2Row  EQU 12
ScoreStartRow   EQU 5
ScoreEndRow     EQU 9

; control is via operand keys, 8 is left, 4 is right, 1 is fire

; RAM layout
;
; page 2/3 frame A
; page 4/5 frame B
; page 6   data storage

ScoreLow    EQU 0x60    ; 0-9 BCD
ScoreHigh   EQU 0x61    ; 0-9 BCD
D1Row       EQU 0x62    ; 0-10
D1Pos       EQU 0x63    ; 0-5
D1Pattern   EQU 0x64    ; 0-4
  PatStill  EQU 0
  PatWiggle EQU 1
  PatDive   EQU 2
  PatDie    EQU 3
D2Row       EQU 0x65    ; 0-10
D2Pos       EQU 0x66    ; 0-5
D2Pattern   EQU 0x67    ; 0-4
FrameNum    EQU 0x68
BasePos     EQU 0x69    ; 0-5
ShotRow     EQU 0x6A    ; if 15, not displayed
Lives       EQU 0x6B
GameState   EQU 0x6C
  Attract   EQU 0
  Active    EQU 1
  ShowScore EQU 2
GameAnim    EQU 0x6D
  NoAnim    EQU 0
  WipeUp    EQU 1
  WipeDn    EQU 2

; data locations

DigitTable  EQU 0x400

; REGISTERS
;
; R0 accumulator
; R1,R2 volatile, may be used as return values
; R3 left page
; R4 right page
; R5 row
; R6,R7 misc parameter

INIT:
    ; entering RUN mode clears data memory to 0
    ; so only need to init variables with a different
    ; starting state
    mov r0, 1
    mov [D2Pattern], r0
    mov r0, 3
    mov [D2Row], r0
    mov r0, 4
    mov [D2Pos], r0
    mov [BasePos], r0
    mov [Lives], r0
    mov r0, 15
    mov [ShotRow], r0

    mov r0, F_3_kHz
    mov [Clock], r0

    gosub SETUP_DRAWING_PAGE
    gosub FLIP_PAGES

LOOP:

    mov r0, [D1Row]
    mov r5, r0
    mov r0, [D1Pos]
    mov r6, r0
    gosub DRAW_DEMON
    
    mov r0, [D2Row]
    mov r5, r0
    mov r0, [D2Pos]
    mov r6, r0
    gosub DRAW_DEMON

    gosub DRAW_BASE
    gosub DRAW_LIVES

    gosub FLIP_PAGES
    gosub CHECK_INPUT

    ; FIXME: move demons and shots with collision detection

    mov r0, [FrameNum]  ; increment FrameNum
    inc r0
    mov [FrameNum], r0

    gosub SETUP_DRAWING_PAGE
    jr LOOP

;
; Utility Functions
;

SHIFT_LEFT:         ; value in r1 left by r0, output in r2/r1
    mov r2, 0
SHIFT_LEFT_LOOP:
    dec r0
    skip nc, 3
      add r1, r1
      adc r2, r2
      jr SHIFT_LEFT_LOOP
    ret r0, 0

SAT_INC_BCD:         ; add 1 to BCD number in r2:r1, saturating at 99
    inc r1
    mov r0, r1
    cp r0, 10
    skip nz, 2
      mov r1, 0
      inc r2
    mov r0, r2
    cp r0, 10
    skip nz, 2
      mov r1, 9
      mov r2, 9
    ret r0, 0

TOGGLE_PANEL:
    mov r0, [WrFlags]
    btg r0, LedsOff
    mov [WrFlags], r0
    ret r0, 0

;
; General drawing functions
;

FLIP_PAGES:
    mov r0, r3
    mov [Page], r0
    ret r0, 0

SETUP_DRAWING_PAGE: 
    mov r0, [FrameNum]
    bit r0, 0       ; test for odd/even
    mov r0, 2       ; default to even frames drawing to pages 2/3
    skip z, 1       ; if odd... 
      mov r0, 4     ; use pages 4/5 for odd frames
    mov r3, r0      ; setup r3 with right draw page
    mov r4, r0      ; then r4 has left draw page
    inc r4          ; as r3+1
    ; fallthrough to CLS routine

CLS:
    mov r5, 0       ; clear drawing pages
    mov r0, 0
CLS_LOOP:
    mov [r3:r5], r0
    mov [r4:r5], r0
    inc r5
    skip c, 1
      jr CLS_LOOP
    ret r0, 0

DRAW_ROW:           ; draw data in R2:R1
    mov r0, r1
    mov [r3:r5], r0
    mov r0, r2
    mov [r4:r5], r0
    ret r0, 0

;
; Game logic
;

INC_SCORE:
    mov r0, [ScoreLow]
    mov r1, r0
    mov r0, [ScoreHigh]
    mov r2, r0
    gosub SAT_INC_BCD
    mov r0, r1
    mov [ScoreLow], r0
    mov r0, r2
    mov [ScoreHigh], r0
    ret r0, 0

DEC_LIVES:
    mov r0, [Lives]
    dec r0

    mov [Lives], r0

;
; Demon-specific drawing functions
;

DRAW_DEMON:         ; have demon row in r5, position in r6
    mov r1, DF0Top
    mov r0, [FrameNum]
    bit r0, 0
    skip z, 1 
      mov r1, DF1Top
    mov r0, r6
    gosub SHIFT_LEFT
    gosub DRAW_ROW

    inc r5
    mov r1, DF0Bottom
    mov r0, [FrameNum]
    bit r0, 0
    skip z, 1 
      mov r1, DF1Bottom
    mov r0, r6      ; load shift amount
    gosub SHIFT_LEFT
    gosub DRAW_ROW

    ret r0, 0

DRAW_BASE:
    mov r5, BaseRow
    mov r1, BaseTop
    mov r0, [BasePos]
    gosub SHIFT_LEFT
    gosub DRAW_ROW
    inc r5
    mov r1, BaseBottom
    mov r0, [BasePos]
    gosub SHIFT_LEFT
    gosub DRAW_ROW
    ret r0, 0

DRAW_LIVES:
    mov r5, LivesRow
    mov r0, [Lives]     ; r0 will hold number of lives
    cp r0, 4
    skip nz, 2
      mov r2, 0b1010
      mov r1, 0b1010
    cp r0, 3
    skip nz, 2
      mov r2, 0b1010
      mov r1, 0b1000
    cp r0, 2
    skip nz, 2
      mov r2, 0b1010
      mov r1, 0b0000
    cp r0, 1
    skip nz, 2
      mov r2, 0b1000
      mov r1, 0b0000
    cp r0, 0
    skip nz, 2
      mov r2, 0b0000
      mov r1, 0b0000
    gosub DRAW_ROW
    ret r0, 0

DRAW_SCORE:
    mov r5, 1           ; score screen has demons
    mov r0, [D1Pos]     ; flying above and below the
    mov r6, r0          ; digits
    gosub DRAW_DEMON
    mov r5, 12
    mov r0, [D2Pos]
    mov r6, r0
    gosub DRAW_DEMON

    mov r5, ScoreStartRow
    mov r0, [ScoreLow]
    mov r6, r0
    mov r0, [ScoreHigh]
    mov r7, r0
    mov r8, 0

DRAW_SCORE_LOOP:
    mov pch, HIGH DigitTable
    mov pcm, r6
    mov jsr, r8
    mov r1, r0

    mov pch, HIGH DigitTable
    mov pcm, r7
    mov jsr, r8
    mov r2, r0

    gosub DRAW_ROW
    inc r8
    inc r5
    mov r0, r5
    cp r0, ScoreEndRow + 1
    skip z, 1
      jr DRAW_SCORE_LOOP
    ret r0, 0

;
; Input handling
;

; button labels

CHECK_INPUT:
    mov r0, [KeyStatus]
    bit r0, JustPress
    skip nz, 1
      ret r0, 0
    mov r0, [KeyReg]
    cp r0, Btn_Opc_8        ; toggle panel
    skip nz, 2
        goto TOGGLE_PANEL
    cp r0, Btn_Y_8          ; move left
    skip nz, 1
      jr MOVE_BASE_LEFT
    cp r0, Btn_Y_4          ; move right
    skip nz, 1
      jr MOVE_BASE_RIGHT
    cp r0, Btn_Y_1          ; fire
    skip nz, 1
      jr FIRE_SHOT
    ret r0, 0

MOVE_BASE_LEFT:
    mov r0, [BasePos]
    inc r0
    cp r0, 6
    skip nz, 1
      mov r0, 4
    mov [BasePos], r0
    ret r0, 0

MOVE_BASE_RIGHT:
    mov r0, [BasePos]
    dec r0
    skip c, 1
      mov r0, 0
    mov [BasePos], r0
    ret r0, 0

FIRE_SHOT:
    ; FIXME - actually set fire state instead of inc score

    ret r0, 0

;
; DATA TABLES
;

    ORG 0x400
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0101
    NIBBLE 0b0101
    NIBBLE 0b0111
    ORG 0x410
    NIBBLE 0b0010
    NIBBLE 0b0110
    NIBBLE 0b0010
    NIBBLE 0b0010
    NIBBLE 0b0111
    ORG 0x420
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0010
    NIBBLE 0b0100
    NIBBLE 0b0111
    ORG 0x430
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0011
    NIBBLE 0b0001
    NIBBLE 0b0111
    ORG 0x440
    NIBBLE 0b0101
    NIBBLE 0b0101
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0001
    ORG 0x450
    NIBBLE 0b0111
    NIBBLE 0b0100
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0111
    ORG 0x460
    NIBBLE 0b0111
    NIBBLE 0b0100
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0111
    ORG 0x470
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0010
    NIBBLE 0b0010
    NIBBLE 0b0010
    ORG 0x480
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0111
    ORG 0x490
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0111
