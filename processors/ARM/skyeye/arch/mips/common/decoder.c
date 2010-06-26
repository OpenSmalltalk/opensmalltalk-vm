#include "instr.h"
#include "emul.h"
#include <stdio.h>

/* Anthony Lee: 2006-09-18 */
#ifdef __MINGW32__
#define sync()	_flushall()
#else
#include <unistd.h> /* for sync() */
#endif

extern FILE *skyeye_logfd;
/* This monster of a switch statement decodes all CPU instructions. I've
 * decided against an explicit jump table, as such implementation both
 * increases the code size and introduced additional overhead to the inner
 * decoder loop.
 */

/*  WARNING: The below code currently does not simulate any slips.
 * This should be fixed soon (it's fairly easy to simulate, too.)
 */

const char* regname[32] = {
    "$0", "at", "v0", "v1", "a0", "a1", "a2", "a3",
    "t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
    "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7",
    "t8", "t9", "k0", "k1", "gp", "sp", "s8", "ra"
};

int 
decode(MIPS_State* mstate, Instr instr)
{
    	switch (opcode(instr)) {
    		case SPECIAL:
    		{
			/* Special instructions, decoded using the (function) field */
			switch (function(instr)) {
				case SLL:
				{
	    				// Shift Left Logical
	    				if (rd(instr)) {
						UInt32 x = mstate->gpr[rt(instr)];
						int s = shamt(instr);
						x <<= s;
						mstate->gpr[rd(instr)] = x;
					}
    					return nothing_special;
				}
				case SRL:
				{
	    				// Shift Right Logical
					UInt32 x = mstate->gpr[rt(instr)];
	    				int s = shamt(instr);
					x >>= s;
	   				mstate->gpr[rd(instr)] = x;
				  	return nothing_special;
				}
				case SRA:
				{
				    	// Shift Right Arithmetic
					UInt32 x = mstate->gpr[rt(instr)];
	    				int s = shamt(instr);
					x >>= s;
	    				mstate->gpr[rd(instr)] = sign_extend_UInt32(x, 32 - s);
		
	    				return nothing_special;
				}
				case SLLV:
				{
				    	UInt32 x = mstate->gpr[rt(instr)];
				    	int s = bits(mstate->gpr[rs(instr)], 4, 0);
					x <<= s;
					//mstate->gpr[rd(instr)] = sign_extend_UInt32(x, 32 - s);
					mstate->gpr[rd(instr)] = x;

					return nothing_special;
				}
				case SRLV:
				{
	    				// Shift Right Logical Variable
					UInt32 x = mstate->gpr[rt(instr)];
				        int s = bits(mstate->gpr[rs(instr)], 4, 0);
					x >>= s;
	   				//mstate->gpr[rd(instr)] = sign_extend_UInt32(x, 32 - s);
					mstate->gpr[rd(instr)] = x;
					return nothing_special;
				}
				case SRAV:
				{
					// Shift Right Arithmetic Variable 
					UInt32 x = mstate->gpr[rt(instr)];
				        int s = bits(mstate->gpr[rs(instr)], 4, 0);
					x >>= s;
				        mstate->gpr[rd(instr)] = sign_extend_UInt32(x, 32 - s);
					return nothing_special;

				}
				case MOVZ:
				{
					if(!mstate->gpr[rt(instr)])
                                        	mstate->gpr[rd(instr)] = mstate->gpr[rs(instr)];
                                        return nothing_special;

                                }
				case MOVN:
                                {
                                        if(mstate->gpr[rt(instr)])
                                                mstate->gpr[rd(instr)] = mstate->gpr[rs(instr)];
                                        return nothing_special;

                                }

				case JR:
				{
				    	// Jump Register
					mstate->branch_target = mstate->gpr[rs(instr)];
	    				if (mstate->pipeline == branch_delay)
						printf("Can't handle branch in branch delay slot\n");
	   
					return bits(mstate->branch_target, 1, 0) ? instr_addr_error : branch_delay;
				}
				case JALR:
				{
					// Jump And Link Register
					mstate->branch_target = mstate->gpr[rs(instr)];
					if(rd(instr) != 31)
						mstate->gpr[rd(instr)] = mstate->pc + 8;
					else
						mstate->gpr[31] = mstate->pc + 8;

	    				if (mstate->pipeline == branch_delay)
						printf("Can't handle branch in branch delay slot\n");
		
					return bits(mstate->branch_target, 1, 0) ? instr_addr_error : branch_delay;
				}
				case SYSCALL:
				{
				        // System Call
					process_syscall(mstate);
	
	    				return nothing_special;
				}
				case BREAK:
				{
					//process_breakpoint(mstate);
					fprintf(stderr,"workaround for break instruction, pc=0x%x\n ", mstate->pc);
				    	return nothing_special;
				}
				case SYNC:
				{
					// Synchronize
					//Fix me Shi yang 2006-08-08
					//process_reserved_instruction(mstate);
					return nothing_special;
				}
				case MFHI:
				{
				    	// Move From HI
	    				mstate->gpr[rd(instr)] = mstate->hi;
					return nothing_special;
				}
				case MTHI:
				{
					// Move To HI
				    	mstate->hi = mstate->gpr[rs(instr)];
					return nothing_special;
				}
				case MFLO:
				{
				    	// Move From LO
	    				mstate->gpr[rd(instr)] = mstate->lo;
		
				        return nothing_special;
				}
				case MTLO:
				{
	    				// Move To LO
		    			mstate->lo = mstate->gpr[rs(instr)];

				        return nothing_special;
				}
				case DSLLV:
				{
			    		// Doubleword Shift Left Logical Variable
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DSRLV:
				{
				    	// Doubleword Shift Right Logical Variable
					process_reserved_instruction(mstate);
					return nothing_special;
				}
	
				case DSRAV:
				{
		    			// Doubleword Shift Right Arithmetic Variable
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case MULT:
				{
			    		// Multiply
				        Int64 x = mstate->gpr[rs(instr)];
	    				Int64 y = mstate->gpr[rt(instr)];
	    				//multiply(x, y);
					long long z = x * y;
					mstate->hi = (z >> 32) & 0xFFFFFFFF;
                                        mstate->lo = z & 0xFFFFFFFF;

					return nothing_special;
				}
				case MULTU:
				{
	    				// Multiply Unsigned
				    	UInt64 x = mstate->gpr[rs(instr)];
		    			UInt64 y = mstate->gpr[rt(instr)];
					unsigned long long z = x * y;
	   	 			//multiply(x, y);
					mstate->hi = (z >> 32) & 0xFFFFFFFF;
				        mstate->lo = z & 0xFFFFFFFF;


				    	return nothing_special;
				}
				case DIV:
				{
	    				// Divide
					Int32 y = (Int32) mstate->gpr[rt(instr)];
					Int32 x = (Int32) mstate->gpr[rs(instr)];
					divide_Int32(x, y);
					
				    	return nothing_special;
				}

				case DIVU:
				{
				    	UInt32 y = (UInt32) mstate->gpr[rt(instr)];
					UInt32 x = (UInt32) mstate->gpr[rs(instr)];
					divide_UInt32(x, y);
				    	return nothing_special;
				}

				case DMULT:
				{
	    				// Doubleword Multiply
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DMULTU:
				{
	    				// Doubleword Multiply Unsigned
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DDIV:
				{
			   		 // Doubleword Divide
					process_reserved_instruction(mstate);
					return nothing_special;
				}

				case DDIVU:
				{
	    				// Doubleword Divide Unsigned
					process_reserved_instruction(mstate);
					return nothing_special;
				}

				case ADD:
	    			{
	    				// Add
	    				UInt32 x = mstate->gpr[rs(instr)];
	    				UInt32 y = mstate->gpr[rt(instr)];
	    				UInt32 z = x + y;
				    	// Overflow occurs is sign(x) == sign(y) != sign(z).
				    	if (bit(x ^ y, 31) == 0 && bit(x ^ z, 31) != 0)
						process_integer_overflow(mstate);
					mstate->gpr[rd(instr)] = z;
				    	return nothing_special;
				}
				case ADDU:
				{
	    				// Add Unsigned
					UInt32 x = mstate->gpr[rs(instr)];
				    	UInt32 y = mstate->gpr[rt(instr)];
					UInt32 z = x + y;
	    				mstate->gpr[rd(instr)] = z;
				    	return nothing_special;
				}
				case SUB:
				{
	    				// Subtract
					Int32 x = mstate->gpr[rs(instr)];
					Int32 y = mstate->gpr[rt(instr)];
	    				Int32 z = (UInt32)x - (UInt32)y;
				    	if ((y < 0 && z < x) || (y > 0 && z > x))
						process_integer_overflow();
				    	mstate->gpr[rd(instr)] = z;

					return nothing_special;
				}
				case SUBU:
				{
	    				// Subtract Unsigned
	    				UInt32 x = mstate->gpr[rs(instr)];
	    				UInt32 y = mstate->gpr[rt(instr)];
				    	mstate->gpr[rd(instr)] = x - y;

					return nothing_special;
				}
				case AND:
				{
	    				// And
					mstate->gpr[rd(instr)] = mstate->gpr[rs(instr)] & mstate->gpr[rt(instr)];
				    	return nothing_special;
				}
				case OR:
				{
				    	// Or
				    	mstate->gpr[rd(instr)] = mstate->gpr[rs(instr)] | mstate->gpr[rt(instr)];
				   	return nothing_special;
				}
				case XOR:
				{
			    		// Exclusive Or
				        mstate->gpr[rd(instr)] = mstate->gpr[rs(instr)] ^ mstate->gpr[rt(instr)];
				    	return nothing_special;
				}
				case NOR:
				{
	    				// Nor
				        mstate->gpr[rd(instr)] = ~((mstate->gpr[rs(instr)] | mstate->gpr[rt(instr)]));
	
				    	return nothing_special;
				}
				case SLT:
				{
	    				// Set On Less Than
				    	Int32 x = mstate->gpr[rs(instr)];
				    	Int32 y = mstate->gpr[rt(instr)];
				    	mstate->gpr[rd(instr)] = (x < y);
	
				    	return nothing_special;
				}
				case SLTU:
				{
				    	mstate->gpr[rd(instr)] = (mstate->gpr[rs(instr)] < mstate->gpr[rt(instr)]);

				    	return nothing_special;
				}
				case DADD:
				{
				    	// Doubleword Add	
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DADDU:
				{
	    				// Doubleword Add Unsigned
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DSUB:
				{
		    			// Doubleword Subtract
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DSUBU:
				{
	    				// Doubleword Subtract Unsigned
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case TGE:
				{
			    		// Trap If Greater Than Or Equal
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case TGEU:
				{
			    		// Trap If Greater Than Or Equal Unsigned
					process_reserved_instruction(mstate);
					return nothing_special;
				}

				case TLT:
				{
				    	// Trap If Less Than
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case TLTU:
				{
				    	// Trap If Less Than Unsigned
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case TEQ:
				{
				    	// Trap If Equal
					if( mstate->gpr[rs(instr)] == mstate->gpr[rt(instr)])
						fprintf(stderr,"trap happened in %s at 0x%x.\n", __FUNCTION__, mstate->pc);
					//process_reserved_instruction(mstate);
					return nothing_special;
				}
				case TNE:
				{
				    	// Trap If Not Equal
					if( mstate->gpr[rs(instr)] != mstate->gpr[rt(instr)])
						fprintf(stderr,"trap happened in %s at 0x%x.\n", __FUNCTION__, mstate->pc);
					//process_reserved_instruction(mstate);
					//skyeye_exit(-1);
					
					return nothing_special;
				}
				case DSLL:
				{
				    	// Doubleword Shift Left Logical
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DSRL:
				{
				    	// Doubleword Shift Right Logical
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DSRA:
				{
			    		// Doubleword Shift Right Arithmetic
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DSLL32:
				{
			    		// Doubleword Shift Left Logical + 32
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DSRL32:
				{
				    	// Doubleword Shift Right Logical + 32 
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				case DSRA32:
				{
			    		// Doubleword Shift Right Arithmetic + 32
					process_reserved_instruction(mstate);
					return nothing_special;
				}
				default:
			    		// Reserved instruction
					process_reserved_instruction(mstate);
				    	return nothing_special;
			}// switch (function(instr)) {
		}//case SPECIAL:
    	
		case REGIMM:
    		{
			switch (rt(instr)) {
				case BLTZ:
				{
	   			 	// Branch On Less Than Zero
				    	Int32 x = mstate->gpr[rs(instr)];
	    				if (x < 0) {
						VA off = sign_extend_UInt32(offset(instr), 16);
						mstate->branch_target = mstate->pc + 4 + (off << 2);
	    				} else {
						mstate->branch_target = mstate->pc + 8;
	    				}
			    		if (mstate->pipeline == branch_delay) {
						printf("Can't handle branch in branch delay slot\n");
					}
				    	return branch_delay;
				}
				case BGEZ:
				{
				    	// Branch On greater Than Zero
				    	Int32 x = mstate->gpr[rs(instr)];
				    	if (x >= 0) {
						VA off = sign_extend_UInt32(offset(instr), 16);
						mstate->branch_target = mstate->pc + 4 + (off << 2);
	    				} else {
						mstate->branch_target = mstate->pc + 8;
	    				}
			    		if (mstate->pipeline == branch_delay) {
						printf("Can't handle branch in branch delay slot\n");
					}
				    	return branch_delay;
				}
				case BLTZL:
				{
					  // Branch On Not Equal Likely
	        	                /*handle the opcode: BNEL, BNEZL*/
        	        	        Int32   x = mstate->gpr[rt(instr)];
		                        Int32   y = mstate->gpr[rs(instr)];
        		                //printf("In BLTZL,y=0x%x,pc=0x%x\n", y, mstate->pc);
                		        if(y < 0)
                        		{
	                        	    VA off = sign_extend_UInt32(offset(instr), 16);
	        	                    mstate->branch_target = mstate->pc + 4 + (off << 2);
        	        	        }
                	        	else/*if condition not match, we do not execute the insn in branch slot */
	                	        {
        	                	      mstate->branch_target = mstate->pc + 8;
                	                	mstate->pipeline = branch_delay;
	                        	    return nothing_special;
		                        }

        		                if (mstate->pipeline == branch_delay)
                		        {
                        		    printf("Can't handle branch in branch delay slot\n");
	                        	}

        	               		 return branch_delay;

					//process_reserved_instruction(mstate);
			    		// Branch On Less Than Zero Likely
					return nothing_special;
				}
				case BGEZL:
				{
					  // Branch On Not Equal Likely
	        	                /*handle the opcode: BNEL, BNEZL*/
        	        	        Int32   x = mstate->gpr[rt(instr)];
		                        Int32   y = mstate->gpr[rs(instr)];
        		                //printf("In BGEZL,y=0x%x,pc=0x%x\n", y, mstate->pc);
                		        if(y >= 0)
                        		{
	                        	    VA off = sign_extend_UInt32(offset(instr), 16);
	        	                    mstate->branch_target = mstate->pc + 4 + (off << 2);
        	        	        }
                	        	else/*if condition not match, we do not execute the insn in branch slot */
	                	        {
        	                	      mstate->branch_target = mstate->pc + 8;
                	                	mstate->pipeline = branch_delay;
	                        	    return nothing_special;
		                        }

        		                if (mstate->pipeline == branch_delay)
                		        {
                        		    printf("Can't handle branch in branch delay slot\n");
	                        	}

        	               		 return branch_delay;

					process_reserved_instruction(mstate);
				    	// Branch On Greater Than Or Equal To Zero Likely
					return nothing_special;
				}
				case TGEI:
				{
					process_reserved_instruction(mstate);
				    	// Trap If Greater Than Or Equal Immediate
					return nothing_special;
				}
				case TGEIU:
				{
					process_reserved_instruction(mstate);
			    		// Trap If Greater Than Or Equal Immediate Unsigned
				    	return nothing_special;
				}
				case TLTI:
				{
					process_reserved_instruction(mstate);
			    		// Trap If Less Than Immediate
				    	return nothing_special;
				}
				case TLTIU:
				{
					process_reserved_instruction(mstate);
			    		// Trap If Less Than Immediate Unsigned
				    	return nothing_special;
				}
				case TEQI:
				{
					process_reserved_instruction(mstate);
			    		// Trap If Equal Immediate
				    	return nothing_special;
				}
				case TNEI:
				{
					process_reserved_instruction(mstate);
			    		// Trap If Not Equal Immediate
				    	return nothing_special;
				}
				case BLTZAL:
				{
				    	// Branch On Less Than Zero And Link
				    	Int32 x = mstate->gpr[rs(instr)];
				    	mstate->gpr[31] = mstate->pc + 8;
				    	if (x < 0) {
						VA off = sign_extend_UInt32(offset(instr), 16);
						mstate->branch_target = mstate->pc + 4 + (off << 2);
	    				} else {
				    		mstate->branch_target = mstate->pc + 8;
	    				}
	    				if (mstate->pipeline == branch_delay) {
						printf("Can't handle branch in branch delay slot\n");
					}
				    	return branch_delay;
				}
				case BGEZAL:
				{
				    	// Branch On Greater Than Or Equal To Zero And Link
				    	Int32 x = mstate->gpr[rs(instr)];
				    	mstate->gpr[31] = mstate->pc + 8;
				    	if (x >= 0) {
						VA off = sign_extend_UInt32(offset(instr), 16);
						mstate->branch_target = mstate->pc + 4 + (off << 2);
					} else {
						mstate->branch_target = mstate->pc + 8;
	    				}		
				    	if (mstate->pipeline == branch_delay) {
						printf("Can't handle branch in branch delay slot\n");
					}
				    	return branch_delay;
				}
				case BLTZALL:
				{
					process_reserved_instruction(mstate);
			    		// Branch On Less Than Zero And Link Likely
					return nothing_special;
				}
				case BGEZALL:
				{
					process_reserved_instruction(mstate);
			    		// Branch On Greater Than Or Equal To Zero And Link Likely
					return nothing_special;
				}
				default:
				    	process_reserved_instruction(mstate);
				    	return nothing_special; //Fix me. Shi yang 2006-08-09
			}
    		}//case REGIMM:
    		case J:
    		{
			// Jump
			VA msb = clear_bits(mstate->pc + 4, 27, 0);
			mstate->branch_target = msb | (target(instr) << 2);
			if (mstate->pipeline == branch_delay) {
				printf("Can't handle branch in branch delay slot");
			}
			return branch_delay;
    		}
		case JAL:
    		{
			// Jump And Link
			mstate->gpr[31] = mstate->pc + 8;
			VA msb = clear_bits(mstate->pc + 4, 27, 0);
			mstate->branch_target = msb | (target(instr) << 2);
			if (mstate->pipeline == branch_delay) {
				printf("Can't handle branch in branch delay slot");
			}
			return branch_delay;
    		}
    		case BEQ:
    		{
			// Branch On Equal
			if (mstate->gpr[rs(instr)] == mstate->gpr[rt(instr)]) {
				VA off = sign_extend_UInt32(offset(instr), 16);
			    	mstate->branch_target = mstate->pc + 4 + (off << 2);
			} else {
			    	mstate->branch_target = mstate->pc + 8;
			}
			if (mstate->pipeline == branch_delay) {
				printf("Can't handle branch in branch delay slot");
			}

			return branch_delay;
    		}
    		case BNE:
    		{
			// Branch On Not Equal
			if (mstate->gpr[rs(instr)] != mstate->gpr[rt(instr)]) {
				VA off = sign_extend_UInt32(offset(instr), 16);
	   			 mstate->branch_target = mstate->pc + 4 + (off << 2);
			} else {
			    	mstate->branch_target = mstate->pc + 8;
			}
			if (mstate->pipeline == branch_delay) {
				printf("Can't handle branch in branch delay slot");
			}
	
			return branch_delay;
    		}
    		case BLEZ:
    		{
			// Branch On Less Than Or Equal To Zero
			Int32 x = mstate->gpr[rs(instr)];
			if (x <= 0) {
			    	VA off = sign_extend_UInt32(offset(instr), 16);
			    	mstate->branch_target = mstate->pc + 4 + (off << 2);
			} else {
				mstate->branch_target = mstate->pc + 8;
			}
			if (mstate->pipeline == branch_delay) {
				printf("Can't handle branch in branch delay slot");
			}

			return branch_delay;
    		}
		case BGTZ:
    		{
			// Branch On Greater Than Zero
			Int32 x = mstate->gpr[rs(instr)];
			if (x > 0) {
			    	VA off = sign_extend_UInt32(offset(instr), 16);
			    	mstate->branch_target = mstate->pc + 4 + (off << 2);
			} else {
			    	mstate->branch_target = mstate->pc + 8;
			}
			if (mstate->pipeline == branch_delay) {
				printf("Can't handle branch in branch delay slot");
			}

			return branch_delay;
    		}
    		case ADDI:
    		{
			// Add Immediate
			UInt32 x = mstate->gpr[rs(instr)];
			UInt32 y = sign_extend_UInt32(immediate(instr), 16);
			UInt32 z = x + y;
			// Overflow occurs is sign(x) == sign(y) != sign(z).
			if (bit(x ^ y, 31) == 0 && bit(x ^ z, 31) != 0)
			    	process_integer_overflow(mstate);
			mstate->gpr[rt(instr)] = z;
			return nothing_special;
    		}
		case ADDIU:
    		{
			/* confused, signed or unsigned ?? */
			// Add Immediate Unsigned
			UInt32 x = mstate->gpr[rs(instr)];
			Int32 y = sign_extend_UInt32(immediate(instr), 16);
			UInt32 z = x + y;
			//fprintf(skyeye_logfd, "0x%d,0x%d,0x%d, in 0x%x\n", x ,y, z, mstate->pc);
			mstate->gpr[rt(instr)] = z;
		
			return nothing_special;
    		}
		case SLTI:
    		{
			// Set On Less Than Immediate
			Int32 x = mstate->gpr[rs(instr)];
			Int32 y = sign_extend_UInt32(immediate(instr), 16);
			mstate->gpr[rt(instr)] = (x < y);
	
			return nothing_special;
    		}
	    	case SLTIU:
    		{
			// Set On Less Than Immediate Unsigned
			UInt32 x = mstate->gpr[rs(instr)];
			UInt32 y = sign_extend_UInt32(immediate(instr), 16);
			mstate->gpr[rt(instr)] = (x < y);

			return nothing_special;
    		}
	    	case ANDI:
    		{
			// And Immediate
			UInt16 x = mstate->gpr[rs(instr)];
			UInt16 imm = zero_extend(immediate(instr), 16);
			mstate->gpr[rt(instr)] = x & imm; //Shi yang 2006-08-31
			return nothing_special;
    		}
	    	case ORI:
    		{
			// Or Immediate
			UInt32 x = mstate->gpr[rs(instr)]; //Shi yang 2006-08-09
			UInt16 imm = immediate(instr);
			mstate->gpr[rt(instr)] = x | imm;

			return nothing_special;
    		}
	    	case XORI:
    		{
			// Exclusive Or Immediate
			UInt32 x = mstate->gpr[rs(instr)];
			UInt32 imm = immediate(instr);
			mstate->gpr[rt(instr)] = x ^ imm;

			return nothing_special;
    		}
    		case LUI:
    		{
			// Load Upper Immediate
			UInt32 imm = immediate(instr);
			imm <<= 16;
			mstate->gpr[rt(instr)] = imm;

			return nothing_special;
    		}
	    	case COP0:
    		{
			// Coprocessor 0 Operation
			return decode_cop0(mstate, instr);
    		}
	    	case COP1:
    		{
			return decode_cop1(mstate, instr);
			// Coprocessor 1 Operation
			//process_reserved_instruction(mstate);
    		}
		case COP2:
    		{
			// Coprocessor 2 Operation
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
		case PREF:
		{
			static int print_once = 1;
			if(print_once)
				printf("Warning,PREF instruction not implemented,only print once, pc=0x%x\n",mstate->pc);
			print_once = 0;
			return nothing_special;
		}
	    	case BEQL:
    		{
			// Branch On Equal Likely
			//process_reserved_instruction(mstate);
			//return nothing_special;
			Int32   x = mstate->gpr[rt(instr)];
                        Int32   y = mstate->gpr[rs(instr)];
			#if 0
                        if(y == 0)
                        {
                            printf("beqzl \n");
                            /*BEQZL*/
			    VA off = sign_extend_UInt32(offset(instr), 16);
      			    mstate->branch_target = mstate->pc + 4 + (off << 2);
                        }
                        else 
			#endif
			if(y == x)
                        {
                            /*BEQL*/
                            //printf("beql,pc=0x%x \n", mstate->pc);
			    VA off = sign_extend_UInt32(offset(instr), 16);
			    mstate->branch_target = mstate->pc + 4 + (off << 2);
			    //printf("branch_target=0x%x\n", mstate->branch_target);
                        }
			else
			{
			    mstate->branch_target = mstate->pc + 8;
			    mstate->pipeline = branch_delay;	
			    return nothing_special;
			}
			
			if (mstate->pipeline == branch_delay) 
			{
			    printf("Can't handle branch in branch delay slot\n");
			}

			return branch_delay;
    		}
    		case BNEL:
    		{
			// Branch On Not Equal Likely
			//process_reserved_instruction(mstate);
			//return nothing_special;
                        /*handle the opcode: BNEL, BNEZL*/
                        Int32   x = mstate->gpr[rt(instr)];
                        Int32   y = mstate->gpr[rs(instr)];
			#if 0
                        if(y != 0)
                        {
                            printf("bnezl \n");
                            /*BNEZL*/
			    VA off = sign_extend_UInt32(offset(instr), 16);
      			    mstate->branch_target = mstate->pc + 4 + (off << 2);
                        }
                        else 
			#endif
			if(y != x)
                        {
                            /*BNEL*/
                            //printf("bnel \n");
			    VA off = sign_extend_UInt32(offset(instr), 16);
			    mstate->branch_target = mstate->pc + 4 + (off << 2);
                        }
			else
			{
			    mstate->branch_target = mstate->pc + 8;
			mstate->pipeline = branch_delay;
                            return nothing_special;

			}
			
			if (mstate->pipeline == branch_delay) 
			{
			    printf("Can't handle branch in branch delay slot\n");
			}

			return branch_delay;
    		}
    		case BLEZL:
    		{
			// Branch On Not Equal Likely
                        /*handle the opcode: BNEL, BNEZL*/
                        Int32   x = mstate->gpr[rt(instr)];
                        Int32   y = mstate->gpr[rs(instr)];
			//printf("In BLEZL,y=0x%x,pc=0x%x\n", y, mstate->pc);
			if(y <= 0)
                        {
			    VA off = sign_extend_UInt32(offset(instr), 16);
			    mstate->branch_target = mstate->pc + 4 + (off << 2);
                        }
			else/*if condition not match, we do not execute the insn in branch slot */
			{
			      mstate->branch_target = mstate->pc + 8;
				mstate->pipeline = branch_delay;
                            return nothing_special;
			}
			
			if (mstate->pipeline == branch_delay) 
			{
			    printf("Can't handle branch in branch delay slot\n");
			}

			return branch_delay;

			/*
			process_reserved_instruction(mstate);
			return nothing_special;
			*/
    		}
    		case BGTZL:
    		{
			// Branch On Not Equal Likely
                        /*handle the opcode: BNEL, BNEZL*/
                        Int32   x = mstate->gpr[rt(instr)];
                        Int32   y = mstate->gpr[rs(instr)];
			//printf("In BGTZL,y=0x%x,pc=0x%x\n", y, mstate->pc);
			if(y > 0)
                        {
			    VA off = sign_extend_UInt32(offset(instr), 16);
			    mstate->branch_target = mstate->pc + 4 + (off << 2);
                        }
			else/*if condition not match, we do not execute the insn in branch slot */
			{
			      mstate->branch_target = mstate->pc + 8;
				mstate->pipeline = branch_delay;
                            return nothing_special;
			}
			
			if (mstate->pipeline == branch_delay) 
			{
			    printf("Can't handle branch in branch delay slot\n");
			}

			return branch_delay;
    		}
    		case DADDI:
    		{
			// Doubleword Add Immediate
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
	    	case DADDIU:
    		{
			// Doubleword Add Immediate Unsigned
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case LDL:
    		{
			// Load Doubleword Left
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case LDR:
    		{
			// Load Doubleword Right
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
		case SPECIAL2:
		{
			
                        switch (function(instr)) {
				case MADD:
				{
					UInt64 temp1 = mstate->hi << 32 + mstate->lo;
					UInt64 temp2 = mstate->gpr[rs(instr)] * mstate->gpr[rt(instr)] + temp1;
					mstate->hi = (temp2 >> 32) & (~0x0);
					mstate->lo = temp2 & (~0x0);
					return nothing_special;
				}	
                                case FMUL:
                                {
                                        mstate->gpr[rd(instr)] = mstate->gpr[rs(instr)] * mstate->gpr[rt(instr)];
                                        return nothing_special;
                                }
				case CVT_S://CLZ:
				{
					int i = 31;
					for(i; i >= 0;i--)
						if( mstate->gpr[rs(instr)] & (1 << i))
							break;
						else
							continue;
					 mstate->gpr[rd(instr)] = 31 - i;
                                        return nothing_special;
				}
				default:
		                        // Load Doubleword Right
                		        process_reserved_instruction(mstate);
		                        return nothing_special;
			}
                }

	
		case LB:
    		{
			// Load Byte
			UInt32 x; 
			UInt32 y = 0;

			if (mstate->sync_bit)
			    	sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			PA pa;
			if(translate_vaddr(mstate, va, data_load, &pa) != TLB_SUCC)
				return nothing_special;
			/*
			if(translate_vaddr(mstate, va, data_load, &pa) != TLB_SUCC){
					return nothing_special;
			}*/
			load(mstate, va, pa, &y, 1);
			
			x = sign_extend_UInt32(y & (0xff), 8); //Shi yang 2006-08-10, Sign extend

			mstate->gpr[rt(instr)] = x;

			return nothing_special;
    		}
    		case LH:
    		{
			// Load Halfword
			if (mstate->sync_bit)
				sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];

			if (bit(va, 0)) //Check alignment
				process_address_error(data_load, va);
			PA pa;
			if(translate_vaddr(mstate,va, data_load, &pa) != TLB_SUCC)
				return nothing_special; //Shi yang 2006-08-10
			UInt32 x; 
			UInt32 y = 0;
			load(mstate, va, pa, &y, 2);
			x = sign_extend_UInt32(y & (0xffff), 16); //Shi yang 2006-08-10, Sign extend

			mstate->gpr[rt(instr)] = x;
			return nothing_special;
    		}
    		case LWL:
    		{
			// Load Word Left
			if (mstate->sync_bit)
				sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			PA pa;
			if(translate_vaddr(mstate, va, data_load, &pa) != TLB_SUCC)
				return nothing_special; //Shi yang 2006-08-10
			UInt32 mem;
			UInt32 y = 0;
			load(mstate, round_down(va, 4), round_down(pa, 4), &y, 4);
			mem = y & (0xffffffff);

			UInt32 reg = mstate->gpr[rt(instr)];

			int syscmd = bits(va, 1, 0);
			if (!big_endian_cpu(mstate))
			    	syscmd ^= bitsmask(1, 0);

			reg = copy_bits(reg, mem, 31, syscmd * 8);
			mstate->gpr[rt(instr)] = reg;

			return nothing_special;
    		}
    		case LW:
    		{
			// Load Word
			if (mstate->sync_bit)
  			    	sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			if (va & 0x3) //Check alignment
				process_address_error(mstate,data_load, va);
			PA pa;
			if(translate_vaddr(mstate, va, data_load, &pa) != TLB_SUCC)
				return nothing_special; //Shi yang 2006-08-10
			UInt32 x;
			UInt32 y = 0;
			load(mstate, va, pa, &y, 4);

			mstate->gpr[rt(instr)] = y;
			return nothing_special;
    		}
		case LBU:
    		{
			// Load Byte Unsigned
			if (mstate->sync_bit)
			    	sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			PA pa;
			if(translate_vaddr(mstate, va, data_load, &pa) != TLB_SUCC)
				return nothing_special; //Shi yang 2006-08-10
			UInt32 y = 0;
			UInt32 x;
			load(mstate, va, pa, &y, 1);
			x = y & 0xffL; //Shi yang 2006-08-25
			mstate->gpr[rt(instr)] = x;

			return nothing_special;
    		}
		case LHU:
    		{
			// Load Halfword Unsigned
			if (mstate->sync_bit)
			    	sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			if (bit(va, 0)) //Check alignment
		    		process_address_error(mstate,data_load, va);
			PA pa;
			if(translate_vaddr(mstate, va, data_load, &pa) != TLB_SUCC)
				return nothing_special; //Shi yang 2006-08-10
			UInt16 x;
			UInt32 y = 0;
			load(mstate, va, pa, &y, 2);
			x = y & 0xffffL; //Shi yang 2006-08-25

			mstate->gpr[rt(instr)] = x;
			return nothing_special;
    		}
		case LWR:
    		{
			// Load Word Right
			if (mstate->sync_bit)
			    	sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			PA pa;
			if(translate_vaddr(mstate,va, data_load, &pa))
				return nothing_special; //Shi yang 2006-08-10
			UInt32 mem;
			UInt32 y = 0;
			load(mstate, round_down(va, 4), round_down(pa, 4), &y, 4);
			mem = y & (0xffffffff);

			UInt32 reg = mstate->gpr[rt(instr)];
			int syscmd = bits(va, 1, 0);
			if (big_endian_cpu(mstate))
			    	syscmd ^= bitsmask(1, 0);
			reg = copy_bits(reg, bits(mem, 31, syscmd * 8), 31 - syscmd * 8, 0);
			mstate->gpr[rt(instr)] = reg;
			return nothing_special;
    		}
		case LWU:
		{
			// Load Word Unsigned
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case SB:
    		{
			// Store Byte
			if (mstate->sync_bit)
	    			sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			PA pa;
			if(translate_vaddr(mstate,va, data_store, &pa))
				return nothing_special; //Shi yang 2006-08-10
			store(mstate, mstate->gpr[rt(instr)], va, pa, 1); // Fix me: Shi yang 2006-08-10
			return nothing_special;
    		}
	    	case SH:
    		{
			// Store Halfword
			if (mstate->sync_bit)
			    	sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			if (bit(va, 0)) //Check alignment
			    	process_address_error(mstate,data_store, va);
			PA pa;
			if(translate_vaddr(mstate, va, data_store, &pa))
				return nothing_special; //Shi yang 2006-08-10
			store(mstate, mstate->gpr[rt(instr)], va, pa, 2); //Fix me: Shi yang 2006-08-10
			return nothing_special;
    		}
		case SWL:
    		{
			// Store Word Left
			if (mstate->sync_bit)
				sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			PA pa;
			if(translate_vaddr(mstate, va, data_store, &pa))
				return nothing_special; //Shi yang 2006-08-10
			UInt32 mem;
			UInt32 y = 0;
			load(mstate, round_down(va, 4), round_down(pa, 4), &y, 4);
			mem = y & (0xffffffff);
	
			UInt32 reg = mstate->gpr[rt(instr)];
			int syscmd = bits(va, 1, 0);
			if (!big_endian_cpu(mstate))
			    	syscmd ^= bitsmask(1, 0);
			mem = copy_bits(mem, bits(reg, 31, syscmd * 8), 31 - syscmd * 8, 0);
			store(mstate, mem, round_down(va, 4), round_down(pa, 4), 4); //Fix me: Shi yang 2006-08-10
			return nothing_special;
    		}
    		case SW:
    		{
			// Store Word
			if (mstate->sync_bit)
		    		sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			if (bits(va, 1, 0)) //Check alignment
			{
				fprintf(stderr," in %s,address unaligned va=0x%x,pc=0x%x\n", __FUNCTION__, va, mstate->pc);
				skyeye_exit(-1);
			    	process_address_error(mstate,data_store, va);
			}
			PA pa;
			if(translate_vaddr(mstate,va, data_store, &pa) != TLB_SUCC)
				return nothing_special; //Shi yang 2006-08-10
			store(mstate, mstate->gpr[rt(instr)], va, pa, 4); //Fix me: Shi yang 2006-08-10
			return nothing_special;
    		}
    		case SDL:
    		{
			// Store Doubleword Left
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case SDR:
    		{
			// Store Doubleword Right
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case SWR:
    		{
			// Store Word Right
			if (mstate->sync_bit)
			    	sync();
			VA va = sign_extend_UInt32(offset(instr), 16) + mstate->gpr[base(instr)];
			PA pa;
			if(translate_vaddr(mstate, va, data_store, &pa) != TLB_SUCC)
				return nothing_special; //Shi yang 2006-08-10
			UInt32 mem;
			UInt32 y = 0;
			load(mstate,round_down(va, 4), round_down(pa, 4),&y,4);
			mem = y & (0xffffffff);
	
			UInt32 reg = mstate->gpr[rt(instr)];
			int syscmd = bits(va, 1, 0);
			if (big_endian_cpu(mstate))
			    	syscmd ^= bitsmask(1, 0);
			mem = copy_bits(mem, reg, 31, syscmd * 8);
			store(mstate, mem, round_down(va, 4), round_down(pa, 4), 4); //Fix me: Shi yang 2006-08-10
			return nothing_special;
    		}
    		case CACHE: //Nedved's cache instruction. Shi yang 2006-08-24
    		{
			// Cache
			return nothing_special;
    		}
		case LL:
    		{
			// Load Linked
			//int va = mstate->gpr[base(instr)] + offset(instr);
			int va = mstate->gpr[base(instr)] + sign_extend_UInt32(offset(instr), 16);
			PA pa;
			if(translate_vaddr(mstate, va, data_load, &pa) != TLB_SUCC)
				return nothing_special;
			int data;
			mips_mem_read(pa, &data, 4);	
			mstate->gpr[rt(instr)] = data;
			//process_reserved_instruction(mstate);
			return nothing_special;
    		}
		case LWC1:
    		{
			// Load Word to Coprocessor 1
			return nothing_special; //Shi yang 2006-08-31
    		}
	    	case LWC2:
    		{
			// Load Word to Coprocessor 2
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
		case LLD:
    		{
			// Load Linked Doubleword
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case LDC1:
    		{
			// Load Doubleword To Coprocessor 1
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
	    	case LDC2:
    		{
			// Load Doubleword To Coprocessor 2
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case LD:
    		{
			// Load Doubleword
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case SC:
    		{
			// Store Conditional
                        //int va = mstate->gpr[base(instr)] + offset(instr);
			int va = mstate->gpr[base(instr)] + sign_extend_UInt32(offset(instr), 16);
                        PA pa;
			if(translate_vaddr(mstate, va, data_load, &pa) != TLB_SUCC)
				return nothing_special;
                        int data;
			data = mstate->gpr[rt(instr)];
			
			/*
			if(mstate->pc == 0x8012a858){
				fprintf(stderr, "In SC,data=0x%x,va=0x%x\n", data, va);
				if(va == 0x81179a00){
					fprintf(stderr, "Write to %d\n",va);
					skyeye_exit(-1);
				}
			}
			*/
                        mips_mem_write(pa, &data, 4);
                        mstate->gpr[rt(instr)] = 1;

			//process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case SWC1:
    		{
			// Store Word From Coprocessor 1
			return nothing_special; //Shi yang 2006-08-31
    		}
		case SWC2:
    		{
			// Store Word From Coprocessor 2
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case SCD:
    		{
			// Store Conditional
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case SDC1:
    		{
			// Store Doubleword From Coprocessor 1
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
	    	case SDC2:
    		{
			// Store Doubleword From Coprocessor 2
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		case SD:
    		{
			// Store Doubleword
			process_reserved_instruction(mstate);
			return nothing_special;
    		}
    		default:
			// Reserved instruction.
			process_reserved_instruction(mstate);
			return nothing_special;
    	}
}
