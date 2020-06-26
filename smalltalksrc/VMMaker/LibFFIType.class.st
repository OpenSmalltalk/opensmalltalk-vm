Class {
	#name : #LibFFIType,
	#superclass : #VMStructType,
	#instVars : [
		'type',
		'size',
		'alignment',
		'elements',
		'libFFI'
	],
	#pools : [
		'LibFFIConstants'
	],
	#category : #'VMMaker-FFI'
}

{ #category : #translation }
LibFFIType class >> filteredInstVarNames [
	"Eliminate the obvious simulation-only inst vars"
	^ self allInstVarNames copyWithoutAll: #(libFFI)
]

{ #category : #'type constants' }
LibFFIType class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [ 

	self filteredInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['size']		-> [#'size_t'].
						['alignment']		-> [#'unsigned short'].
						['type']		-> [#'unsigned short'].
						['elements']		-> [#'struct _ffi_type **'].
				} otherwise: [ self halt ])]
]

{ #category : #'type constants' }
LibFFIType class >> printTypedefOn: aStream [

	"This is already defined in ffi.h"
]

{ #category : #'type constants' }
LibFFIType class >> structTypeName [
	
	^ 'ffi_type'
]

{ #category : #'type constants' }
LibFFIType class >> type: aType size: aSize on: aLibFFI [

	^ self new
		type: aType;
		size: aSize;
		libFFI: aLibFFI;
		yourself
]

{ #category : #testing }
LibFFIType >> fromSmalltalk: aNumber putInto: aCArrayAccessor [
	<doNotGenerate>
	[ type ]
		caseOf: {
		[ FFI_TYPE_FLOAT ] -> [ |floatHolder| 
			floatHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'float *'.
			floatHolder at: 0 put: aNumber].
		[ FFI_TYPE_DOUBLE ] -> [ |dobuleHolder| 
			dobuleHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'double *'.
			dobuleHolder at: 0 put: aNumber].
		[ FFI_TYPE_VOID ] -> []		
		} otherwise: [ self halt ]
]

{ #category : #accessing }
LibFFIType >> libFFI: aLibFFI [ 
	libFFI := aLibFFI
]

{ #category : #simulating }
LibFFIType >> marshallToSmalltalk: holder [ 
		
	^ [ type ] 
		caseOf: { 
			[ FFI_TYPE_FLOAT ] -> [ libFFI interpreter objectMemory float32AtPointer: holder ].
			[ FFI_TYPE_DOUBLE ] -> [ libFFI interpreter objectMemory float64AtPointer: holder ].
			[ FFI_TYPE_POINTER ] -> [ (holder asPointerAccessor: libFFI interpreter objectMemory wordSize) at: 0 ] } 
		otherwise: [ self halt ]

]

{ #category : #accessing }
LibFFIType >> size [
	^ size
]

{ #category : #accessing }
LibFFIType >> size: anObject [
	size := anObject
]

{ #category : #accessing }
LibFFIType >> type [
	^ type
]

{ #category : #accessing }
LibFFIType >> type: anObject [
	type := anObject
]
