#ifndef _INSTR_H_
#define _INSTR_H_

#include "inttypes.h"

// Instruction decoder functions.

/* I-Type (Immediate) */
#define opcode(instr)			bits(instr, 31, 26)
#define rs(instr)			bits(instr, 25, 21)
#define rt(instr)			bits(instr, 20, 16)

#define sel(instr)			bits(instr, 2, 0)

//#define rd(instr)			bits(instr, 15, 11)
#define immediate(instr)		bits(instr, 15,  0)
// Some aliases for the above.
#define base(instr)			bits(instr, 25, 21)
#define offset(instr)			bits(instr, 15,  0)

/* J-Type (Jump) */
#define target(instr)			bits(instr, 25,  0)

/* R-Type (Register) */
#define rd(instr)			bits(instr, 15, 11)
#define shamt(instr)			bits(instr, 10,  6)
#define funct(instr)			bits(instr,  5,  0)

/* COP1 (Floating Point) */
#define fmt(instr) 			bits(instr, 25, 21)
#define ft(instr) 			bits(instr, 20, 16)
#define fs(instr) 			bits(instr, 15, 11)
#define fd(instr) 			bits(instr, 10,  6)
#define function(instr) 		bits(instr,  5,  0)
#define cond(instr) 			bits(instr,  3,  0)

/* COPz (Coprocessor) */
#define cofun(instr) 			bits(instr, 24,  0)

/* The (op) field */
#define        SPECIAL			000
#define        REGIMM			001
#define        J			002
#define        JAL			003
#define        BEQ			004
#define        BNE			005
#define        BLEZ			006
#define        BGTZ			007 
#define        ADDI			010
#define        ADDIU			011
#define        SLTI			012
#define        SLTIU			013
#define        ANDI			014
#define        ORI			015
#define        XORI			016
#define        LUI			017
#define        COP0			020
#define        COP1			021
#define        COP2			022
// reserved	= 023,
#define        BEQL 		 	024
#define        BNEL 		 	025
#define        BLEZL 		 	026
#define        BGTZL 		 	027

#define        DADDI		 	030
#define        DADDIU		 	031
#define        LDL			032
#define        LDR			033
#define		SPECIAL2		034
// reserved = 034,
// reserved	= 035,
// reserved = 036,
// reserved	= 037,

#define        LB			040
#define        LH			041
#define        LWL			042
#define        LW			043
#define        LBU			044
#define        LHU			045
#define        LWR			046
#define        LWU			047
#define        SB			050
#define        SH			051
#define        SWL			052
#define        SW			053
#define        SDL			054
#define        SDR			055
#define        SWR			056
#define        CACHE		 	057

#define        LL			060
#define        LWC1			061
#define        LWC2			062
#define 	PREF			063
// reserved	= 063,
#define        LLD			064
#define        LDC1			065
#define        LDC2			066
#define        LD			067

#define        SC			070
#define        SWC1		 	071
#define        SWC2		 	072
// reserved	= 073,
#define        SCD			074
#define        SDC1			075
#define        SDC2			076
#define        SD			077


/* The (function) field when (op == SPECIAL) */
#define        SLL		 	000
// reserved		= 001,		
#define        SRL		 	002
#define        SRA		 	003
#define        SLLV		 	004
// reserved		= 005,
#define        SRLV		 	006
#define        SRAV		 	007

#define	       JR			010	
#define        JALR		 	011
#define 	MOVZ			012
#define 	MOVN			013
// reserved		= 012,
// reserved		= 013,
#define        SYSCALL	 		014
#define        BREAK	 		015
// reserved		= 016,
#define        SYNC		 	017

#define        MFHI		 	020
#define        MTHI		 	021
#define        MFLO		 	022
#define        MTLO		 	023
#define        DSLLV	 		024
// reserved		= 025,
#define        DSRLV	 		026
#define        DSRAV	 		027

#define        MULT		 	030
#define        MULTU	 		031
#define        DIV		 	032
#define        DIVU		 	033
#define        DMULT	 		034
#define        DMULTU	 		035
#define        DDIV		 	036
#define        DDIVU	 		037

#define        ADD		 	040
#define        ADDU	 		041
#define        SUB		 	042
#define        SUBU		 	043
#define        AND		 	044
#define        OR		 	045
#define        XOR		 	046
#define        NOR		 	047

// reserved		= 050,
// reserved		= 051,
#define        SLT		 	052
#define        SLTU		 	053
#define        DADD	 		054
#define        DADDU	 		055
#define        DSUB		 	056
#define        DSUBU	 		057

#define        TGE		 	060
#define        TGEU		 	061
#define        TLT		 	062
#define        TLTU		 	063
#define        TEQ		 	064
// reserved		= 065,
#define        TNE		 	066
// reserved		= 067,

#define        DSLL		 	070
// reserved		= 071,
#define        DSRL		 	072
#define        DSRA		 	073
#define        DSLL32	 		074
// reserved		= 075,
#define        DSRL32	 		076
#define        DSRA32	 		077



/* The (rt) field when (op == REGIMM) */
#define        BLTZ	 	 	000
#define        BGEZ		 	001
#define        BLTZL	 		002
#define        BGEZL	 		003
// reserved	= 004,
// reserved	= 005,
// reserved	= 006,
// reserved	= 007,

#define        TGEI		 	010
#define        TGEIU	 		011
#define        TLTI		 	012
#define        TLTIU	 		013
#define        TEQI		 	014
// reserved	= 015,
#define        TNEI		 	016
// reserved	= 017,

#define        BLTZAL	 		020
#define        BGEZAL	 		021
#define        BLTZALL	 		022
#define        BGEZALL	 		023
// reserved	= 024,
// reserved	= 025,
// reserved	= 026,
// reserved	= 027,

// reserved	= 030,
// reserved	= 031,
// reserved	= 032,
// reserved	= 033,
// reserved	= 034,
// reserved	= 035,
// reserved	= 036,
// reserved	= 037



/* The (rs) field of COPz rs instructions */

#define        MFCz		 	000
#define        DMFCz	 		001
#define        CFCz		 	002
// reserved	= 003,
#define        MTCz		 	004
#define        DMTCz	 		005
#define        CTCz		 	006
// reserved = 007,
#define        BCz		 	010


/* The (rt) field of COPz rt instructions */
#define        BCzF		 	000
#define        BCzT		 	001
#define        BCzFL	 		002
#define        BCzTL	 		003

/* CP0 (function) field */
#define        TLBR		 	001
#define        TLBWI	 		002
#define        TLBWR	 		006
#define        TLBP		 	010
#define	       RFE			020 //Shi yang 2006-08-08
#define	       ERET		 	030
#define	       WAIT		 	040

/* The (function) field */
#define		MADD			000
#define        FADD		 	000
#define        FSUB		 	001
#define        FMUL		 	002
#define        FDIV		 	003
#define        SQRT		 	004
#define        ABS		 	005
#define        MOV		 	006
#define        NEG		 	007

#define        ROUND_L	 		010
#define        TRUNC_L	 		011
#define        CEIL_L	 		012
#define        FLOOR_L	 		013
#define        ROUND_W 			014
#define        TRUNC_W	 		015
#define        CEIL_W 	 		016
#define        FLOOR_W	 		017

// reserved = 020,
// reserved = 021,
// reserved = 022,
// reserved = 023,
// reserved = 024,
// reserved = 025,
// reserved = 026,
// reserved = 027,

// reserved = 030,
// reserved = 031,
// reserved = 032,
// reserved = 033,
// reserved = 034,
// reserved = 035,
// reserved = 036,
// reserved = 037,

#define        CVT_S  	 		040
#define        CVT_D  	 		041
// reserved = 042,
// reserved = 043,
#define        CVT_W  	 		044
#define        CVT_L  	 		045
// reserved = 046,
// reserved = 047,

// reserved = 050,
// reserved = 051,
// reserved = 052,
// reserved = 053,
// reserved = 054,
// reserved = 055,
// reserved = 056,
// reserved = 057,

#define        C_F    	 		060
#define        C_UN   	 		061
#define        C_EQ   	 		062
#define        C_UEQ  	 		063
#define        C_OLT  	 		064
#define        C_ULT  	 		065
#define        C_OLE  	 		066
#define        C_ULE  	 		067

#define        C_SF   	 		070
#define        C_NGLE 	 		071
#define        C_SEQ  	 		072
#define        C_NGL  	 		073
#define        C_LT   	 		074
#define        C_NGE  	 		075
#define        C_LE   	 		076
#define        C_NGT  	 		077


/* The (mt) field */
// 0-15	  // Reserved
#define        S		 	16	  // IEEE 754 single-precision floating-point
#define        D 		 	17	  // IEEE 754 double-precision floating-point
// 18-19	  // Reserved
#define        W 		 	20	  // 32-bit binary fixed-point
#define        L 		 	21	  // 64-bit binary fixed-point
// 22-31	  // Reserved

/* The floating-point condition codes */
#define        unordered  	 	0
#define        equal      		1
#define        less       		2
#define        signalling 	 	3


#define 	CF		2	
#endif //end of _INSTR_H_

