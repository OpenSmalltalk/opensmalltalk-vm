Class {
	#name : #LibFFIConstants,
	#superclass : #SharedPool,
	#classVars : [
		'FFI_TYPE_DOUBLE',
		'FFI_TYPE_FLOAT',
		'FFI_TYPE_INT',
		'FFI_TYPE_POINTER',
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

	FFI_TYPE_POINTER := 14	
]
