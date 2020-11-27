Class {
	#name : #LibFFICIF,
	#superclass : #VMStructType,
	#instVars : [
		'address',
		'libFFI',
		'abi',
		'nargs',
		'arg_types',
		'rtype',
		'bytes',
		'flags'
	],
	#category : #'VMMaker-FFI'
}

{ #category : #translation }
LibFFICIF class >> filteredInstVarNames [
	"Eliminate the obvious simulation-only inst vars"
	^ super filteredInstVarNames copyWithoutAll: #(address libFFI)
]

{ #category : #translation }
LibFFICIF class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [ 

	self filteredInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['abi']		-> [#'ffi_abi'].
						['nargs']		-> [#'unsigned int'].
						['arg_types']		-> [#'ffi_type **'].
						['rtype']		-> [#'ffi_type *'].
						['bytes']		-> [#'unsigned int'].
						['flags']		-> [#'unsigned int'].
				} otherwise: [ self halt ])]
]

{ #category : #translation }
LibFFICIF class >> printTypedefOn: aStream [

	"This is already defined in ffi.h"
]

{ #category : #translation }
LibFFICIF class >> structTypeName [
	
	^ 'ffi_cif'
]

{ #category : #accessing }
LibFFICIF >> address [
	<doNotGenerate>	
	^ address
]

{ #category : #accessing }
LibFFICIF >> address: anInteger [ 
	<doNotGenerate>	
	address := anInteger
]

{ #category : #accessing }
LibFFICIF >> argTypeAt: anIndex [

	^ self arg_types at: anIndex
]

{ #category : #accessing }
LibFFICIF >> arg_types [

	^ arg_types
]

{ #category : #simulation }
LibFFICIF >> argumentTypes: aCollectionOfTypes [ 
	<doNotGenerate>
	nargs := aCollectionOfTypes size.
	arg_types := CArrayAccessor on: aCollectionOfTypes
]

{ #category : #accessing }
LibFFICIF >> interpreter [
	
	<doNotGenerate>
	^ libFFI interpreter
]

{ #category : #accessing }
LibFFICIF >> libFFI: aLibFFI [ 
	<doNotGenerate>	
	libFFI := aLibFFI
]

{ #category : #accessing }
LibFFICIF >> nargs [

	^ nargs
]

{ #category : #accessing }
LibFFICIF >> numberArguments [

	^ self nargs
]

{ #category : #testing }
LibFFICIF >> parametersToSmalltalk: parameters [ 
	<doNotGenerate>		
	^ arg_types getObject collectWithIndex: [ :type :index | 
		type marshallToSmalltalk: (parameters at: index - 1) ].
]

{ #category : #accessing }
LibFFICIF >> returnType [ 
	<inline: #always>
	
	^ self rtype
]

{ #category : #accessing }
LibFFICIF >> returnType: aType [ 
	<inline: #always>
	
	self rtype: aType
]

{ #category : #accessing }
LibFFICIF >> rtype [
	^ rtype
]

{ #category : #accessing }
LibFFICIF >> rtype: aLibFFIType [ 
	rtype := aLibFFIType
]
