/****************************************************************************
*   PROJECT: Squeak foreign function interface
*   FILE:    sqUnixFFI.c
*   CONTENT: Unix support for the foreign function interface
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: any-libffi.c 966 2005-03-09 08:50:45Z piumarta $
*
*   NOTES:  The Unix version of the FFI support code relies on libffi from
*	    http://sourceware.cygnus.com/libffi/
*
*****************************************************************************/
#include "sq.h"
#include "sqFFI.h"

#ifndef NO_FFI_SUPPORT

#include <ffi.h>

#ifndef  FFI_TYPE_STRUCT	/* this is private in libffi-2 */
# define FFI_TYPE_STRUCT 13
#endif

#if defined(FFI_TEST)
  static int primitiveFail(void) { puts("primitive fail"); exit(1); return 0; }
#else
  extern struct VirtualMachine *interpreterProxy;
# define primitiveFail() interpreterProxy->primitiveFail();
#endif

#if 1
#define HAVE_LONGLONG
#endif

/* Check if HAVE_LONGLONG is defined (should be figured out by configure */
#ifdef HAVE_LONGLONG
#define HAS_LONGLONG 1
#define LONGLONG long long
#endif

/* Error if LONGLONG is not defined */
#if HAS_LONGLONG
#ifndef LONGLONG
#error "You must define LONGLONG if HAS_LONGLONG is defined"
#endif
#endif

/* Max number of arguments in call */
#define FFI_MAX_ARGS 32

static ffi_type*  ffiTypes[FFI_MAX_ARGS];
static void*      ffiArgs[FFI_MAX_ARGS];

static char   ffiBytes[FFI_MAX_ARGS];
static short  ffiShorts[FFI_MAX_ARGS];
static int    ffiInts[FFI_MAX_ARGS];
static float  ffiFloats[FFI_MAX_ARGS];
static double ffiDoubles[FFI_MAX_ARGS];
static int    ffiArgIndex = 0;

static ffi_type*  ffiStructTypes[FFI_MAX_ARGS];
static int ffiStructIndex = 0;

/* helpers */
#define CHECK_ARGS() if(ffiArgIndex >= FFI_MAX_ARGS) return primitiveFail();
#define PUSH_TYPE(type) { CHECK_ARGS(); ffiTypes[ffiArgIndex] = &type; }
#define PUSH(where, what, type) { \
	PUSH_TYPE(type); where[ffiArgIndex] = what; \
	ffiArgs[ffiArgIndex] = (void*) (where + ffiArgIndex); \
	ffiArgIndex++;\
}


#define BARG_PUSH(value, type) PUSH(ffiBytes, value, type)
#define SARG_PUSH(value, type) PUSH(ffiShorts, value, type)
#define IARG_PUSH(value, type) PUSH(ffiInts, value, type)
#define FARG_PUSH(value) PUSH(ffiFloats, value, ffi_type_float)
#define DARG_PUSH(value) PUSH(ffiDoubles, value, ffi_type_double)

#if HAS_LONGLONG
static LONGLONG ffiLongLongs[FFI_MAX_ARGS];
#define LARG_PUSH(value, type) PUSH(ffiLongLongs, value, type)
#endif

/* The 64bit return value storage area - aligned by the C compiler */
static double   returnValue;
/* Storage area for large structure returns */
static ffi_type* structReturnType = NULL;
static void *structReturnValue = NULL;

/* The area for temporarily allocated strings */
static char *ffiTempStrings[FFI_MAX_ARGS];
/* The number of temporarily allocated strings */
static int   ffiTempStringCount = 0;

/*****************************************************************************/
/*****************************************************************************/

/*  ffiInitialize:
    Announce that the VM is about to do an external function call. */
int ffiInitialize(void)
{
  ffiArgIndex = 0;
  ffiTempStringCount = 0;
  ffiStructIndex = 0;
  structReturnType = NULL;
  structReturnValue = NULL;
  return 1;
}

/*  ffiSupportsCallingConvention:
    Return true if the support code supports the given calling convention */
int ffiSupportsCallingConvention(int callType)
{
  if(callType == FFICallTypeCDecl) return 1;
  return 0;
}

/*  ffiAlloc:
    Allocate space from the external heap */
int ffiAlloc(int byteSize)
{
  return (int)malloc(byteSize);
}
/*  ffiFree:
    Free space from the external heap */
int ffiFree(sqIntptr_t pointer)
{
  if(pointer) free((void*)pointer);
  return 1;
}

/*****************************************************************************/
/*****************************************************************************/

int ffiPushSignedByte(int value)
{
  BARG_PUSH((char)value, ffi_type_sint8);
  return 1;
}

int ffiPushUnsignedByte(int value)
{
  BARG_PUSH((char)value, ffi_type_uint8);
  return 1;
}

int ffiPushSignedShort(int value)
{
  SARG_PUSH((short)value, ffi_type_sint16);
  return 1;
}

int ffiPushUnsignedShort(int value)
{
  SARG_PUSH((short)value, ffi_type_uint16);
  return 1;
}

int ffiPushSignedInt(int value)
{
  IARG_PUSH(value, ffi_type_sint32);
  return 1;
}

int ffiPushUnsignedInt(int value)
{
  IARG_PUSH(value, ffi_type_uint32);
  return 1;
}

int ffiPushSignedLongLong(int low, int high)
{
#if HAS_LONGLONG
  LONGLONG value = (((LONGLONG) high) << 32)  | ((LONGLONG) (unsigned) low);
  LARG_PUSH(value, ffi_type_sint64);
  return 1;
#else
  return primitiveFail();
#endif
}

int ffiPushUnsignedLongLong(int low, int high)
{
#if HAS_LONGLONG
  LONGLONG value = (((LONGLONG) high) << 32)  | ((LONGLONG) (unsigned) low);
  LARG_PUSH(value, ffi_type_uint64);
  return 1;
#else
  return primitiveFail();
#endif
}

int ffiPushSignedChar(int value)
{
  BARG_PUSH(value, ffi_type_sint8);
  return 1;
}

int ffiPushUnsignedChar(int value)
{
  BARG_PUSH(value, ffi_type_uint8);
  return 1;
}

int ffiPushBool(int value)
{
  IARG_PUSH(value, ffi_type_uint8);
  return 1;
}

int ffiPushSingleFloat(double value)
{
  FARG_PUSH((float)value);
  return 1;
}

int ffiPushDoubleFloat(double value)
{
  DARG_PUSH(value);
  return 1;
}


ffi_type* ffiCreateType(int *structSpec, int structSize)
{
  ffi_type *structType, **newTypes;
  int nTypes, i, typeSpec;

  /* count the number of atomic types we need to create */
  nTypes = 0;
  for(i=0; i<structSize; i++) {
    typeSpec = structSpec[i];
    if(typeSpec & FFIFlagPointer) nTypes++;
    else if(typeSpec & FFIFlagAtomic) nTypes++;
  }
  /* note: nTypes == 0 means an invalid structure */
  if(nTypes == 0) {
    printf("Warning: nTypes == 0 in ffiCreateTypes\n");
    return NULL;
  }
  /* allocate the structure type */
  structType = calloc(1, sizeof(ffi_type));
  /* allocate the atomic type refs */
  newTypes = calloc(nTypes+1, sizeof(ffi_type*));
  /* number of elements in type */
  structType->size = (*structSpec) & FFIStructSizeMask;
  structType->alignment = 4;
  structType->type = FFI_TYPE_STRUCT;
  structType->elements = newTypes;

  /* now go over the structure and fill in the fields */
  nTypes = 0;
  for(i=0; i<structSize; i++) {
    typeSpec = structSpec[i];
    if(typeSpec & FFIFlagPointer) {
      newTypes[nTypes++] = &ffi_type_pointer;
      continue;
    }
    if((typeSpec & FFIFlagAtomic) == 0) continue;
    switch((typeSpec & FFIAtomicTypeMask) >> FFIAtomicTypeShift) {
    case FFITypeBool:
      newTypes[nTypes++] = &ffi_type_uint8; break;
    case FFITypeUnsignedByte:
      newTypes[nTypes++] = &ffi_type_uint8; break;
    case FFITypeSignedByte:
      newTypes[nTypes++] = &ffi_type_sint8; break;
    case FFITypeUnsignedShort:
      newTypes[nTypes++] = &ffi_type_uint16; break;
    case FFITypeSignedShort:
      newTypes[nTypes++] = &ffi_type_sint16; break;
    case FFITypeUnsignedInt:
      newTypes[nTypes++] = &ffi_type_uint32; break;
    case FFITypeSignedInt:
      newTypes[nTypes++] = &ffi_type_sint32; break;
    case FFITypeUnsignedLongLong:
      newTypes[nTypes++] = &ffi_type_uint64; break;
    case FFITypeSignedLongLong:
      newTypes[nTypes++] = &ffi_type_sint64; break;
    case FFITypeUnsignedChar:
      newTypes[nTypes++] = &ffi_type_uint8; break;
    case FFITypeSignedChar:
      newTypes[nTypes++] = &ffi_type_sint8; break;
    case FFITypeSingleFloat:
      newTypes[nTypes++] = &ffi_type_float; break;
    case FFITypeDoubleFloat:
      newTypes[nTypes++] = &ffi_type_double; break;
    default:
      printf("Warning: unknown atomic type (%x) in ffiCreateTypes\n", 
	     typeSpec);
      free(newTypes);
      free(structType);
      return NULL;
    };
  }
  newTypes[nTypes++] = NULL;
  return structType;
}

int ffiPushStructureOfLength(int pointer, int* structSpec, int structSize)
{
  ffi_type *structType;

  if(pointer == 0) return primitiveFail();
  CHECK_ARGS(); /* fail early on */
  structType = ffiCreateType(structSpec, structSize);
  if(structType == NULL) return primitiveFail();
  ffiStructTypes[ffiStructIndex++] = structType;
  ffiTypes[ffiArgIndex] = structType;
  ffiArgs[ffiArgIndex] = (void*) pointer;
  ffiArgIndex++;
  return 1;
}

int ffiPushPointer(int pointer)
{
  IARG_PUSH(pointer, ffi_type_pointer);
  return 1;
}

int ffiPushStringOfLength(int srcIndex, int length)
{
  char *ptr;
  ptr = (char*) malloc(length+1);
  if(!ptr) return primitiveFail();
  memcpy(ptr, (void*)srcIndex, length);
  ptr[length] = 0;
  ffiTempStrings[ffiTempStringCount++] = ptr;
  IARG_PUSH((int)ptr, ffi_type_pointer);
  return 1;
}

/*****************************************************************************/
/*****************************************************************************/

/*  ffiCanReturn:
	Return true if the support code can return the given type. */
int ffiCanReturn(int *structSpec, int specSize)
{
  int header = *structSpec;
  if(header & FFIFlagPointer) return 1;
  if(header & FFIFlagStructure) {
    int structSize = header & FFIStructSizeMask;
    structReturnType = ffiCreateType(structSpec, specSize);
    if(!structReturnType) return 0;
    if(structSize > 8) {
      structReturnValue = calloc(1,structSize);
      if(!structReturnValue) return 0;
      return 1;
    }
  }
  return 1;
}

/*  ffiReturnFloatValue:
    Return the value from a previous ffi call with float return type. */
double ffiReturnFloatValue(void)
{
  return returnValue;
}

/*  ffiLongLongResultLow:
    Return the low 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultLow(void)
{
#if HAS_LONGLONG
  return (int) ( (*(LONGLONG*)&returnValue) & (LONGLONG)0xFFFFFFFFU);
#else
  return 0;
#endif
}

/*  ffiLongLongResultHigh:
    Return the high 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultHigh(void)
{
#if HAS_LONGLONG
  return (int) ( (*(LONGLONG*)&returnValue) >> 32);
#else
  return 0;
#endif
}

/*  ffiStoreStructure:
    Store the structure result of a previous ffi call into the given address*/
int ffiStoreStructure(int address, int structSize)
{
  if(structReturnValue) {
    memcpy((void*)address, (void*)structReturnValue, structSize);
  } else {
    memcpy((void*)address, (void*)&returnValue, structSize);
  }
  return 1;
}

/*  ffiCleanup:
    Cleanup after a foreign function call has completed.
    The generic support code only frees the temporarily
    allocated strings. */
int ffiCleanup(void)
{
  int i;
  for(i=0; i<ffiTempStringCount; i++)
    free(ffiTempStrings[i]);
  for(i=0; i<ffiStructIndex; i++) {
    free(ffiStructTypes[i]->elements);
    free(ffiStructTypes[i]);
    ffiStructTypes[i]=NULL;
  }
  if(structReturnType) {
    free(structReturnType->elements);
    free(structReturnType);
    structReturnType = NULL;
  }
  if(structReturnValue) {
    free(structReturnValue);
    structReturnValue = NULL;
  }
  ffiTempStringCount = 0;
  ffiStructIndex = 0;
  return 1;
}

/*****************************************************************************/
/*****************************************************************************/
int ffiCallAddress(int fn, ffi_type *returnType, int atomicArgType)
{
  ffi_cif cif;
  ffi_status result;
  int retVal;

  result = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, ffiArgIndex, 
			returnType, ffiTypes);
  if(result != FFI_OK) return primitiveFail();
  if(structReturnValue) {
    ffi_call(&cif, (void *)fn, (void *)structReturnValue, (void **)ffiArgs);
    return (int) structReturnValue;
  }
  ffi_call(&cif, (void *)fn, (void *)&returnValue, (void **)ffiArgs);
  retVal = *(int*)&returnValue;
#ifdef FFI_MIPS_N32
  /* Note: MIPS N32 ABI returns 64bit for integer/pointer whatever.
     This seems to be a bug in the fficall implementation. */
  retVal = ((int*)(&returnValue))[1];
#endif
  /* Promote certain return types to integral size */
  switch(atomicArgType) {
  case FFITypeUnsignedChar:
  case FFITypeUnsignedByte: retVal = *(unsigned char*) &retVal; break;
  case FFITypeSignedChar:
  case FFITypeSignedByte: retVal = *(signed char*) &retVal; break;
  case FFITypeUnsignedShort: retVal = *(unsigned short*) &retVal; break;
  case FFITypeSignedShort: retVal = *(signed short*) &retVal; break;
  case FFITypeSingleFloat: returnValue = *(float*)&returnValue; break;
  }
  return retVal;
}

int ffiCallAddressOfWithPointerReturn(int fn, int callType)
{
  return ffiCallAddress(fn, &ffi_type_pointer,-1);
}

int ffiCallAddressOfWithStructReturn(int fn, int callType, 
				     int *structSpec, int specSize)
{
  if(!structReturnType) return primitiveFail();
  return ffiCallAddress(fn, structReturnType,-1);
}

int ffiCallAddressOfWithReturnType(int fn, int callType, int typeSpec)
{
  ffi_type *returnType;
  int atomicType;
  atomicType = (typeSpec & FFIAtomicTypeMask) >> FFIAtomicTypeShift;
  switch(atomicType) {
  case FFITypeVoid:		returnType = &ffi_type_void; break;
  case FFITypeBool:		returnType = &ffi_type_uint8; break;
  case FFITypeUnsignedByte:	returnType = &ffi_type_uint8; break;
  case FFITypeSignedByte:	returnType = &ffi_type_sint8; break;
  case FFITypeUnsignedShort:	returnType = &ffi_type_uint16; break;
  case FFITypeSignedShort:	returnType = &ffi_type_sint16; break;
  case FFITypeUnsignedInt:	returnType = &ffi_type_uint32; break;
  case FFITypeSignedInt:       	returnType = &ffi_type_sint32; break;
  case FFITypeUnsignedLongLong: returnType = &ffi_type_uint64; break;
  case FFITypeSignedLongLong:	returnType = &ffi_type_sint64; break;
  case FFITypeUnsignedChar:	returnType = &ffi_type_uint8; break;
  case FFITypeSignedChar:      	returnType = &ffi_type_sint8; break;
  case FFITypeSingleFloat:	returnType = &ffi_type_float; break;
  case FFITypeDoubleFloat:	returnType = &ffi_type_double; break;
  default:
    return primitiveFail();
  }
  return ffiCallAddress(fn, returnType, atomicType);
}


#if defined(FFI_TEST)
void ffiDoAssertions(void) {}
#endif


#endif /* NO_FFI_SUPPORT */
