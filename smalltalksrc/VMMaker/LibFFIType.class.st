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

{ #category : #accessing }
LibFFIType >> elements: aCollection [ 
	elements := aCollection
]

{ #category : #testing }
LibFFIType >> fromSmalltalk: aNumber putInto: aCArrayAccessor [
	<doNotGenerate>
	[ type ]
		caseOf: {
		[ FFI_TYPE_SINT8 ] -> [ | intHolder | 
			intHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'int8_t *'.
			intHolder at: 0 put: aNumber].
		[ FFI_TYPE_SINT16 ] -> [ | intHolder | 
			intHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'int16_t *'.
			intHolder at: 0 put: aNumber].
		[ FFI_TYPE_SINT32 ] -> [ | intHolder | 
			intHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'int32_t *'.
			intHolder at: 0 put: aNumber].
		[ FFI_TYPE_SINT64 ] -> [ | intHolder | 
			intHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'int64_t *'.
			intHolder at: 0 put: aNumber].

		[ FFI_TYPE_UINT8 ] -> [ | intHolder | 
			intHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'uint8_t *'.
			intHolder at: 0 put: aNumber].
		[ FFI_TYPE_UINT16 ] -> [ | intHolder | 
			intHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'uint16_t *'.
			intHolder at: 0 put: aNumber].
		[ FFI_TYPE_UINT32 ] -> [ | intHolder | 
			intHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'uint32_t *'.
			intHolder at: 0 put: aNumber].
		[ FFI_TYPE_UINT64 ] -> [ | intHolder | 
			intHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'uint64_t *'.
			intHolder at: 0 put: aNumber].

		[ FFI_TYPE_POINTER ] -> [ | ptrHolder | 
			ptrHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'void **'.
			ptrHolder at: 0 put: aNumber].

		"Returning an Struct returns copy the value into the return buffer"
		[ FFI_TYPE_STRUCT ] -> [ 
			aCArrayAccessor object replaceFrom: 1 to: aNumber size with: aNumber startingAt: 1  ].

		[ FFI_TYPE_FLOAT ] -> [ | floatHolder | 
			floatHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'float *'.
			floatHolder at: 0 put: aNumber].
		[ FFI_TYPE_DOUBLE ] -> [ | doubleHolder | 
			doubleHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'double *'.
			doubleHolder at: 0 put: aNumber].
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
			[ FFI_TYPE_FLOAT ] -> [ libFFI interpreter objectMemory readFloat32AtPointer: holder ].
			[ FFI_TYPE_DOUBLE ] -> [ libFFI interpreter objectMemory readFloat64AtPointer: holder ].
			[ FFI_TYPE_POINTER ] -> [ (holder asPointerAccessor: libFFI interpreter objectMemory wordSize) at: 0 ]. 
			[ FFI_TYPE_STRUCT ] -> [ holder object ]. 
			[ FFI_TYPE_SINT8 ] -> [ (holder asIntAccessorOfSize: 1 signed: true) at: 0 ].
			[ FFI_TYPE_UINT8 ] -> [ (holder asIntAccessorOfSize: 1 signed: false) at: 0 ].

			[ FFI_TYPE_SINT16 ] -> [ (holder asIntAccessorOfSize: 2 signed: true) at: 0 ].
			[ FFI_TYPE_UINT16 ] -> [ (holder asIntAccessorOfSize: 2 signed: false) at: 0 ].

			[ FFI_TYPE_SINT32 ] -> [ (holder asIntAccessorOfSize: 4 signed: true) at: 0 ].
			[ FFI_TYPE_UINT32 ] -> [ (holder asIntAccessorOfSize: 4 signed: false) at: 0 ].

			[ FFI_TYPE_SINT64 ] -> [ (holder asIntAccessorOfSize: 8 signed: true) at: 0 ].
			[ FFI_TYPE_UINT64 ] -> [ (holder asIntAccessorOfSize: 8 signed: false) at: 0 ].		
		} 
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
