; demons.asm
;
; a simple shooter for Hackaday Supercon.6 badge
;
; inspired by Demon Attack by Rob Fulop, but since it's
; a 4-bit platform, I just borrowed half the name.
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
  S_1000_Hz EQU 0
  S_600_Hz  EQU 1
  S_400_Hz  EQU 2
  S_250_Hz  EQU 3
  S_150_Hz  EQU 4
  S_100_Hz  EQU 5
  S_60_Hz   EQU 6
  S_40_Hz   EQU 7
  S_25_Hz   EQU 8
  S_15_Hz   EQU 9
  S_10_Hz   EQU 10
  S_6_Hz    EQU 11
  S_4_Hz    EQU 12
  S_2_5_Hz  EQU 13
  S_1_5_Hz  EQU 14
  S_1_Hz    EQU 15
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
; after all lives are used, score is drawn on screen until game restarts

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
; page 6   game state
; page 8   demon 1 state
; page 9   demon 2 state

ScoreLow    EQU 0x60    ; 0-9 BCD
ScoreHigh   EQU 0x61    ; 0-9 BCD
FrameNum    EQU 0x62
BasePos     EQU 0x63    ; 0-5
ShotPos     EQU 0x64
ShotRow     EQU 0x65    ; 0-14, 15 means don't draw
Lives       EQU 0x66
  NumLives  EQU 4
GameState   EQU 0x67
  Attract   EQU 0
  Active    EQU 1
  ShowScore EQU 2
GameAnim    EQU 0x68
  NoAnim    EQU 0
  WipeUp    EQU 1
  WipeDown  EQU 2
PauseTimer  EQU 0x69    ; count of frames until input is handled

; This is the number of the first column that's shown
; for the logo.  It's incremented for each frame of the
; attract screen until it gets to 7:3, then wraps to 0:0
LogoPosL    EQU 0x6A    ; 0..3 - position within nibble
LogoPosH    EQU 0x6B    ; 0..7 - number of nibble

D1Row       EQU 0x80    ; 0-14, 15 means don't draw
D1Pos       EQU 0x81    ; 0-5
D1Pattern   EQU 0x82    ; 0-4
  PatStill  EQU 0       ; stay in same
  PatWiggle EQU 1       ; move from left to right and back
  PatJitter EQU 2       ; tight back and forth
  PatDie    EQU 3
D1PatIdx    EQU 0x83

D2Row       EQU 0x90    ; 0-14, 15 means don't draw
D2Pos       EQU 0x91    ; 0-5
D2Pattern   EQU 0x92    ; 0-4
D2PatIdx    EQU 0x93

; data locations

DigitTable  EQU 0x400
LogoTable   EQU 0x500
WiggleTable EQU 0x600
DemonTable  EQU 0x700
DeadTable   EQU 0x780

; REGISTERS
;
; R0 accumulator
; R1,R2 volatile, may be used as return values
; R3 left page (2 or 3)
; R4 right page (4 or 5)
; R5 row
; R6,R7 misc parameter
; R8 active demon page (8 or 9)

INIT:
    mov r0, F_100_kHz
    mov [Clock], r0
    mov r0, S_10_Hz         ; run at 10 fps
    mov [Sync], r0

    gosub SETUP_ATTRACT_STATE
    gosub SETUP_DRAWING_PAGE
    gosub FLIP_PAGES

LOOP:
    ; state machine for running animations
    ; between modes
    mov r0, [GameAnim]
    cp r0, WipeUp
    skip nz, 2
      goto WIPE_UP
    cp r0, WipeDown
    skip nz, 2
      goto WIPE_DOWN
FINISH_ANIM:
    ; state machine for running game modes
    mov r0, [GameState]
    cp r0, Attract
    skip nz, 2
      goto ATTRACT_MODE
    cp r0, Active
    skip nz, 2
      goto ACTIVE_MODE
    cp r0, ShowScore
    skip nz, 2
      goto SHOW_SCORE_MODE
FINISH_MODE:
    gosub FLIP_PAGES
    gosub CHECK_INPUT
    gosub CHECK_LIVES

    mov r0, [FrameNum]  ; increment FrameNum
    inc r0
    mov [FrameNum], r0

    gosub SETUP_DRAWING_PAGE
    gosub WAIT_FOR_SYNC
    jr LOOP

WIPE_UP:
    ; FIXME - implement wipe up animation
    jr FINISH_ANIM

WIPE_DOWN:
    ; FIXME - implement wipe down animation
    jr FINISH_ANIM

ATTRACT_MODE:
    ; attract mode has the base stationary
    ; at the bottom of the screen, while two
    ; demons fly back and forth on rows 0 & 3
    ; the word "DEMON" scrolls across in 5-pixel
    ; high letters on rows 6-A

    gosub MOVE_DEMONS_X
    gosub DRAW_DEMONS
    gosub DRAW_DEMON_LOGO
    jr FINISH_MODE

ACTIVE_MODE:
    gosub MOVE_SHOT
    gosub MOVE_DEMONS_X
    gosub MOVE_DEMONS_Y
    gosub ADD_DEMON_IF_NEEDED

    gosub DRAW_BASE
    gosub DRAW_DEMONS
    gosub DRAW_LIVES
    gosub DRAW_SHOT

    jr FINISH_MODE

SHOW_SCORE_MODE:
    gosub MOVE_DEMONS_X
    gosub DRAW_DEMONS
    gosub DRAW_SCORE
    jr FINISH_MODE

;
; Utility Functions
;

;; compute R2:R1 =  R1 << R0
LSL_16_BY_R0:
    mov r2, 0
LSL16_1:
    dec r0
    skip nc, 3
      add r1, r1
      adc r2, r2
      jr LSL16_1
    ret r0, 0

;; compute R1 = R1 << R0
LSL_8_BY_R0:
    dec r0
    skip nc, 2
      add r1, r1
      jr LSL_8_BY_R0
    ret r0, 0

;; compute R1 = R1 >> R0, no sign extension
LSR_8_BY_R0:
    dec R0
    skip nc, 3
      and r0, 0xf   ; clears carry without disturbing r0
      rrc r1
      jr LSR_8_BY_R0
    ret r0, 0

;; add 1 to BCD number in r2:r1, saturating at 99
SAT_INC_BCD:
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

;; turn the panel lights on or off
TOGGLE_PANEL:
    mov r0, [WrFlags]
    btg r0, LedsOff
    mov [WrFlags], r0
    ret r0, 0

;; halt execution until UserSync is set
WAIT_FOR_SYNC:
    mov r0, [RdFlags]
    bit r0, UserSync
    skip nz, 1
      jr WAIT_FOR_SYNC
    ret r0, 0

;; get a random number in the closed range 0..r1
GET_CONSTRAINED_RANDOM:
    mov r0, [Random]
    mov r2, r1
    sub r2, r0
    skip c, 1
      jr GET_CONSTRAINED_RANDOM
    mov r1, r0
    ret r0, 0

;
; General drawing functions
;

;; set page register to view current drawing page
;; before drawing more, increment [FrameNum] and call
;; SETUP_DRAWING_PAGE
FLIP_PAGES:
    mov r0, r3
    mov [Page], r0
    ret r0, 0

;; change the drawing page depending on [FrameNum]
;; and clear the new page to all 0
SETUP_DRAWING_PAGE:
    mov r0, [FrameNum]
    bit r0, 0       ; test for odd/even
    mov r0, 2       ; default to even frames drawing to pages 2/3
    skip z, 1       ; if odd...
      mov r0, 4     ; use pages 4/5 for odd frames
    mov r3, r0      ; setup r3 with right draw page
    mov r4, r0      ; then r4 has left draw page
    inc r4          ; as r3+1
    ; clear drawing pages
    mov r5, 0
    mov r0, 0
CLS_LOOP:
    mov [r3:r5], r0
    mov [r4:r5], r0
    inc r5
    skip c, 1
      jr CLS_LOOP
    ret r0, 0

;; draw data in R2:R1 to row r5
DRAW_ROW:
    mov r0, r1
    mov [r3:r5], r0
    mov r0, r2
    mov [r4:r5], r0
    ret r0, 0

;
; Game logic
;

;; when lives are 0, move from active to score mode
CHECK_LIVES:
    mov r0, [Lives]
    cp r0, 0
    skip z, 1
      ret r0, 0
    goto NEXT_STATE

;; adjust X position of the demons depending on their pattern
MOVE_DEMONS_X:
    mov r0, [D1Pos]
    mov r1, r0
    mov r0, [D1Pattern]
    mov r2, r0
    mov r0, [D1PatIdx]
    mov r7, r0
    gosub MOVE_DEMON_X
    mov r0, r1
    mov [D1Pos], r0
    mov r0, r7
    mov [D1PatIdx], r0

    mov r0, [D2Pos]
    mov r1, r0
    mov r0, [D2Pattern]
    mov r2, r0
    mov r0, [D2PatIdx]
    mov r7, r0
    gosub MOVE_DEMON_X
    mov r0, r1
    mov [D2Pos], r0
    mov r0, r7
    mov [D2PatIdx], r0
    ret r0, 0

MOVE_DEMON_X:       ; r1 has pos, r2 has pattern, r7 pattern index
    mov r0, r2
    cp r0, PatWiggle
    skip nz, 1
      jr WIGGLE_PATTERN
    cp r0, PatJitter
    skip nz, 1
      jr JITTER_PATTERN
    ret r0, 0

WIGGLE_PATTERN:
    ; increment index, lookup pos in 10 entry table
    inc r7
    mov r0, r7
    cp r0, 10
    skip nc, 1
      mov r0, 0
    mov r7, r0
    mov pc, [HIGH WiggleTable : MID WiggleTable]
    mov jsr, r7
    mov r1, r0
    ret r0, 0

JITTER_PATTERN:
    ; move position by +1 or -1 on alternating even frames
    mov r0, [FrameNum]
    bit r0, 0
    skip nz, 1
      ret r0, 0
    bit r0, 1
    skip nz, 1
      jr INC_POSITION
    jr DEC_POSITION

;; increment position value in r1, but
;; contrain it to 0-5
INC_POSITION:       ; r1 has pos in/out
    mov r0, r1      ; constrained to 0-5
    inc r0
    cp r0, 6
    skip nz, 1
      mov r0, 5
    mov r1, r0
    ret r0, 0

;; decrement position value in r1, but
;; contrain it to 0-5
DEC_POSITION:
    mov r0, r1
    dec r0
    skip c, 1
      mov r0, 0
    mov r1, r0
    ret r0, 0

;; move the demons down randomly, but don't allow
;; one demon to move past the other
MOVE_DEMONS_Y:
    mov r8, MID D1Row
    mov r9, MID D2Row
    gosub MOVE_DEMON_Y
    mov r8, MID D2Row
    mov r9, MID D1Row
    gosub MOVE_DEMON_Y
    ret r0, 0

MOVE_DEMON_Y:        ; r8 has demon pointer, r9 check demon pointer
    mov r0, [Random] ; only move down 1/4 time
    mov r1, 0b1110   ; so check random to see if
    and r0, r1       ; first three bits are set
    cp r0, 0b1110
    skip z, 1
      ret r0, 0

    mov r0, LOW D1Row
    mov r0, [r8:r0]
    mov r1, r0

    cp r0, 14       ; don't process hidden demons
    skip lt, 1
      ret r0, 0
    cp r0, 10       ; if we're in row 10, remove a life
    skip z, 1
      jr DROP_DEMON
    ; demon dies at the bottom too
    mov r0, PatDie
    mov r1, LOW D1Pattern
    mov [r8:r1], r0
    gosub DEC_LIVES
    ret r0, 0

DROP_DEMON:
    ; don't allow drop if it will push too close to other demon
    mov r0, LOW D1Row
    mov r0, [r9:r0]
    add r0, 13
    mov r2, r0      ; r2 is d2.row - 3
    sub r2, r1      ; compare to d1.row in r1
    skip nz, 1      ; if equal, return early
      ret r0, 0
    inc r1          ; add 1 to r1 and store back
    mov r0, r1
    mov r1, LOW D1Row
    mov [r8:r1], r0
    ret r0, 0

;; move the shot up one row if it's on screen and check
;; for collisions with the two demons
MOVE_SHOT:
    mov r0, [ShotRow]
    cp r0, 15
    skip nz, 1
      ret r0, 0
    dec r0
    mov [ShotRow], r0
    cp r0, 15       ; don't check for collision if moving into 15
    skip nz, 1
      ret r0, 0
    mov r1, r0      ; ShotRow in r1
    mov r0, [ShotPos]
    mov r2, r0      ; ShotPos in r2

    ; we want a collision if the shot is in the same position as
    ; the demon and either on the same row or one below.
CHECK_D1:
    mov r0, [D1Row]
    sub r0, r1
    cp r0, 2
    skip lt, 1
      jr CHECK_D2
    mov r0, [D1Pos]
    sub r0, r2
    skip z, 1
      jr CHECK_D2
    mov r0, PatDie
    mov [D1Pattern], r0
    gosub INC_SCORE
    mov r0, 15
    mov [ShotRow], r0
    ret r0, 0

CHECK_D2:
    mov r0, [D2Row]
    sub r0, r1
    cp r0, 2
    skip lt, 1
      ret r0, 0
    mov r0, [D2Pos]
    sub r0, r2
    skip z, 1
      ret r0, 0
    mov r0, PatDie
    mov [D2Pattern], r0
    gosub INC_SCORE
    mov r0, 15
    mov [ShotRow], r0
    ret r0, 0

ADD_DEMON_IF_NEEDED:
    ; if D1 or D2 is on row 15
    ; then look if the other is
    ; past row 4.
ADD_CHK_D1:
    mov r0, [D1Row]
    cp r0, 15           ; if this bird isn't visible
    skip z, 1
      jr ADD_CHK_D2
    mov r0, [D2Row]     ; and other bird is past row 4
    cp r0, 4
    skip gte, 1
      ret r0, 0         ; if we can't add, exit
    mov r8, MID D1Row
    jr GENERATE_RANDOM_DEMON

ADD_CHK_D2:
    mov r0, [D2Row]
    cp r0, 15           ; if this bird isn't visible
    skip z, 1
      ret r0, 0
    mov r0, [D1Row]     ; and other bird is past row 4
    cp r0, 4
    skip gte, 1
      ret r0, 0
    mov r8, MID D2Row
    ; fallthrough to GENERATE_RANDOM_DEMON

GENERATE_RANDOM_DEMON:  ; demon pointer in r8
    mov r1, 5
    gosub GET_CONSTRAINED_RANDOM
    mov r0, r1
    mov r1, LOW D1Pos
    mov [r8:r1], r0

    mov r1, 2
    gosub GET_CONSTRAINED_RANDOM
    mov r0, r1
    mov r1, LOW D1Pattern
    mov [r8:r1], r0

    mov r0, [Random]
    mov r1, LOW D1PatIdx
    mov [r8:r1], r0

    mov r0, 0
    mov r1, LOW D1Row
    mov [r8:r1], r0

    ret r0, 0

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
    ret r0, 0

NEXT_STATE:
    mov r0, [GameState]
    cp r0, Attract
    skip nz, 2
      mov r1, Active
      mov r2, WipeDown
    cp r0, Active
    skip nz, 2
      mov r1, ShowScore
      mov r2, WipeUp
    cp r0, ShowScore
    skip nz, 2
      mov r1, Attract
      mov r2, WipeDown
    mov r0, r2
    mov [GameAnim], r0
    mov r0, r1
    mov [GameState], r0

    ; setup state for the mode we just entered
    cp r0, Attract
    skip nz, 1
      jr SETUP_ATTRACT_STATE
    cp r0, Active
    skip nz, 1
      jr SETUP_ACTIVE_STATE
    cp r0, ShowScore
    skip nz, 1
      jr SETUP_SHOW_SCORE_STATE
    ret r0, 0

SETUP_ATTRACT_STATE:
    ; both demons wiggling back and forth on row 0 and 4
    ; in attract mode, patterns won't change
    mov r0, 0
    mov [D1Row], r0
    mov r0, 4
    mov [D2Row], r0
    ; don't need to set pos as that will be set by
    ; wiggle pattern and index
    mov r0, PatWiggle
    mov [D1Pattern], r0
    mov [D2Pattern], r0
    mov r0, 0
    mov [D1PatIdx], r0
    mov [LogoPosL], r0
    mov [LogoPosH], r0
    mov [PauseTimer], r0
    mov r0, 5
    mov [D2PatIdx], r0

    mov r0, NumLives
    mov [Lives], r0

    ret r0, 0

SETUP_ACTIVE_STATE:
    mov r0, 15          ; start with no demons on screen
    mov [D1Row], r0
    mov [D2Row], r0

    mov r0, 0
    mov [ScoreLow], r0
    mov [ScoreHigh], r0
    mov [PauseTimer], r0

    mov r0, NumLives
    mov [Lives], r0

    mov r0, 3
    mov [BasePos], r0

    mov r0, 15
    mov [ShotRow], r0

    ret r0, 0

SETUP_SHOW_SCORE_STATE:
    ; score screen has stationary demons flying above and below
    ; the score
    mov r0, 1
    mov [D1Row], r0
    mov r0, 4
    mov [D1Pos], r0
    mov r0, 11
    mov [D2Row], r0
    mov r0, 0
    mov [D2Pos], r0
    mov r0, PatStill
    mov [D1Pattern], r0
    mov [D2Pattern], r0
    mov r0, NumLives
    mov [Lives], r0
    mov r0, 8
    mov [PauseTimer], r0
    ret r0, 0

;
; Demon-specific drawing functions
;

DRAW_DEMON:         ; have demon row in r5, position in r6
    mov r0, r5      ; skip drawing if in row 14 or 15
    cp r0, 14
    skip lt, 1
      ret r0, 0

    mov r0, [FrameNum]  ; r7 = FrameNum & 3
    and r0, 0b0011
    mov r7, r0

    mov pch, HIGH DemonTable
    mov pcm, r7
    mov jsr, 0
    mov r1, r0
    mov r0, r6
    gosub LSL_16_BY_R0
    gosub DRAW_ROW

    inc r5
    mov pch, HIGH DemonTable
    mov pcm, r7
    mov jsr, 1
    mov r1, r0
    mov r0, r6
    gosub LSL_16_BY_R0
    gosub DRAW_ROW

    inc r5
    mov pch, HIGH DemonTable
    mov pcm, r7
    mov jsr, 2
    mov r1, r0
    mov r0, r6
    gosub LSL_16_BY_R0
    gosub DRAW_ROW

    ret r0, 0

DRAW_DEAD_DEMON:    ; have demon row in r5, position in r6
    mov r0, r5      ; skip drawing if in row 14 or 15
    cp r0, 14
    skip lt, 1
      ret r0, 0

    ; draw explosion as all 1s
    mov r1, 0b0111
    mov r0, r6
    gosub LSL_16_BY_R0
    gosub DRAW_ROW
    inc r5
    gosub DRAW_ROW
    inc r5
    gosub DRAW_ROW

    ret r0, 0

DRAW_DEMONS:        ; draw both demons with lifetime checking
DRAW_DEMON_1:
    mov r0, [D1Row]
    mov r5, r0
    mov r0, [D1Pos]
    mov r6, r0
    mov r0, [D1Pattern]
    cp r0, PatDie
    skip z, 3
      gosub DRAW_DEMON
      jr DRAW_DEMON_2
    gosub DRAW_DEAD_DEMON
    mov r0, 15
    mov [D1Row], r0

DRAW_DEMON_2:
    mov r0, [D2Row]
    mov r5, r0
    mov r0, [D2Pos]
    mov r6, r0
    mov r0, [D2Pattern]
    cp r0, PatDie
    skip z, 3
      gosub DRAW_DEMON
      ret r0, 0
    gosub DRAW_DEAD_DEMON
    mov r0, 15
    mov [D2Row], r0
    ret r0, 0

DRAW_BASE:
    mov r5, BaseRow
    mov r1, BaseTop
    mov r0, [BasePos]
    gosub LSL_16_BY_R0
    gosub DRAW_ROW
    inc r5
    mov r1, BaseBottom
    mov r0, [BasePos]
    gosub LSL_16_BY_R0
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

DRAW_SHOT:
    mov r0, [ShotRow]
    cp r0, 15           ; don't draw on row 15
    skip nz, 1
      ret r0, 0
    mov r5, r0
    mov r1, 0b0010
    mov r0, [ShotPos]
    gosub LSL_16_BY_R0
    ; instead of calling DRAW_ROW,
    ; inline a version that ORs shot
    ; with screen contents
    mov r0, [r3:r5]
    or r0, r1
    mov [r3:r5], r0
    mov r0, [r4:r5]
    or r0, r2
    mov [r4:r5], r0
    ret r0, 0

DRAW_SCORE:
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

DRAW_DEMON_LOGO:
    mov r5, 10      ; drawing row
    mov r8, 0       ; row counter
                    ; r7 used as temp

DRAW_DEMON_LOGO_LOOP:
    ; compute the LEFT as
    ; DT:Row:PosH << PosL | DT:Row:PosL+1 >> (4-PosL)

    mov pch, HIGH LogoTable
    mov pcm, r8
    mov r0, [LogoPosH]
    mov jsr, r0
    mov r1, r0          ; R1 = DT:Row:PosH

    mov r0, [LogoPosL]
    gosub LSL_8_BY_R0
    mov r7, r1          ; R7 = R1 >> PosL

    mov pch, HIGH LogoTable
    mov pcm, r8
    mov r0, [LogoPosH]
    inc r0
    mov jsr, r0
    mov r1, r0          ; R1 = DT:Row:PosH+1

    mov r0, [LogoPosL]
    mov r2, 4
    sub r2, r0
    mov r0, r2          ; R0 = 4 - PosL
    gosub LSR_8_BY_R0   ; R1 = R1 >> R0
    or r7, r1           ; R7 = R7 | R1
    mov r0, r7
    mov [r4:r5], r0     ; draw right side of row

    ; compute the RIGHT as
    ; DT:Row:PosH+1 << PosL | DT:Row:PosH+2 >> (4-PosL)

    mov pch, HIGH LogoTable
    mov pcm, r8
    mov r0, [LogoPosH]
    inc r0
    mov jsr, r0
    mov r1, r0          ; R1 = DT:Row:PosH+1

    mov r0, [LogoPosL]
    gosub LSL_8_BY_R0
    mov r7, r1          ; R7 = R1 >> PosL

    mov pch, HIGH LogoTable
    mov pcm, r8
    mov r0, [LogoPosH]
    add r0, 2
    mov jsr, r0
    mov r1, r0          ; R1 = DT:Row:PosH+2

    mov r0, [LogoPosL]
    mov r2, 4
    sub r2, r0
    mov r0, r2          ; R0 = 4 - PosL
    gosub LSR_8_BY_R0   ; R1 = R1 >> R0
    or r7, r1           ; R7 = R7 | R1
    mov r0, r7
    mov [r3:r5], r0     ; draw right side of row

    inc r5
    inc r8
    mov r0, r8
    cp r0, 5
    skip z, 1
      jr DRAW_DEMON_LOGO_LOOP

INC_LOGO_POS:
    ; logo is 56 bits wide
    ; max position we allow is 48, which is
    ; c:0, so special case that
    mov r0, [LogoPosH]
    cp r0, 0xc
    skip ne, 4
      mov r0, 0
      mov [LogoPosH], r0
      mov [LogoPosL], r0
      ret r0, 0
    ; other values will increment with
    ; special carry handling, since we're
    ; only using a limited range for the L
    ; value
    mov r0, [LogoPosL]
    inc r0
    cp r0, 4
    skip lt, 1
      mov r0, 0
    mov [LogoPosL], r0
    skip gte,1
      ret r0, 0
    ; LogoPosH = LogoPosH + 1
    ; it will never go above 6, so no need to mask
    mov r0, [LogoPosH]
    inc r0
    mov [LogoPosH], r0
    ret r0, 0

;
; Input handling
;

CHECK_INPUT:
    ; if PauseTimer > 0, decrement it and return early
    mov r0, [PauseTimer]
    dec r0
    skip nc, 1
      mov [PauseTimer], r0

    ; if game mode isn't active, most key presses
    ; will jump to next mode
    mov r0, [GameState]
    mov r2, r0

    mov r0, [KeyStatus]
    bit r0, JustPress
    skip nz, 1
      ret r0, 0             ; exit if no keys were pressed

    mov r0, [KeyReg]
    cp r0, Btn_Opc_8        ; DEBUG - toggle panel LEDs
    skip nz, 2
        goto TOGGLE_PANEL
    cp r0, Btn_Opc_4        ; DEBUG - next state
    skip nz, 2
        goto NEXT_STATE
    cp r0, Btn_Opc_2        ; DEBUG - lose life
    skip nz, 2
        goto DEC_LIVES

    mov r1, r0              ; return early if PauseTimer != 0
    mov r0, [PauseTimer]
    dec r0
    skip nc, 1
      ret r0, 0
    mov r0, r1

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

MOVE_BASE_LEFT:             ; game state in r2
    mov r0, r2
    cp r0, Active
    skip z, 1
      ret r0, 0             ; do nothing if not active state
    mov r0, [BasePos]
    mov r1, r0
    gosub INC_POSITION
    mov r0, r1
    mov [BasePos], r0
    ret r0, 0

MOVE_BASE_RIGHT:            ; game state in r2
    mov r0, r2
    cp r0, Active
    skip z, 1
      ret r0, 0             ; do nothing if not active state
    mov r0, [BasePos]
    mov r1, r0
    gosub DEC_POSITION
    mov r0, r1
    mov [BasePos], r0
    ret r0, 0

FIRE_SHOT:                  ; game state in r2
    mov r0, r2
    cp r0, Active
    skip z, 2
      goto NEXT_STATE       ; go to next state if not active
    mov r0, [ShotRow]
    cp r0, 15               ; only fire if no shot on screen
    skip z, 1
      ret r0, 0
    mov r0, 12              ; start on base top
    mov [ShotRow], r0
    mov r0, [BasePos]       ; and at BasePos
    mov [ShotPos], r0
    ret r0, 0

;
; DATA TABLES
;

    ORG DigitTable + 0x00
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0101
    NIBBLE 0b0101
    NIBBLE 0b0111
    ORG DigitTable + 0x10
    NIBBLE 0b0010
    NIBBLE 0b0110
    NIBBLE 0b0010
    NIBBLE 0b0010
    NIBBLE 0b0111
    ORG DigitTable + 0x20
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0010
    NIBBLE 0b0100
    NIBBLE 0b0111
    ORG DigitTable + 0x30
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0011
    NIBBLE 0b0001
    NIBBLE 0b0111
    ORG DigitTable + 0x40
    NIBBLE 0b0101
    NIBBLE 0b0101
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0001
    ORG DigitTable + 0x50
    NIBBLE 0b0111
    NIBBLE 0b0100
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0111
    ORG DigitTable + 0x60
    NIBBLE 0b0111
    NIBBLE 0b0100
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0111
    ORG DigitTable + 0x70
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0010
    NIBBLE 0b0010
    NIBBLE 0b0010
    ORG DigitTable + 0x80
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0111
    ORG DigitTable + 0x90
    NIBBLE 0b0111
    NIBBLE 0b0101
    NIBBLE 0b0111
    NIBBLE 0b0001
    NIBBLE 0b0111

    ; organized as 5 lines of 14 nibbles
    ; leading and trailing 2 nibbles are blank
    ; to make scrolling look continuous
    ORG LogoTable + 0x00
    NIBBLE 0b0000
    NIBBLE 0b0000
    NIBBLE 0b1110
    NIBBLE 0b0111
    NIBBLE 0b1011
    NIBBLE 0b0110
    NIBBLE 0b0110
    NIBBLE 0b0110
    NIBBLE 0b1000
    NIBBLE 0b0000
    NIBBLE 0b0010
    NIBBLE 0b0100
    NIBBLE 0b0000
    NIBBLE 0b0000
    ORG LogoTable + 0x10
    NIBBLE 0b0000
    NIBBLE 0b0000
    NIBBLE 0b1001
    NIBBLE 0b0100
    NIBBLE 0b0010
    NIBBLE 0b1010
    NIBBLE 0b1001
    NIBBLE 0b0111
    NIBBLE 0b1000
    NIBBLE 0b0000
    NIBBLE 0b0101
    NIBBLE 0b1010
    NIBBLE 0b0000
    NIBBLE 0b0000
    ORG LogoTable + 0x20
    NIBBLE 0b0000
    NIBBLE 0b0000
    NIBBLE 0b1001
    NIBBLE 0b0111
    NIBBLE 0b0010
    NIBBLE 0b1010
    NIBBLE 0b1001
    NIBBLE 0b0101
    NIBBLE 0b1000
    NIBBLE 0b0000
    NIBBLE 0b1011
    NIBBLE 0b1101
    NIBBLE 0b0000
    NIBBLE 0b0000
    ORG LogoTable + 0x30
    NIBBLE 0b0000
    NIBBLE 0b0000
    NIBBLE 0b1001
    NIBBLE 0b0100
    NIBBLE 0b0010
    NIBBLE 0b0010
    NIBBLE 0b1001
    NIBBLE 0b0100
    NIBBLE 0b1000
    NIBBLE 0b0000
    NIBBLE 0b1001
    NIBBLE 0b1001
    NIBBLE 0b0000
    NIBBLE 0b0000
    ORG LogoTable + 0x40
    NIBBLE 0b0000
    NIBBLE 0b0000
    NIBBLE 0b1110
    NIBBLE 0b0111
    NIBBLE 0b1010
    NIBBLE 0b0010
    NIBBLE 0b0110
    NIBBLE 0b0100
    NIBBLE 0b1000
    NIBBLE 0b0000
    NIBBLE 0b1010
    NIBBLE 0b0101
    NIBBLE 0b0000
    NIBBLE 0b0000

    ORG WiggleTable
    NIBBLE 0
    NIBBLE 1
    NIBBLE 2
    NIBBLE 3
    NIBBLE 4
    NIBBLE 5
    NIBBLE 4
    NIBBLE 3
    NIBBLE 2
    NIBBLE 1

    ; organized by frame (0-3) and pos (0-3)
    ORG DemonTable + 0x00
    NIBBLE 0b0101
    NIBBLE 0b0010
    NIBBLE 0b0000

    ORG DemonTable + 0x10
    NIBBLE 0b0000
    NIBBLE 0b0111
    NIBBLE 0b0000

    ORG DemonTable + 0x20
    NIBBLE 0b0000
    NIBBLE 0b0010
    NIBBLE 0b0101

    ORG DemonTable + 0x30
    NIBBLE 0b0000
    NIBBLE 0b0111
    NIBBLE 0b0000
