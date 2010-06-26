/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/


#include "coldfire.h"

/* Addressing Mode  Mode   Register
        Dy          000    memory_core.dnum
        Ay          001    memory_core.anum
       (Ay)         010    memory_core.anum
       (Ay)+        011    memory_core.anum
      -(Ay)         100    memory_core.anum
     (d16,Ay)       101    memory_core.anum
    (d8,Ay,Xi)      110    memory_core.anum
     (xxx).W        111    000
     (xxx).L        111    001
     #<data>        111    100
     (d16,PC)       111    010
    (d8,PC,Xi)      111    011
*/



/* FUNCTION: Retrives the value in memory based on the supplied Mode and
              Register
       ARGS: Size=8,16,32, we are careful with this because an 8 bit retrive for
                  a Dx, or Ax is the LSB, but for memory addressing, it is the 8
                  bits where the pointer is pointing to.
             Mode=the mode from the instruction
             Register=the register from the instruction
             EAValue=if true, we return the address.. not what is at the address... 
                     this means that we can't use Dx,Ay, and some others (because they
                     don't have an EA
     RETURNS: The value requested, or the EA if EAValue is turned on
    COMMENTS:  */
/* -------------------------------------*/








    
int Addressing_Print(short Size, char Mode, char Register, char *Str)
{
	unsigned int Result=0;
	short Scale;
	struct _InstructionExtensionWord *EWordPtr = (void *)&Result;

	switch(Mode) {
	case 0: /* Dy */
		sprintf(Str, "D%d", Register);
		break;
	case 1: /* Ay */
		sprintf(Str, "A%d", Register);
		break;
	case 2: /* (Ay) */
		sprintf(Str, "(A%d)", Register);
		break;
	case 3: /* (Ay)+ */
		sprintf(Str, "(A%d)+", Register);
		break;
	case 4: /* -(Ay) */
		sprintf(Str, "-(A%d)", Register);
		break;
	case 5: /* (d16,Ay) */
		Memory_RetrWordFromPC(&Result);
		sprintf(Str, "%hd(A%d)",(short)Result,Register);
		break;
	case 6: /* (d8,Ax,Xi) */
		Memory_RetrWordFromPC(&Result);
		if(EWordPtr->Scale == 0) Scale=1;
		else if(EWordPtr->Scale == 1) Scale=2;
		else if(EWordPtr->Scale == 2) Scale=4;
		else Scale=1;
		sprintf(Str, "%d(A%d,%c%d.L*%d)",EWordPtr->Displacement, 
			Register, EWordPtr->AD ? 'A' : 'D', EWordPtr->Register, Scale);
		break;
	case 7: /* Direct modes */
		switch(Register) {
		case 0: /* word addressing */
			Memory_RetrWordFromPC(&Result);
			sprintf(Str, "(0x%04hX.W)", (short)Result);
			break;
		case 1: /* long addressing */
			Memory_RetrLongWordFromPC(&Result);
			sprintf(Str, "(0x%08lX.L)", Result);
			break;
		case 2: /* (d16,PC) */
			Memory_RetrWordFromPC(&Result);
			sprintf(Str, "%hd(PC)",(short)Result);
			break;
		case 3: /* (d8,PC,Xi) */
			Memory_RetrWordFromPC(&Result);
			if(EWordPtr->Scale == 0) Scale=1;
			else if(EWordPtr->Scale == 1) Scale=2;
			else if(EWordPtr->Scale == 2) Scale=4;
			else Scale=1;
			sprintf(Str, "%d(PC,%c%d.L*%d)",EWordPtr->Displacement, 
				EWordPtr->AD ? 'A' : 'D', EWordPtr->Register, Scale);
			break;
		case 4:

			if(Size==8) {
				Memory_RetrByteFromPC(&Result);
/*				if( (char)Result < 0)
					sprintf(Str, "#%d", (char)Result);
				else*/
					sprintf(Str, "#0x%02lX", Result);
			} else if(Size==16) {
				Memory_RetrWordFromPC(&Result);
/*				if( (short)Result < 0)
					sprintf(Str, "#%d", (short)Result);
				else if((short)Result == 0)
					sprintf(Str, "#0");
				else*/
					sprintf(Str, "#0x%04lX", Result);
			} else if(Size==32) {
				Memory_RetrLongWordFromPC(&Result);
/*				if( (int)Result < 0)
					sprintf(Str, "#%ld", (int)Result);
				else*/
					sprintf(Str, "#0x%08lX", Result);
			}
			break;
		default:
			sprintf(Str, "---");
			break;
		}
	}
	return 0;
}

/* This gets an address, and all useful information about an address from
 * the PC.  Once the address is retrieved, it can be used (multiple times)
 * to write to, read from, etc.  This allows us to only need to access the
 * PC once during instruction operand fetch.  So if the destionation is (say)
 * an immediate address, we already have it.. we don't need to do any PC 
 * magic to reset it, and re-read the address.  I don't know if this is 
 * actally how the Coldfire works (what happens if you write to the address
 * you're fetching from.. does the board re-fetch the operand, or just use
 * the value of the address it pulled the source from?) */

/* It also lets us do things like auto increment, and autodecrement.. and
 * stores the original address in a place where we can use it again */
char EA_GetFromPC(struct _Address *Addr, short Size, char Mode, char Register) 
{
	struct _InstructionExtensionWord *EWordPtr = (struct _InstructionExtensionWord *)&Addr->Data;
	short Scale;

	Addr->Mode=Mode;
	Addr->Register=Register;
	Addr->Data=0;	/* This is for storing operands that are in the instruction */
	Addr->Address = 0xdeadbeef;
	Addr->Size=Size;


#ifdef MEMORY_STATS
	/* FIXME: this could be moved to the EA_GetValue, GetEA, and PutValue functions,
	 * it might give a more accurate representation there (some instructions do a direct
	 * read from the PC if they know what they are reading, but usually they go through
	 * the EA_* routines), and would let things be split into reads/writes. */
	Stats_Build_EA(Register, Mode);
#endif /* MEMORY_STATS */

	switch(Mode) {
	case 0: /* Dy */
		return 1;
	case 1: /* Ay */
		return 1;
	case 2: /* (Ay) */
		Addr->Address = memory_core.a[(int)Register];
		return 1;
	case 3: /* (Ay)+ */
		Addr->Address = memory_core.a[(int)Register];
		memory_core.a[(int)Register]+=Size>>3;
		return 1;
	case 4: /* -(Ay) */
		memory_core.a[(int)Register]-=Size>>3;
		Addr->Address = memory_core.a[(int)Register];
		return 1;
	case 5:	/* (d16,Ay) */
		if(!Memory_RetrWordFromPC(&Addr->Data)) return 0;
		Addr->Address = memory_core.a[(int)Register]+(short)Addr->Data;
		return 1;
	case 6:	/* (d8,An,Xi) */
		if(!Memory_RetrWordFromPC(&Addr->Data)) return 0;
		if(EWordPtr->Scale == 0) Scale=1;
		else if(EWordPtr->Scale == 1) Scale=2;
		else if(EWordPtr->Scale == 2) Scale=4;
		else Scale=1;

			EWordPtr->Displacement, EWordPtr->AD ? "A" : "D", 
			EWordPtr->Register, EWordPtr->AD ? memory_core.a[EWordPtr->Register] : memory_core.d[EWordPtr->Register], 

		Addr->Address = memory_core.a[(int)Register] + EWordPtr->Displacement;
		/* EWordPtr->AD == 0 for memory_core.dister */
		if(EWordPtr->AD==0)
			Addr->Address += memory_core.d[(int)EWordPtr->Register] * Scale;	
		else 
			Addr->Address += memory_core.a[(int)EWordPtr->Register] * Scale;
		return 1;
			
	case 7: /* Direct modes */
		switch(Register) {
		case 0: /* word addressing */
			if(!Memory_RetrWordFromPC(&Addr->Data)) return 0;
			Addr->Address = Addr->Data;
			return 1;
		case 1: /* long addressing */
			if (!Memory_RetrLongWordFromPC(&Addr->Data)) return 0;
			Addr->Address = Addr->Data;
			return 1;
		case 2: /* (d16,PC) */
			/* This uses the value of the PC as the address of
				the extenstion word, we are already there */
			Addr->Address = memory_core.pc;
			/* Now alter the PC to get the extension word */
			if(!Memory_RetrWordFromPC(&Addr->Data)) return 0;
			Addr->Address += (short)Addr->Data;
			return 1;
		case 3: /* (d8,PC,Xi) */
			/* This uses the value of the PC as the address of
				the extenstion word, we are already there */
			Addr->Address = memory_core.pc;
			/* Now alter the PC to get the extension word */
			if(!Memory_RetrWordFromPC(&Addr->Data)) return 0;
			if(EWordPtr->Scale == 0) Scale=1;
			
			else if(EWordPtr->Scale == 1) Scale=2;
			else if(EWordPtr->Scale == 2) Scale=4;
			else Scale=1;

				EWordPtr->Displacement, EWordPtr->AD ? "A" : "D", 
				EWordPtr->Register, EWordPtr->AD ? memory_core.a[EWordPtr->Register] : memory_core.d[EWordPtr->Register], 

			Addr->Address += EWordPtr->Displacement;
			/* EWordPtr->AD == 0 for memory_core.dister */
			if(EWordPtr->AD==0)
				Addr->Address += memory_core.d[(int)EWordPtr->Register] * Scale;
			else 	
				Addr->Address += memory_core.a[(int)EWordPtr->Register] * Scale;
			return 1;

		case 4:
			if(!Memory_RetrFromPC(&Addr->Data, Size)) return 0;
			Addr->Address = 0xdeadbeef;
			if(Size==8) {
			} else if(Size==16) {
			} else {
			}
			return 1;
		}
		/* Should never get here */
		break;
	}
	return 0;
}


/* Takes an address, (that we build from EA_GetFromPC), and returns the 
 * value associated with it (with proper masking of bits)
 * This sign extends the return so it can be used directly for math ops
 * or for negative compares without worrying about actual size */
char EA_GetValue(unsigned int *Result, struct _Address *Addr)
{
	char ReturnValue = 1;
	switch(Addr->Mode) {
	case 0: /* Dy */
		*Result = memory_core.d[(int)Addr->Register];
		break;
	case 1: /* Ay */
		*Result = memory_core.a[(int)Addr->Register];
		break;
	case 2: /* (Ay) */
	case 3: /* (Ay)+ */
	case 4: /* -(Ay) */
	case 5:	/* (d16,Ay) */
	case 6:	/* (d8,An,Xi) */
		ReturnValue = Memory_Retr(Result, Addr->Size,Addr->Address);
		break;
			
	case 7: /* Direct modes */
		switch(Addr->Register) {
		case 0: /* word addressing */
		case 1: /* long addressing */
		case 2: /* (d16,PC) */
		case 3: /* (d8,PC,Xi) */
			ReturnValue = Memory_Retr(Result, Addr->Size,Addr->Address);
			break;
		case 4:
			*Result = Addr->Data;
			break;
		}
		break;
	}
	/* Now mask it through the size ..
             eg  & 0x000000FF for 8bit, etc. */
	if(Addr->Size & 0x0020) return 1;
	if(Addr->Size & 0x0010) *Result = (short)*Result;
	else			*Result = (char)*Result;
	return ReturnValue;
}

/* This is used by instructions that play with effective addresses (EAs)
 * instead of getting the value at an addrss, we get the actual address */
char EA_GetEA(unsigned int *Result, struct _Address *Addr)
{
	switch(Addr->Mode) {
	case 0: /* Dy */
	case 1: /* Ay */
	case 3: /* (Ay)+ */
	case 4: /* -(Ay) */
		//ERR("Can't get the EA of a register..\n");
		return 0;
	case 2: /* (Ay) */
	case 5:	/* (d16,Ay) */
	case 6:	/* (d8,An,Xi) */
		*Result = Addr->Address;
		break;
			
	case 7: /* Direct modes */
		switch(Addr->Register) {
		case 0: /* word addressing */
		case 1: /* long addressing */
		case 2: /* (d16,PC) */
		case 3: /* (d8,PC,Xi) */
			*Result = Addr->Address;
			break;
		case 4:
			return 0;
		}
		break;
	}
	return 1;
}

/* Given a value, and an address, this puts that value */
void EA_PutValue(struct _Address *Addr, unsigned int Value)
{
	/* Value is long, sign extended */
	
	switch(Addr->Mode) {
	case 0: /* Dy */
		/* Coldfire preserves the bits not written to when writing
		 *  to a D register */
		if(Addr->Size & 0x0020) {
			memory_core.d[(int)Addr->Register] = Value;
			return;
		} else if(Addr->Size & 0x0010) {
			memory_core.d[(int)Addr->Register] &= 0xFFFF0000;
			memory_core.d[(int)Addr->Register] |= Value & 0x0000FFFF;
			return;
		} else {
			memory_core.d[(int)Addr->Register] &= 0xFFFFFF00;
			memory_core.d[(int)Addr->Register] |= Value & 0x000000FF;
			return;
		}
		return;
	case 1: /* Ay */
		/* for both word and long writes to the A register, we 
		 * store the long sign extended value, but for byte writes, 
		 * we only overwrite the lowest byte. */
		if(Addr->Size & 0x0030) {
			memory_core.a[(int)Addr->Register] = Value;
			return;
/*		} else if(Addr->Size & 0x0010) {
			memory_core.a[(int)Addr->Register] &= 0xFFFF0000;
			memory_core.a[(int)Addr->Register] |= Value & 0x0000FFFF;
			return;*/
		} else {
			memory_core.a[(int)Addr->Register] &= 0xFFFFFF00;
			memory_core.a[(int)Addr->Register] |= Value & 0x000000FF;
			return;
		}
		
		return;
	case 2: /* (Ay) */
	case 3: /* (Ay)+ */
	case 4: /* -(Ay) */
	case 5:	/* (d16,Ay) */
	case 6:	/* (d8,An,Xi) */
		if(Addr->Size & 0x0020);
		else if(Addr->Size & 0x0010) 	Value = (unsigned short)Value;
		else				Value = (unsigned char)Value;
		Memory_Stor(Addr->Size,Addr->Address,Value);
		return;
			
	case 7: /* Direct modes */
		switch(Addr->Register) {
		case 0: /* word addressing */
		case 1: /* long addressing */
			if(Addr->Size & 0x0020);
			else if(Addr->Size & 0x0010) 	Value = (unsigned short)Value;
			else				Value = (unsigned char)Value;
			Memory_Stor(Addr->Size,Addr->Address,Value);
			return;
		case 2: /* (d16,PC) */
		case 3: /* (d8,PC,Xi) */
		case 4:
			//ERR("Can't write to the PC, go away.\n");
			return;
		}
		/* Shouldn't get here */
		break;
	}
}






void Stack_Push(short Size, unsigned int Value)
{
	struct _Address Dest;
	EA_GetFromPC(&Dest, Size, 4, 7);
	EA_PutValue(&Dest, Value);

}

unsigned int Stack_Pop(short Size)
{
	struct _Address Dest;
	unsigned int Value;
	EA_GetFromPC(&Dest, Size, 3, 7);
	EA_GetValue(&Value, &Dest);
	return Value;
}


