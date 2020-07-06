Class {
	#name : #LibFFIConstants,
	#superclass : #SharedPool,
	#classVars : [
		'FFI_TYPE_DOUBLE',
		'FFI_TYPE_FLOAT',
		'FFI_TYPE_INT',
		'FFI_TYPE_LONGDOUBLE',
		'FFI_TYPE_POINTER',
		'FFI_TYPE_SINT16',
		'FFI_TYPE_SINT32',
		'FFI_TYPE_SINT64',
		'FFI_TYPE_SINT8',
		'FFI_TYPE_STRUCT',
		'FFI_TYPE_UINT16',
		'FFI_TYPE_UINT32',
		'FFI_TYPE_UINT64',
		'FFI_TYPE_UINT8',
		'FFI_TYPE_VOID',
		'INT16_MAX',
		'INT16_MIN',
		'INT32_MAX',
		'INT32_MIN',
		'INT64_MAX',
		'INT64_MIN',
		'INT8_MAX',
		'INT8_MIN',
		'UINT16_MAX',
		'UINT32_MAX',
		'UINT64_MAX',
		'UINT8_MAX'
	],
	#category : #'VMMaker-FFI'
}

{ #category : #'class initialization' }
LibFFIConstants class >> initialize [

	<script: 'self initialize'>

	FFI_TYPE_VOID := 0.
	FFI_TYPE_INT := 1.
	FFI_TYPE_FLOAT := 2.
	FFI_TYPE_DOUBLE := 3.
	FFI_TYPE_LONGDOUBLE := 4.

	FFI_TYPE_UINT8 := 5.
	FFI_TYPE_SINT8 := 6.
	FFI_TYPE_UINT16 := 7. 
	FFI_TYPE_SINT16 := 8.
	FFI_TYPE_UINT32 := 9.
	FFI_TYPE_SINT32 := 10.
	FFI_TYPE_UINT64 := 11.
	FFI_TYPE_SINT64 := 12.

	FFI_TYPE_STRUCT := 13.

	FFI_TYPE_POINTER := 14.
	

	"Max ranges as defined in stdint.h"
	INT8_MAX :=  2**( 8 - 1) - 1.
	INT8_MIN :=  (2**( 8 - 1)) negated.
	UINT8_MAX := 2**( 8) - 1.
	
	INT16_MAX :=  2**( 16 - 1) - 1.
	INT16_MIN :=  (2**( 16 - 1)) negated.
	UINT16_MAX := 2**( 16) - 1.
	
	INT32_MAX :=  2**( 32 - 1) - 1.
	INT32_MIN :=  (2**( 32 - 1)) negated.
	UINT32_MAX := 2**( 32) - 1.	

	INT64_MAX :=  2**( 64 - 1) - 1.
	INT64_MIN :=  (2**( 64 - 1)) negated.
	UINT64_MAX := 2**( 64) - 1.	

]
