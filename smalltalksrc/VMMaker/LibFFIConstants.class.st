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
		'FFI_TYPE_VOID'
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
]
