#include "pThreadedFFI.h"

void fillBasicType(sqInt aOop){
	void* address;
	int typeCode;

	typeCode = fetchIntegerofObject(2, aOop);
	
	/* 
			"Platform independent types"
			VOID := self newTypeName: #void code: 1.
		 	FLOAT := self newTypeName: #float code: 2.
		 	DOUBLE := self newTypeName: #double code: 3.

			UINT8 := self newIntTypeName: #uint8 code: 4 signed: false.
			UINT16 := self newIntTypeName: #uint16 code: 5 signed: false.
			UINT32 := self newIntTypeName: #uint32 code: 6 signed: false.
			UINT64 := self newIntTypeName: #uint64 code: 7 signed: false.
			
			SINT8 := self newIntTypeName: #sint8 code: 8 signed: true.
			SINT16 := self newIntTypeName: #sint16 code: 9 signed: true.
			SINT32 := self newIntTypeName: #sint32 code: 10 signed: true.
			SINT64 := self newIntTypeName: #sint64 code: 11 signed: true.

			"Aliased types, these depends of the architecture"

			POINTER := self newTypeName: #pointer code: 12.

			UCHAR := self newIntTypeName: #uchar code: 13 signed: false.
			SCHAR := self newIntTypeName: #schar code: 14 signed: true.
			
			USHORT := self newIntTypeName: #ushort code: 15 signed: false.
			SSHORT := self newIntTypeName: #sshort code: 16 signed: true.

			UINT := self newIntTypeName: #uint code: 17 signed: false.
			SINT := self newIntTypeName: #sint code: 18 signed: true.

			ULONG := self newIntTypeName: #ulong code: 19 signed: false.
			SLONG := self newIntTypeName: #slong code: 20 signed: true.	
*/
		
	switch(typeCode){
		case 1:
			address = &ffi_type_void;
			break;
		case 2:
			address = &ffi_type_float;
			break;
		case 3:
			address = &ffi_type_double;
			break;

		case 4:
			address = &ffi_type_uint8;
			break;
		case 5:
			address = &ffi_type_uint16;
			break;
		case 6:
			address = &ffi_type_uint32;
			break;
		case 7:
			address = &ffi_type_uint64;
			break;

		case 8:
			address = &ffi_type_sint8;
			break;
		case 9:
			address = &ffi_type_sint16;
			break;
		case 10:
			address = &ffi_type_sint32;
			break;
		case 11:
			address = &ffi_type_sint64;
			break;

		case 12:
			address = &ffi_type_pointer;
			break;

		case 13:
			address = &ffi_type_uchar;
			break;
		case 14:
			address = &ffi_type_schar;
			break;
		case 15:
			address = &ffi_type_ushort;
			break;
		case 16:
			address = &ffi_type_sshort;
			break;
		case 17:
			address = &ffi_type_uint;
			break;
		case 18:
			address = &ffi_type_sint;
			break;
		case 19:
			address = &ffi_type_ulong;
			break;
		case 20:
			address = &ffi_type_slong;
			break;

		default:
			primitiveFailFor(1);
	}
	
	setHandler(aOop, address);
}

int getTypeByteSize(void* aType){
	return ((ffi_type*) aType)->size;
}
