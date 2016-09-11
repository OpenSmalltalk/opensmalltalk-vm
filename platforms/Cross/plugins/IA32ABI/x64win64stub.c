/* Stub for X64 Win64 
This function must lie into another file than x64win64abicc
otherwise C Compiler will detect the parameter mismatch and bark,
or worse, optimize the call away.
*/

#if x86_64|x64|__x86_64|__x86_64__|_M_AMD64|_M_X64
#ifdef WIN32
/* Copy the floating point values passed by register into a table fpargs */
void saveFloatRegsWin64(double xmm0,double xmm1,double xmm2, double xmm3,double *fpargs)
{
	fpargs[0]=xmm0;
	fpargs[1]=xmm1;
	fpargs[2]=xmm2;
	fpargs[3]=xmm3;
}
double fakeReturnDouble(double xmm0)
{
	return xmm0;
}
#endif
#endif