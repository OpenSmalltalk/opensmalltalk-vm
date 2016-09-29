/* sqLowcodeFFI-i386 -- i386 Platform specific definitions for the FFI.
 *
 * Author: Ronie Salgado (roniesalg@gmail.com)
 */


#ifndef _SQ_LOWCODE_FFI_I386_H_
#define _SQ_LOWCODE_FFI_I386_H_

typedef struct _sqLowcodeCalloutState
{
    /* No callout state */

} sqLowcodeCalloutState;

#define lowcodeCalloutStatepointerRegister(calloutState, registerId) 0
#define lowcodeCalloutStatepointerRegistervalue(calloutState, registerId, value) 0

#define lowcodeCalloutStateint32Register(calloutState, registerId) 0
#define lowcodeCalloutStateint32Registervalue(calloutState, registerId, value) 0

#define lowcodeCalloutStateint64Register(calloutState, registerId) 0
#define lowcodeCalloutStateint64Registervalue(calloutState, registerId, value) 0

#define lowcodeCalloutStatefloat32Register(calloutState, registerId) 0
#define lowcodeCalloutStatefloat32Registervalue(calloutState, registerId, value) 0

#define lowcodeCalloutStatefloat64Register(calloutState, registerId) 0
#define lowcodeCalloutStatefloat64Registervalue(calloutState, registerId, value) 0

#define lowcodeCalloutStateFetchResultInt32(calloutState) 0
#define lowcodeCalloutStateFetchResultInt64(calloutState) 0
#define lowcodeCalloutStateFetchResultPointer(calloutState) 0

#define lowcodeCalloutStateFetchResultFloat32(calloutState) 0
#define lowcodeCalloutStateFetchResultFloat64(calloutState) 0
#define lowcodeCalloutStateFetchResultStructure(calloutState) 0

#define lowcodeCalloutStatestackPointerstackSizecallFunction(calloutState, stackPointer, stackSize, functionPointer)

#endif /*_SQ_LOWCODE_FFI_I386_H_*/
