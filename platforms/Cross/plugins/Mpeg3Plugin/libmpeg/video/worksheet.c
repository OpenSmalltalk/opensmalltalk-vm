#include <stdio.h>
#include <stdlib.h>
#include <time.h>


static long long  mpeg3_MMX_601_Y_COEF = 0x0000004000400040;

inline void mpeg3_601_mmx(unsigned long y, 
		unsigned long *output)
{
	__asm {
/* Output will be 0x00rrggbb */
	movd (y), %%mm0;          /* Load y   0x00000000000000yy */
/*	pmullw mpeg3_MMX_601_Y_COEF, %%mm0;   // Scale y   0x00000000000000yy */
 	psllw $6, %%mm0;                /* Shift y coeffs 0x0000yyy0yyy0yyy0 */
	movd %%mm0, (output);          /* Store output */
	}
}


int main(int argc, char *argv[])
{
	unsigned char output[1024];

	memset(output, 0, 1024);
	mpeg3_601_mmx(1, (unsigned long*)output);
	printf("%02x%02x\n", *(unsigned char*)&output[1], *(unsigned char*)&output[0]);
}
