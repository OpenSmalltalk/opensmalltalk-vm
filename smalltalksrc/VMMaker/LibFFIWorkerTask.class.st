Class {
	#name : #LibFFIWorkerTask,
	#superclass : #VMStructType,
	#instVars : [
		'address',
		'anExternalFunction',
		'cif',
		'parametersAddress',
		'returnHolderAddress',
		'semaphoreIndex'
	],
	#category : #'VMMaker-FFI'
}

{ #category : #translation }
LibFFIWorkerTask class >> filteredInstVarNames [
	"Eliminate the obvious simulation-only inst vars"
	^ self allInstVarNames copyWithoutAll: #(address)
]

{ #category : #translation }
LibFFIWorkerTask class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [ 

	self filteredInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['anExternalFunction']		-> [#'void *'].
						['cif']		-> [#'ffi_cif *'].
						['parametersAddress']		-> [#'void *'].
						['returnHolderAddress']		-> [#'void *'].
						['semaphoreIndex']		-> [#'int'].
				} otherwise: [ self halt ])]
]

{ #category : #translation }
LibFFIWorkerTask class >> printTypedefOn: aStream [

	"This is already defined in workerTask.h"
]

{ #category : #translation }
LibFFIWorkerTask class >> structTypeName [
	
	^ 'WorkerTask'
]

{ #category : #accessing }
LibFFIWorkerTask >> anExternalFunction [
	^ anExternalFunction
]

{ #category : #accessing }
LibFFIWorkerTask >> anExternalFunction: anObject [
	anExternalFunction := anObject
]

{ #category : #accessing }
LibFFIWorkerTask >> asInteger [

	^ address ifNil: [ 
		  address := (Random new nextInteger: 1024) + 16rFF1FF ]
]

{ #category : #'memory access' }
LibFFIWorkerTask >> cCoerce: value to: cTypeString [

	<doNotGenerate>

	^value
		ifNil: [value]
		ifNotNil: [value coerceTo: cTypeString sim: cif interpreter]
]

{ #category : #accessing }
LibFFIWorkerTask >> cif [
	^ cif
]

{ #category : #accessing }
LibFFIWorkerTask >> cif: anObject [
	cif := anObject
]

{ #category : #operations }
LibFFIWorkerTask >> doFreeFromTask: anAddress [

	<cmacro: '(aTask,anAddress) (free(anAddress))'>
	
]

{ #category : #operations }
LibFFIWorkerTask >> freeTask [
	
	self parametersAddress
		ifNotNil: [ :anAddress | | parameters |
			parameters := self cCoerce: anAddress to: #'void **'. 
			0 to: self cif nargs - 1 do: [ :i | 
				(parameters at: i) ifNotNil: [ :anParameterAddress | self doFreeFromTask: anParameterAddress ] ].
			self doFreeFromTask: parameters ]. 
	
	self returnHolderAddress 
		ifNotNil: [ :anAddress | self doFreeFromTask: anAddress ]. 
		
	self doFreeFromTask: self asInteger
]

{ #category : #accessing }
LibFFIWorkerTask >> parametersAddress [
	^ parametersAddress
]

{ #category : #accessing }
LibFFIWorkerTask >> parametersAddress: anObject [
	parametersAddress := anObject
]

{ #category : #accessing }
LibFFIWorkerTask >> returnHolderAddress [
	^ returnHolderAddress
]

{ #category : #accessing }
LibFFIWorkerTask >> returnHolderAddress: anObject [
	returnHolderAddress := anObject
]

{ #category : #accessing }
LibFFIWorkerTask >> semaphoreIndex [
	^ semaphoreIndex
]

{ #category : #accessing }
LibFFIWorkerTask >> semaphoreIndex: anObject [
	semaphoreIndex := anObject
]
