;/**************************************************************************/
;/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
;/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
;/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
;/*  other machines not yet tested.                                        */
;/*                       fperrors.s                                       */
;/*  fudge the FPE status to get /0 errors properly                        */
;/**************************************************************************/

R0      RN      0
sp      RN      13
lk      RN      14
pc      RN      15


; Macro to provide labels in ASM code to suit C linker/debugger
        MACRO
$label  C_Label $string
        LCLA size
size SETA &FF000000 + (( (:LEN: "$string")  + 4 ) :AND: &FFFFFFFC)

$label DCB "$string",0
        ALIGN
        DCD  size
        MEND

;*****************************************************************

    AREA |C$$code|, CODE, READONLY

        EXPORT setFPStatus
        EXPORT readFPStatus

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
 
    AREA |C$$data|

|x$dataseg|

        END
