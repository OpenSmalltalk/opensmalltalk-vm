
R0      RN      0
sp      RN      13
lk      RN      14
pc      RN      15

XOS_ReadMonotonicTime *  &42 + (1 :SHL: 17)
ioc       * &3200000
ioc_ctrl  * &106
t0_low    * &40
t0_high   * &44
t0_go     * &48
t0_latch  * &4C



; Macro to provide labels in ASM code to suit C linker/debugger
        MACRO
$label  C_Label $string
        LCLA size
size SETA &FF000000 + (( (:LEN: "$string")  + 4 ) :AND: &FFFFFFFC)

$label DCB "$string"
        ALIGN
        DCD  size
        MEND

;*****************************************************************

    AREA |C$$code|, CODE, READONLY

        EXPORT setFPStatus
        EXPORT readFPStatus
;        EXPORT readCSecClock
;        EXPORT readMSecClock

;*****************************************************************

        C_Label "setFPStatus"

setFPStatus
        WFS R0
        MOV pc, lk

;*****************************************************************
        C_Label "readFPStatus"
readFPStatus
        RFS R0
        AND R0, R0, #&F
        MOV pc, lk

;*****************************************************************
; The following two functions were part of an experiment in making
; a faster  and higher resolution clock. It failed.
; Reading the timer0 would need to be in a module to work :-(
;        C_Label "readCSecClock"
;readCSecClock
;        ; return the centisecond clock value * 10, ie rough millisecs
;        STMFD sp!, {lr}
;        SWI XOS_ReadMonotonicTime
;        ADD R0,R0,R0                    ; double RO
;        ADD R0,R0,R0,LSL#2              ; then R0 = 2r0 + 2r0*4 -> 10r0
;        LDMFD sp!, {pc}
;
;*****************************************************************
;        C_Label "readMSecClock"
;readMSecClock
;        ; return the centisec * 10 + ~result of checking the timer0
;        ; gives reasonably accurate millisecs
;        STMFD sp!, {lr}        
;        MOV     R1,#ioc                 ; read IOC timer
;        STRB    R0,[R1,#t0_latch]       ; make value appear on latch
;        LDRB    R0,[R1,#t0_low]
;        LDRB    R1,[R1,#t0_high]
;        ADD     R0,R0,R1,LSL#8          ; add high and low
;        MOV     R1,#2048
;        SUB     R1,R1,#49               ; leaves 1999 in R1
;        SUB     R1,R1,R0                ; reverse countdown to count up
;        MOV     R1,R1,LSR#11            ; divide by 2048, close enough to 2000!
;        
;        SWI XOS_ReadMonotonicTime
;
;        ADD R0,R0,R0                    ; double RO
;        ADD R0,R0,R0,LSL#2              ; then R0 = 2r0 + 2r0*4 -> 10r0
;        ADD R0,R0,R1
;
;        LDMFD sp!, {pc}
;
;*****************************************************************
 
    AREA |C$$data|

|x$dataseg|

        END
