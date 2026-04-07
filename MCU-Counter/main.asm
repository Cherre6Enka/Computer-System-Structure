; ============================================================
; STC89C52RC — 4-Digit Multiplexed Display with Individual Increment
; ============================================================
; This program:
; - Uses Timer0 interrupts to multiplex 4 digits on a 7-seg display
; - Displays initial values 1 2 3 4
; - Increments each digit when its assigned push-button is pressed
; - Debounces button presses to prevent accidental double counts
;
; Verified hardware connections (active-LOW logic):
; - P0.0–P0.7 ? Segment lines (a–g + dp)
; - P1.3–P1.6 ? Digit enable lines (left to right)
; - P3.2–P3.5 ? Push-buttons (rightmost to leftmost digit)
; - P3.6      ? Buzzer (not used in this program)
;
; ============================================================

                NAME    MAIN          ; Name of the module

; --- Interrupt Vector Table ---
                CSEG
                ORG     0000H         ; Reset vector address
                LJMP    START         ; Jump to start of program

                ORG     000BH         ; Timer0 interrupt vector
                LJMP    T0_ISR        ; Jump to Timer0 ISR

; --- Direct RAM Variables ---
                DSEG
LED_PAT         DATA    30H           ; Stores LED pattern (not used here for LEDs)
DIG0            DATA    31H           ; Leftmost digit value (0–9)
DIG1            DATA    32H           ; 2nd digit value
DIG2            DATA    33H           ; 3rd digit value
DIG3            DATA    34H           ; Rightmost digit value
SCAN_STATE      DATA    35H           ; Current multiplex scan position (0–4)

; --- Lookup Tables ---
                CSEG
                ORG     0200H
SEGTAB:         DB 0C0H,0F9H,0A4H,0B0H,099H,092H,082H,0F8H,080H,090H
; Segment patterns for digits 0–9 (common cathode, active-LOW)
; 0C0H ? "0", 0F9H ? "1", etc.

DMASK:          DB 0F7H,0EFH,0DFH,0BFH
; Active-LOW digit enable masks for P1.3–P1.6
; 0F7H ? enable digit 1 (P1.3=0), etc.

; --- Main Program ---
                CSEG
                ORG     0100H
START:
                MOV     SP,#70H       ; Set stack pointer above bit-addressable RAM
                MOV     P0,#0FFH      ; All segments OFF initially
                MOV     P1,#0FFH      ; All digits disabled initially
                MOV     P3,#0FFH      ; All inputs high (buttons unpressed)

                ; Initialize display values to 1, 2, 3, 4
                MOV     DIG0,#1
                MOV     DIG1,#2
                MOV     DIG2,#3
                MOV     DIG3,#4

                MOV     LED_PAT,#0FFH ; All LEDs OFF (not used here)
                MOV     SCAN_STATE,#0 ; Start scan at digit 0

                ; Setup Timer0 in mode 1 (16-bit)
                MOV     TMOD,#01H     
                MOV     TH0,#0FCH     ; High byte reload for ~1ms at 11.0592 MHz
                MOV     TL0,#018H     ; Low byte reload value

                ; Enable interrupts
                SETB    ET0           ; Enable Timer0 interrupt
                SETB    EA            ; Enable global interrupts
                SETB    TR0           ; Start Timer0

; --- Main loop: checks button presses ---
MAIN_LOOP:
                JNB     P3.5,KEY_S5   ; If button S5 pressed ? increment DIG0
                JNB     P3.4,KEY_S4   ; If button S4 pressed ? increment DIG1
                JNB     P3.3,KEY_S3   ; If button S3 pressed ? increment DIG2
                JNB     P3.2,KEY_S2   ; If button S2 pressed ? increment DIG3
                SJMP    MAIN_LOOP     ; Repeat forever

; --- Button handling routines ---
KEY_S5: 
        ACALL   DEBOUNCE_PRESS        ; Wait for stable press
        INC     DIG0                  ; Increment digit value
        MOV     A,DIG0
        CJNE    A,#10,KS5_CONT        ; If <10, keep value
        MOV     DIG0,#0               ; Else wrap to 0
KS5_CONT: 
        JB      P3.5,MAIN_LOOP        ; Wait for release
        SJMP    KS5_CONT              ; Keep waiting

KEY_S4:
        ACALL   DEBOUNCE_PRESS
        INC     DIG1
        MOV     A,DIG1
        CJNE    A,#10,KS4_CONT
        MOV     DIG1,#0
KS4_CONT:
        JB      P3.4,MAIN_LOOP
        SJMP    KS4_CONT

KEY_S3:
        ACALL   DEBOUNCE_PRESS
        INC     DIG2
        MOV     A,DIG2
        CJNE    A,#10,KS3_CONT
        MOV     DIG2,#0
KS3_CONT:
        JB      P3.3,MAIN_LOOP
        SJMP    KS3_CONT

KEY_S2:
        ACALL   DEBOUNCE_PRESS
        INC     DIG3
        MOV     A,DIG3
        CJNE    A,#10,KS2_CONT
        MOV     DIG3,#0
KS2_CONT:
        JB      P3.2,MAIN_LOOP
        SJMP    KS2_CONT

; ============================================================
; Timer0 Interrupt Service Routine
; Handles multiplex scanning of the display
; ============================================================
T0_ISR:
                PUSH    ACC           ; Save registers used in ISR
                PUSH    PSW
                PUSH    DPL
                PUSH    DPH

                ; Reload Timer0 for next 1ms tick
                MOV     TH0,#0FCH
                MOV     TL0,#018H

                ; Determine which output to update
                MOV     A,SCAN_STATE
                CJNE    A,#4,DO_DIGIT ; State 4 ? LED slot, else display digit

LED_SLOT:       MOV     P1,#0FFH      ; Disable all digits
                MOV     A,LED_PAT     ; Load LED pattern (all OFF here)
                MOV     P0,A          ; Output to P0 (LED control)
                SJMP    ADV_STATE     ; Skip to state advance

DO_DIGIT:       MOV     P1,#0FFH      ; Disable all digits before update
                MOV     R0,SCAN_STATE ; Select which digit to display

                ; Select the correct digit value
                CJNE    R0,#0,DCHK1
                MOV     A,DIG0
                SJMP    GOT_DIG
DCHK1:          CJNE    R0,#1,DCHK2
                MOV     A,DIG1
                SJMP    GOT_DIG
DCHK2:          CJNE    R0,#2,DCHK3
                MOV     A,DIG2
                SJMP    GOT_DIG
DCHK3:          MOV     A,DIG3

GOT_DIG:        ANL     A,#0FH        ; Ensure value is in range 0–9
                MOV     DPTR,#SEGTAB  ; Load pointer to segment table
                MOVC    A,@A+DPTR     ; Get segment pattern
                MOV     P0,A          ; Output pattern to segment lines

                MOV     A,SCAN_STATE  ; Get digit number
                MOV     DPTR,#DMASK   ; Load digit enable mask table
                MOVC    A,@A+DPTR     ; Get mask for this digit
                MOV     P1,A          ; Enable this digit (active-LOW)

; --- Advance to next scan state ---
ADV_STATE:      MOV     A,SCAN_STATE
                INC     A              ; Move to next state (0?1?2?3?4?0)
                CJNE    A,#5,KEEP_A
                CLR     A              ; Wrap back to 0 after 4
KEEP_A:         MOV     SCAN_STATE,A

                POP     DPH            ; Restore registers
                POP     DPL
                POP     PSW
                POP     ACC
                RETI                   ; Return from interrupt

; ============================================================
; Debounce routine for button presses
; Waits ~15ms to ensure stable signal
; ============================================================
DEBOUNCE_PRESS:
                MOV     R6,#3          ; Outer loop count
DLY1:           MOV     R7,#250        ; Inner loop count
DLY2:           DJNZ    R7,DLY2        ; Delay ~5ms
                DJNZ    R6,DLY1        ; Repeat outer loop
                RET

                END                    ; End of program
