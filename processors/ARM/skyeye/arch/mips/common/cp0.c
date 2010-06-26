/*
        cp0.c - read/write for cp0 register 

        Copyright (C) 2003 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 2 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software
        Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/
/*
 * 12/21/2007   Michael.Kang  <blackfin.kang@gmail.com>
 */

#include "skyeye_config.h"
#include "instr.h"
#include "emul.h"
#include <stdio.h>

// Access to the System Coprocessor registers.

extern FILE *skyeye_logfd;
UInt32 
read_cp0(MIPS_State* mstate, int n, int sel) 
{
    	switch (n) {
		case Index:
                {
                        #if 0
                        mstate->cp0[Index] = clear_bits(x, 30, 17); //Shi yang 2006-08-11
                        mstate->cp0[Index] = clear_bits(x, 7, 0);
                        #endif
                        //printf("In %s, Index,x=0x%x\n", __FUNCTION__, mstate->cp0[Index]);
                        return mstate->cp0[Index];
                }

    		case Random:
    		{
			return get_random(mstate);
    		}
	    	case Count:
    		{
			return mstate->cp0[Count] + ((mstate->now - mstate->count_seed) / 2);
	    	}
    		case Cause:
    		{
			//printf("KSDBG:read cause=0x%x, pc=0x%x\n", mstate->cp0[Cause], mstate->pc);
			return mstate->cp0[Cause];
			//return mstate->cp0[Cause] | (mstate->events & bitsmask(Cause_IP_Last, Cause_IP_First));
    		}
		case EPC:
                {
                        //fprintf(stderr, "read EPC, EPC = 0x%x, pc=0x%x\n", mstate->cp0[EPC], mstate->pc);
                        return mstate->cp0[EPC];
                }
		case PRId:
		{
			return mstate->cp0[PRId]; /* the id of au1200 */
		}
		case Config:
		{
			if(sel) /* config1 */
				return mstate->cp0_config1; /* config1 for au1200 */
			else
				return mstate->cp0[Config]; /* config0 for au1200 */
		}
	    	default:
			return mstate->cp0[n];
    }
}


void 
write_cp0(MIPS_State* mstate, int n, UInt32 x)
{
    	switch (n) {
		case Index:
    		{
			#if 0
			mstate->cp0[Index] = clear_bits(x, 30, 17); //Shi yang 2006-08-11
			mstate->cp0[Index] = clear_bits(x, 7, 0);
			#endif
			mstate->cp0[Index] = x;
			//printf("In %s,Write Index,x=0x%x\n", __FUNCTION__, x);
			break;
    		}
	    	case Random: //Random register is a read-only register
    		{
			break;
    		}
	    	case EntryLo0:
    		{
			//mstate->cp0[EntryLo0] = clear_bits(x, 7, 0); //Shi yang 2006-08-11
			mstate->cp0[EntryLo0] = x;
			//printf("In %s,Write lo,x=0x%x,pc=0x%x\n", __FUNCTION__, x, mstate->pc);
			break;
    		}
		case EntryLo1:
    		{
			//mstate->cp0[EntryLo0] = clear_bits(x, 7, 0); //Shi yang 2006-08-11
			mstate->cp0[EntryLo1] = x;
			//printf("In %s,Write lo1,x=0x%x,pc=0x%x,\n", __FUNCTION__, x, mstate->pc);
			break;
    		}
	    	case Context:
    		{
			mstate->cp0[Context] = clear_bits(x, 1, 0); //Shi yang 2006-08-11
			break;
    		}
	    	case BadVAddr: //BadVAddr register is a read-only register
    		{
			break;
    		}
	    	case Count:
    		{
			mstate->count_seed = mstate->now;
			mstate->cp0[Count] = x;
			mstate->now = mstate->now + (mstate->cp0[Compare] - (mstate->cp0[Count] + ((mstate->now - mstate->count_seed) / 2))) * 2;
			break;
    		}
	    	case EntryHi:
    		{
			mstate->cp0[EntryHi] = x;
			break;
    		}
    		case Compare:
    		{
			//fprintf(stderr, "KSDBG: in %s,write 0x%x to compare\n", __FUNCTION__, x);
			mstate->cp0[Compare] = x;
			mstate->events = clear_bit(mstate->events, 7 + Cause_IP_First);
			mstate->now = mstate->now + (mstate->cp0[Compare] - (mstate->cp0[Count] + ((mstate->now - mstate->count_seed) / 2))) * 2;
			mstate->cp0[Cause] &= 0xFFFF7FFF; /* clear IP bit in cause register for timer */
			break;
    		}
	    	case SR:
    		{
			mstate->cp0[SR] = x & ~(bitsmask(27, 26) | bitsmask(24, 23) | bitsmask(7, 6)); //Shi yang 2006-08-11
			//leave_kernel_mode(mstate);
			break;
    		}
	    	case Cause:
    		{
			//fprintf(stderr, "write cause, cause = 0x%x,pc=0x%x\n", x, mstate->pc);
			mstate->events |= x & bitsmask(Cause_IP1, Cause_IP0);
			break;
    		}
	    	case EPC:
    		{
			//fprintf(stderr, "write EPC, EPC = 0x%x, pc=0x%x\n", x, mstate->pc);
			mstate->cp0[EPC] = x;
			break;
    		}
	    	case PRId: //PRId register is a read-only register
    		{
			break;
    		}
    		default:
			printf("Reg=0x%x, not implemented instruction in %s\n",n, __FUNCTION__);
			break;
    		}
}


int 
decode_cop0(MIPS_State* mstate, Instr instr)
{
	// CP0 is usable in kernel more or when the CU bit in SR is set.
    	if (!(mstate->mode & kmode) && !bit(mstate->cp0[SR], SR_CU0))
		process_coprocessor_unusable(mstate, 0);

    	/* Only COP0, MFC0 and MTC0 make sense, although the R3K
    	 * manuals say nothing about handling the others.
         */

    	if (bit(instr, 25)) {
		switch (funct(instr)) {
			case TLBR:
			{
			    	// Read Indexed TLB Entry
				TLBEntry* e = &mstate->tlb[bits(mstate->cp0[Index], 13, 6)]; //Shi yang 2006-08-11
			    	mstate->cp0[EntryHi] = e->hi ;
			    	mstate->cp0[EntryLo0] = e->lo_reg[0];
				mstate->cp0[EntryLo1] = e->lo_reg[1];
			    	return nothing_special;
			}
			case TLBWI:
			{
			    	// Write Indexed TLB Entry
				//printf("TLBWI,index=0x%x, pc=0x%x\n", mstate->cp0[Index], mstate->pc);
			    	set_tlb_entry(mstate, mstate->cp0[Index]); //Shi yang 2006-08-11
			    	return nothing_special;
			}
			case TLBWR:
			{
		    		// Write Random TLB Entry
				//printf("TLBWR,index=0x%x, pc=0x%x\n", get_random(mstate), mstate->pc);
			    	set_tlb_entry(mstate, get_random(mstate));
			    	return nothing_special;
			}
			case TLBP:
			{
		    		// Probe TLB For Matching Entry
			    	VA va = mstate->cp0[EntryHi];
				//printf("TLBP, va=0x%x\n", va);
		    		TLBEntry* e = probe_tlb(mstate, va);
				//printf("TLBP, index=0x%x\n", e->index);
			    	mstate->cp0[Index] = (e) ? e->index : bitmask(31);
			    	return nothing_special;
			}
			case RFE: //Shi yang 2006-08-11
			{
				printf("RFE, return from exp, pc=0x%x\n", mstate->pc);

				// Exception Return
				leave_kernel_mode(mstate);
				return nothing_special;
			}
			case ERET:
			{	
				/* enable interrupt */
				mstate->cp0[SR] |= 0x1;
				//fprintf(stderr, "ERET, return from exp, SR=0x%x, pc=0x%x,epc=0x%x\n", mstate->cp0[SR], mstate->pc, mstate->cp0[EPC]);
				mstate->pc =  mstate->cp0[EPC];
				//fprintf(stderr, "ERET, return from exp, epc=0x%x\n", mstate->cp0[EPC]);
				if(mstate->cp0[Cause] & 1 << Cause_IP2)
					skyeye_config.mach->mach_set_intr(0);/* clear the corresponding interrupt status register */
				/*
				if(mstate->cp0[Cause] & 1 << Cause_IP4)
					mstate->cp0[Cause] &= ~(1 << Cause_IP4);
				*/
				mstate->pipeline = branch_nodelay;
				return nothing_special;
			}
			default:
				process_reserved_instruction(mstate);
		    		return nothing_special;
		}
    	} else {
		switch (rs(instr)) {
			case MFCz:
			{
		    		// Move From System Control Coprocessor
				mstate->gpr[rt(instr)] = read_cp0(mstate, rd(instr), sel(instr));
			    	return nothing_special;
			}
			case DMFCz:
			{
		    		// Doubleword Move From System Control Coprocessor
				process_reserved_instruction(mstate);
				return nothing_special;
			}
			case CFCz:
			{
		    		// Move Control From Coprocessor
			    	return nothing_special;
			}
			case MTCz:
			{
		    		// Move To System Control Coprocessor
			    	write_cp0(mstate, rd(instr), mstate->gpr[rt(instr)]);
			    	return nothing_special;
			}
			case DMTCz:
			{
			    	// Doubleword Move To System Control Coprocessor
				process_reserved_instruction(mstate);
			    	return nothing_special;
			}
			case CTCz:
			{
				process_reserved_instruction(mstate);

		    		// Move Control To Coprocessor
			    	return nothing_special;
			}
			case BCz:
			{
			    	// Branch On Coprocessor Condition
	    			switch (rt(instr)) {
				    	case BCzF:
				    	case BCzT:
				    	case BCzFL:
				    	case BCzTL:
						process_reserved_instruction(mstate);
						return nothing_special;
	    				default:
						process_reserved_instruction(mstate);
						return nothing_special;
	    			}
			}
			default:
				    	process_reserved_instruction(mstate);
					return nothing_special;
		}
    	}
    	return nothing_special;
}
int 
decode_cop1(MIPS_State* mstate, Instr instr)
{
	// CP1 is usable in kernel more or when the CU bit in SR is set.
    	if (!bit(mstate->cp0[SR], SR_CU1)){
		process_coprocessor_unusable(mstate, 1);
		return nothing_special;
	}

    	/* Only COP0, MFC0 and MTC0 make sense, although the R3K
    	 * manuals say nothing about handling the others.
         */
	switch (function(instr)){
				case WAIT:
			return nothing_special;
		default:
			//process_reserved_instruction(mstate);
                        break;

	}
	switch (fmt(instr)){
		case CF:		
			if(fs(instr) == 0)
				mstate->gpr[ft(instr)] = mstate->fir;
			else
				fprintf(stderr, "In %s, not implement for CFC1 instruction\n", __FUNCTION__);
			break;
								
		default:
			//process_reserved_instruction(mstate);
			fprintf(stderr, "In %s,not implement instruction 0x%x,pc=0x%x\n", __FUNCTION__, instr, mstate->pc);

			break;
	}
	return nothing_special;
}

