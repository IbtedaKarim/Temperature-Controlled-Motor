;====================================================================
; INTEGRATED SYSTEM: PASSWORD PROTECTED TEMPERATURE CONTROL
;====================================================================
RS      EQU     P2.0
EN      EQU     P2.2

PASS_D1 EQU     1
PASS_D2 EQU     2
PASS_D3 EQU     3
PASS_D4 EQU     4

ADC_PORT EQU    P1
LCD_PORT EQU    P0

ADC_WR  EQU     P2.3
MTR1_EN EQU     P2.4
MTR2_EN EQU     P2.1
MTR1_IN EQU     P2.6
MTR2_IN EQU     P2.5
BUZZER  EQU     P2.7

TEMP      EQU     30H
PSET      EQU     31H
L_NRML    EQU     32H
H_NRML    EQU     33H
TOO_HI    EQU     34H
AUD_STL   EQU     35H
COUNTER   EQU     36H
DUTY      EQU     37H
SYS_FLAG  EQU     38H
MODE      EQU     39H
INPUT_ST  EQU     3AH
DIGIT_BUF EQU     3BH
DIGIT_TMP EQU     3CH

;====================================================================
; RESET VECTORS
;====================================================================
        ORG     00H
        LJMP    MAIN

        ORG     000BH
        LJMP    ISR_T0

        ORG     001BH
        LJMP    ISR_T1

        ORG     30H

;====================================================================
; MAIN INITIALIZATION
;====================================================================
MAIN:
        MOV     P0, #00H
        MOV     P1, #0FFH
        MOV     P2, #00H
        MOV     P3, #0FEH

        MOV     COUNTER,  #00H
        MOV     AUD_STL,  #00H
        MOV     DUTY,      #00H
        MOV     SYS_FLAG, #00H
        MOV     MODE,      #00H
        MOV     INPUT_ST, #00H
        
        ACALL   LCD_INIT_PASS

        MOV     R0, #01H
        ACALL   COMMAND
        MOV     DPTR, #MSG_START
DO_LOOP1:
        CLR     A
        MOVC    A, @A+DPTR
        MOV     R0, A
        JZ      EXIT1
        ACALL   DISPLAY
        ACALL   DELAY
        INC     DPTR
        SJMP    DO_LOOP1
EXIT1:
        ACALL   DELAY
        MOV     R0, #01H
        ACALL   COMMAND

        MOV     R0, #80H
        ACALL   COMMAND
        MOV     DPTR, #MSG_PROMPT
DO_LOOP2:
        CLR     A
        MOVC    A, @A+DPTR
        MOV     R0, A
        JZ      EXIT2
        ACALL   DISPLAY
        INC     DPTR
        SJMP    DO_LOOP2
EXIT2:
        MOV     R0, #0C0H
        ACALL   COMMAND

        CLR     TR0
        CLR     TR1

;====================================================================
; KEYPAD SCAN LOOP
;====================================================================
L1:
        JNB     P3.0, C1
        JNB     P3.1, C2
        JNB     P3.2, C3
        JNB     P3.3, C4
        SJMP    L1

C1:
        JNB     P3.4, JUMP_TO_7
        JNB     P3.5, JUMP_TO_4
        JNB     P3.6, JUMP_TO_1
        JNB     P3.7, JUMP_2CLR
        SETB    P3.0
        CLR     P3.1
        SJMP    L1

C2:
        JNB     P3.4, JUMP_TO_8
        JNB     P3.5, JUMP_TO_5
        JNB     P3.6, JUMP_TO_2
        JNB     P3.7, JUMP_TO_0
        SETB    P3.1
        CLR     P3.2
        SJMP    L1

C3:
        JNB     P3.4, JUMP_TO_9
        JNB     P3.5, JUMP_TO_6
        JNB     P3.6, JUMP_TO_3
        JNB     P3.7, JUMP_EQUAL
        SETB    P3.2
        CLR     P3.3
        SJMP    L1

C4:
        JNB     P3.4, JUMP_IGNORE
        JNB     P3.5, JUMP_IGNORE
        JNB     P3.6, JUMP_IGNORE
        JNB     P3.7, JUMP_IGNORE
        SETB    P3.3
        CLR     P3.0
        LJMP    L1

JUMP_2CLR:      LJMP    JUMP_RFRESH
JUMP_TO_0:      LJMP    NUM_0
JUMP_TO_1:      LJMP    NUM_1
JUMP_TO_2:      LJMP    NUM_2
JUMP_TO_3:      LJMP    NUM_3
JUMP_TO_4:      LJMP    NUM_4
JUMP_TO_5:      LJMP    NUM_5
JUMP_TO_6:      LJMP    NUM_6
JUMP_TO_7:      LJMP    NUM_7
JUMP_TO_8:      LJMP    NUM_8
JUMP_TO_9:      LJMP    NUM_9
JUMP_EQUAL:     LJMP    L1
JUMP_IGNORE:    LJMP    L1

;====================================================================
; CLEAR / RESET
;====================================================================
JUMP_RFRESH:
        MOV     A, SYS_FLAG
        JNZ     SYSTEM_ACTIVE_RESET
        MOV     R0, #01H
        ACALL   COMMAND
        MOV     R5, #00H
        LJMP    MAIN

SYSTEM_ACTIVE_RESET:
        MOV     R5, #00H
        LJMP    L1

;====================================================================
; NUMBER KEYS
;====================================================================
NUM_0:
        JNB     P3.7, NUM_0
        MOV     R0, #'0'
        ACALL   DISPLAY
        MOV     A, #0D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_1:
        JNB     P3.6, NUM_1
        MOV     R0, #'1'
        ACALL   DISPLAY
        MOV     A, #1D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_2:
        JNB     P3.6, NUM_2
        MOV     R0, #'2'
        ACALL   DISPLAY
        MOV     A, #2D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_3:
        JNB     P3.6, NUM_3
        MOV     R0, #'3'
        ACALL   DISPLAY
        MOV     A, #3D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_4:
        JNB     P3.5, NUM_4
        MOV     R0, #'4'
        ACALL   DISPLAY
        MOV     A, #4D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_5:
        JNB     P3.5, NUM_5
        MOV     R0, #'5'
        ACALL   DISPLAY
        MOV     A, #5D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_6:
        JNB     P3.5, NUM_6
        MOV     R0, #'6'
        ACALL   DISPLAY
        MOV     A, #6D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_7:
        JNB     P3.4, NUM_7
        MOV     R0, #'7'
        ACALL   DISPLAY
        MOV     A, #7D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_8:
        JNB     P3.4, NUM_8
        MOV     R0, #'8'
        ACALL   DISPLAY
        MOV     A, #8D
        ACALL   SAVE_DIGIT
        LJMP    L1

NUM_9:
        JNB     P3.4, NUM_9
        MOV     R0, #'9'
        ACALL   DISPLAY
        MOV     A, #9D
        ACALL   SAVE_DIGIT
        LJMP    L1

;====================================================================
; SAVE_DIGIT
;====================================================================
SAVE_DIGIT:
        MOV     DIGIT_TMP, A
        MOV     A, SYS_FLAG
        CJNE    A, #00H, SD_TO_THRESH
        MOV     A, DIGIT_TMP
        SJMP    SD_PASSWORD
SD_TO_THRESH:
        MOV     A, DIGIT_TMP
        LJMP    THRESHOLD_INPUT

SD_PASSWORD:
        CJNE    R5, #0D, SD_TRY2
        MOV     R1, A
        INC     R5
        RET
SD_TRY2:
        CJNE    R5, #1D, SD_TRY3
        MOV     R2, A
        INC     R5
        RET
SD_TRY3:
        CJNE    R5, #2D, SD_TRY4
        MOV     R3, A
        INC     R5
        RET
SD_TRY4:
        MOV     R4, A
        INC     R5
        ACALL   CHECK_PASSWORD
        RET

;====================================================================
; THRESHOLD_INPUT
;====================================================================
THRESHOLD_INPUT:
        MOV     A, INPUT_ST
        CJNE    A, #00H, TH_TRY1
        MOV     DIGIT_BUF, DIGIT_TMP
        INC     INPUT_ST
        RET
TH_TRY1:
        CJNE    A, #01H, TH_TRY2
        MOV     A, DIGIT_BUF
        MOV     B, #10D
        MUL     AB
        ADD     A, DIGIT_TMP
        MOV     L_NRML, A
        INC     INPUT_ST
        ACALL   DELAY           
        MOV     R0, #01H        
        ACALL   COMMAND
        MOV     R0, #80H
        ACALL   COMMAND
        MOV     DPTR, #MSG_TMAX
        ACALL   PRNT_STRNG_TEMP
        MOV     R0, #0C0H       
        ACALL   COMMAND
        RET
TH_TRY2:
        CJNE    A, #02H, TH_TRY3
        MOV     DIGIT_BUF, DIGIT_TMP
        INC     INPUT_ST
        RET
TH_TRY3:
        CJNE    A, #03H, TH_TRY4
        MOV     A, DIGIT_BUF
        MOV     B, #10D
        MUL     AB
        ADD     A, DIGIT_TMP
        MOV     H_NRML, A
        ADD     A, #10D
        MOV     TOO_HI, A
        INC     INPUT_ST
        ACALL   DELAY           
        MOV     R0, #01H
        ACALL   COMMAND
        MOV     R0, #80H
        ACALL   COMMAND
        MOV     DPTR, #MSG_MODE
        ACALL   PRNT_STRNG_TEMP
        MOV     R0, #0C0H       
        ACALL   COMMAND
        RET
TH_TRY4:
        MOV     A, DIGIT_TMP
        MOV     MODE, A
        ACALL   DELAY           
        MOV     SYS_FLAG, #02H
        LJMP    ACTIVATE_TEMP_SYSTEM

;====================================================================
; CHECK_PASSWORD
;====================================================================
CHECK_PASSWORD:
        CJNE    R1, #PASS_D1, WRONG_PASS
        CJNE    R2, #PASS_D2, WRONG_PASS
        CJNE    R3, #PASS_D3, WRONG_PASS
        CJNE    R4, #PASS_D4, WRONG_PASS

CORRECT_PASS:
        MOV     R0, #0C0H
        ACALL   COMMAND
        MOV     DPTR, #MSG_OK
        ACALL   PRINT_RESULT
        ACALL   DELAY
        MOV     SYS_FLAG, #01H
        MOV     INPUT_ST, #00H
        MOV     R0, #01H
        ACALL   COMMAND
        MOV     R0, #80H
        ACALL   COMMAND
        MOV     DPTR, #MSG_TMIN
        ACALL   PRNT_STRNG_TEMP
        MOV     R0, #0C0H       
        ACALL   COMMAND
        RET

WRONG_PASS:
        MOV     R0, #0C0H
        ACALL   COMMAND
        MOV     DPTR, #MSG_FAIL
        ACALL   PRINT_RESULT
        ACALL   DELAY
        LJMP    JUMP_RFRESH

PRINT_RESULT:
        CLR     A
        MOV     R7, #0D
PR_LOOP:
        MOV     A, R7
        MOVC    A, @A+DPTR
        MOV     R0, A
        JZ      PR_DONE
        ACALL   DISPLAY
        INC     R7
        SJMP    PR_LOOP
PR_DONE:
        RET

;====================================================================
; ACTIVATE_TEMP_SYSTEM
;====================================================================
ACTIVATE_TEMP_SYSTEM:
        MOV     R0, #01H
        ACALL   COMMAND
        MOV     R0, #80H
        ACALL   COMMAND
        MOV     DPTR, #MSG1
        ACALL   PRNT_STRNG_TEMP
        LCALL   SETUP_TMR0
        LCALL   SETUP_TMR1
        LJMP    TEMP_CONTROL_LOOP

;====================================================================
; TEMPERATURE CONTROL LOOP
;====================================================================
TEMP_CONTROL_LOOP:
        CLR     ADC_WR
        SETB    ADC_WR
RD_ADC:
        MOV     A, ADC_PORT
        MOV     TEMP, A
        ACALL   CHECK_TEMP
        LCALL   CTRL_FAN
        ACALL   DISPLAY_STATUS
        LJMP    TEMP_CONTROL_LOOP

;====================================================================
; CTRL_FAN
;====================================================================
CTRL_FAN:
        MOV     A, AUD_STL
        JZ      CF_NO_ALARM
        MOV     DUTY, #0FFH
        RET

CF_NO_ALARM:
        MOV     A, MODE
        CJNE    A, #01H, CF_GRADUAL

CF_BINARY:
        ; Mode 1: TEMP > Tmax ? max speed (FFH), else ? 50% speed (80H)
        MOV     A, TEMP
        CLR     C
        SUBB    A, H_NRML
        JNC     CF_BIN_MAX
        MOV     DUTY, #80H      ; below or equal Tmax ? 50% speed
        RET
CF_BIN_MAX:
        MOV     DUTY, #0FFH     ; above Tmax ? maximum speed
        RET



CF_GRADUAL:
        ;--- Boundary checks ---
        MOV     A, TEMP
        CLR     C
        SUBB    A, H_NRML
        JNC     CF_GRAD_MAX         ; TEMP >= Tmax ? 100%

        MOV     A, TEMP
        CLR     C
        SUBB    A, L_NRML
        JC      CF_GRAD_MIN         ; TEMP < Tmin  ? 50%

        ;--- Compute scale factor: R7 = Tmax - Tmin ---
        MOV     A, H_NRML
        CLR     C
        SUBB    A, L_NRML
        JZ      CF_GRAD_MAX         ; guard: Tmin == Tmax
        MOV     R7, A               ; R7 = Tmax - Tmin

        ;--- Compute numerator: A = TEMP - Tmin ---
        MOV     A, TEMP
        CLR     C
        SUBB    A, L_NRML           ; A = TEMP - Tmin   [0 .. R7-1]

        ;--- Multiply: B:A = (TEMP-Tmin) * 127 ---
        MOV     B, #127D
        MUL     AB                  ; B=high byte, A=low byte  [16-bit]

        ;--- Save low byte; check if high byte causes overflow ---
        MOV     R6, A               ; R6 = product_low
        MOV     A, B                ; A  = product_high
        CLR     C
        SUBB    A, R7               ; if product_high >= R7, result > 255
        JNC     CF_GRAD_MAX         ; overflow clamp ? use 100%

        ;--- 16-bit ÷ 8-bit division using shift-subtract (8 bits) ---
        ; Dividend:  R3(hi) : R6(lo)   Divisor: R7
        ; Quotient result ? A
        MOV     R3, B               ; R3 = product_high (original, pre-SUBB)
        ; * R3 was clobbered by SUBB A,R7 above via A, not R3. Safe. *
        ; Restore: R3 = original B (product_high). We already moved it to A
        ; and A now holds (B - R7). So restore R3 from the pre-sub value:
        ADD     A, R7               ; A = product_high restored
        MOV     R3, A               ; R3 = product_high  ?

        MOV     A,  #00H            ; accumulator for quotient
        MOV     R5, #08H            ; 8-bit result
DIVLOOP:
        ; Shift left: C ? R3(msb), R3 ? R3<<1, LSB of R3 ? R6(msb), R6 ? R6<<1
        CLR     C
        MOV     A,  R6
        RLC     A                   ; shift R6 left; old MSB ? C
        MOV     R6, A
        MOV     A,  R3
        RLC     A                   ; shift R3 left with bit from R6; old MSB ? C
        MOV     R3, A
        ; Now C = shifted-out MSB (overflow bit, should be 0 for valid range)

        ; Partial remainder in R3; try subtract divisor R7
        CLR     C
        SUBB    A, R7               ; A = R3 - R7
        JC      DIV_NO_SUB          ; if borrow, R3 < R7, don't subtract
        MOV     R3, A               ; accept subtraction
        ; set quotient bit: shift quotient left 1 with bit=1
        MOV     A, #00H
        SETB    C                   ; quotient bit = 1
        SJMP    DIV_SHIFT_Q
DIV_NO_SUB:
        CLR     C                   ; quotient bit = 0
DIV_SHIFT_Q:
        ; We accumulate quotient in R4 (shift left + insert C)
        MOV     A, R4
        RLC     A
        MOV     R4, A
        DJNZ    R5, DIVLOOP

        ;--- Final duty = 128 + quotient ---
        MOV     A, R4
        ADD     A, #128D
        MOV     DUTY, A
        RET

CF_GRAD_MIN:
        MOV     DUTY, #80H          ; 50% duty cycle
        RET
CF_GRAD_MAX:
        MOV     DUTY, #0FFH         ; 100% duty cycle
        RET
;====================================================================
; CHECK_TEMP (Logic for Display & Buzzer)
;====================================================================
CHECK_TEMP:
        MOV     A, TEMP
        CLR     C
        SUBB    A, TOO_HI
        JNC     _2HI
        MOV     A, TEMP
        CLR     C
        SUBB    A, H_NRML
        JNC     _HI
        MOV     A, TEMP
        CLR     C
        SUBB    A, L_NRML
        JC      _LO

_NRM:
        SETB    MTR1_EN
        CLR     MTR2_EN
        ; FIX: Use CLR to ensure LED/Buzzer is OFF in Normal range
        CLR     BUZZER          
        CLR     TR1
        MOV     AUD_STL, #00H
        MOV     DPTR, #STR_NR
        LCALL   PRNT_STAT_TEMP
        RET
_2HI:
        SETB    MTR1_EN
        CLR     MTR2_EN
        MOV     AUD_STL, #0FFH
        SETB    TR1
        MOV     DPTR, #STR_2H
        LCALL   PRNT_STAT_TEMP
        RET
_HI:
        SETB    MTR1_EN
        CLR     MTR2_EN
        MOV     AUD_STL, #00H
        SETB    TR1
        MOV     DPTR, #STR_HI
        LCALL   PRNT_STAT_TEMP
        RET
        
_LO:
        SETB    MTR1_EN
        CLR     MTR2_EN
        MOV     AUD_STL, #00H
        CLR     TR1                 ; no alert needed for LOW
        CLR     BUZZER
        MOV     DPTR, #STR_LO
        LCALL   PRNT_STAT_TEMP
        RET
        
_LO_STOP:
        CLR     MTR1_EN   
_LO_DISP:
        CLR     MTR2_EN
        MOV     AUD_STL, #00H
        SETB    TR1
        MOV     DPTR, #STR_LO
        LCALL   PRNT_STAT_TEMP
        RET

;====================================================================
; LCD & TIMER SUBROUTINES
;====================================================================
PRNT_STAT_TEMP:
        MOV     R0, #0C0H
        ACALL   COMMAND
PRNT_STRNG_TEMP:
        CLR     A
        MOVC    A, @A+DPTR
        MOV     R0, A
        JZ      END_STRNG_TEMP
        ACALL   DISPLAY
        INC     DPTR
        SJMP    PRNT_STRNG_TEMP
END_STRNG_TEMP:
        RET

SETUP_TMR0:
        MOV     TMOD, #01H
        SETB    EA
        SETB    ET0
        SETB    TR0
        RET

SETUP_TMR1:
        ORL     TMOD, #10H
        MOV     TL1, #00H
        MOV     TH1, #00H
        SETB    ET1
        SETB    TR1
        RET

ISR_T0:
        JB      F0, HIGH_DONE
        SETB    F0
        SETB    MTR1_IN
        MOV     TH0, DUTY
        MOV     TL0, #00H
        RETI
HIGH_DONE:
        CLR     F0
        CLR     MTR1_IN
        MOV     A, #0FFH
        CLR     C
        SUBB    A, DUTY
        MOV     TH0, A
        MOV     TL0, #00H
        RETI

ISR_T1:
        PUSH    07H
        INC     COUNTER
        MOV     R7, COUNTER
        MOV     A, AUD_STL
        JZ      OUT_RANGE
        CPL     BUZZER
        SJMP    LEAVE
OUT_RANGE:
        ; Non-Critical alert (Normal/Low/High but not Danger)
        ; Toggles the pin to make the LED blink or stay off
        CJNE    R7, #03D, LEAVE
        CLR     BUZZER
        CLR     COUNTER
LEAVE:
        MOV     TH1, #0C0H
        MOV     TL1, #00H
        POP     07H
        RETI

DISPLAY_STATUS:
        MOV     R0, #80H
        ACALL   COMMAND

        MOV     DPTR, #MSG1
        ACALL   PRNT_STRNG_TEMP

        MOV     A, TEMP
        MOV     B, #10D
        DIV     AB
        ADD     A, #30H
        MOV     R0, A
        ACALL   DISPLAY
        MOV     A, B
        ADD     A, #30H
        MOV     R0, A
        ACALL   DISPLAY

        MOV     DPTR, #MSG_DC
        ACALL   PRNT_STRNG_TEMP

      MOV     A, DUTY
        MOV     B, #100D
        MUL     AB
        ; A = low byte, B = high byte of DUTY*100
        ; Simple approach: since DUTY<=255 and 255*100=25500 fits in 16-bit,
        ; divide by 255 using repeated subtraction on 16-bit value
        MOV     R6, A           ; R6 = low byte
        MOV     R3, B           ; R3 = high byte
        MOV     R4, #00H        ; R4 = quotient (duty%)
DC_DIV_LOOP:
        ; Check if R3:R6 >= 255 (i.e. R3 > 0 OR R6 >= 255)
        MOV     A, R3
        JNZ     DC_CAN_SUB      ; high byte non-zero means value > 255
        MOV     A, R6
        CLR     C
        SUBB    A, #255D
        JC      DC_DIV_DONE     ; R6 < 255, stop
DC_CAN_SUB:
        ; Subtract 255 from R3:R6
        MOV     A, R6
        CLR     C
        SUBB    A, #255D
        MOV     R6, A
        MOV     A, R3
        SUBB    A, #00H         ; borrow from high byte
        MOV     R3, A
        INC     R4              ; quotient++
        SJMP    DC_DIV_LOOP
DC_DIV_DONE:

        MOV     A, R4
        MOV     B, #100D
        DIV     AB
        ADD     A, #30H
        MOV     R0, A
        ACALL   DISPLAY
        MOV     A, B
        MOV     B, #10D
        DIV     AB
        ADD     A, #30H
        MOV     R0, A
        ACALL   DISPLAY
        MOV     A, B
        ADD     A, #30H
        MOV     R0, A
        ACALL   DISPLAY

        MOV     DPTR, #MSG_MODE_D
        ACALL   PRNT_STRNG_TEMP

        MOV     A, MODE
        ADD     A, #30H
        MOV     R0, A
        ACALL   DISPLAY

        MOV     R0, #0C0H
        ACALL   COMMAND
        RET

LCD_INIT_PASS:
        MOV     R0, #38H
        ACALL   COMMAND
        MOV     R0, #0EH
        ACALL   COMMAND
        MOV     R0, #01H
        ACALL   COMMAND
        MOV     R0, #06H
        ACALL   COMMAND
        RET

DISPLAY:
        MOV     LCD_PORT, R0
        SETB    RS
        SETB    EN
        ACALL   DELAY
        CLR     EN
        RET
COMMAND:
        MOV     LCD_PORT, R0
        CLR     RS
        SETB    EN
        ACALL   DELAY
        CLR     EN
        RET

DELAY:
        MOV     62, #2
D1:     MOV     61, #100
D2:     MOV     60, #250
        DJNZ    60, $
        DJNZ    61, D2
        DJNZ    62, D1
        RET

;====================================================================
; MESSAGES
;====================================================================
MSG_START:  DB 'TEMP CTRL SYS   ', 0
MSG_PROMPT: DB 'Enter Password: ', 0
MSG_OK:     DB 'ACCESS GRANTED  ', 0
MSG_FAIL:   DB 'ACCESS DENIED   ', 0
MSG_TMIN:   DB 'Enter Tmin(2dig)', 0
MSG_TMAX:   DB 'Enter Tmax(2dig)', 0
MSG_MODE:   DB 'Mode:1=Bin 2=Grd', 0
MSG1:       DB 'T=', 0
MSG_DC:     DB ' DC=', 0
MSG_MODE_D: DB ' M-', 0
STR_2H:     DB 'DANGER', 0
STR_HI:     DB 'HIGH  ', 0
STR_NR:     DB 'NORMAL', 0
STR_LO:     DB 'LOW   ', 0

        END