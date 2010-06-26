/**********************************/
/*                                */
/*  Copyright 2000, David Grant   */
/*                                */
/*  see LICENSE for more details  */
/*                                */
/**********************************/


struct _Address {
	short Size;
	char Mode;
	char Register;
	unsigned int Address;
	unsigned int Data;
};


/*ng Addressing_Retr(short Size, char Mode, char Register, char EAValue);
void Addressing_Stor(short Size, char Mode, char Register, long Value);*/
int Addressing_Print(short Size, char Mode, char Register, char *Str);

char EA_GetFromPC(struct _Address *Addr, short Size, char Mode, char Register);
char EA_GetValue(unsigned int *Result,  struct _Address *Addr);
char EA_GetEA(unsigned int *Result, struct _Address *Addr);
/*long EA_GetAddress(struct _Address *Addr);*/
void EA_PutValue(struct _Address *Addr, unsigned int Value);

void Stack_Push(short Size, unsigned int Value);
unsigned int Stack_Pop(short Size);

