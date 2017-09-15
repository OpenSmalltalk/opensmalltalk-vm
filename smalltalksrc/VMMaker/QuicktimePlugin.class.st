Class {
	#name : #QuicktimePlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
QuicktimePlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
QuicktimePlugin class >> requiresCrossPlatformFiles [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #'system primitives' }
QuicktimePlugin >> initialiseModule [
	<export: true>
	^self sqQuicktimeInitialize 
]

{ #category : #'system primitives' }
QuicktimePlugin >> moduleUnloaded: aModuleName [ 
	"The module with the given name was just unloaded. 
	Make sure we have no dangling references."
	<export: true>
	<var: #aModuleName type: 'char *'>
	(aModuleName strcmp: 'QuicktimePlugin') = 0
		ifTrue: [self sqQuicktimeShutdown]
]

{ #category : #'system primitives' }
QuicktimePlugin >> primitiveClearFrameCompletedSemaphore: data [

	self primitive: 'primitiveClearFrameCompletedSemaphore' parameters: #(SmallInteger).
	self stQuicktimeClearSemaphore: data.
	^nil
]

{ #category : #'system primitives' }
QuicktimePlugin >> primitiveDestroyHandle: data [ 

	self primitive: 'primitiveDestroyHandle' parameters: #(SmallInteger).
	self stQuicktimeDestroy: data.
	^nil
]

{ #category : #'system primitives' }
QuicktimePlugin >> primitiveDestroySurface: data [ 

	self primitive: 'primitiveDestroySurface' parameters: #(SmallInteger).
	self stQuicktimeDestroySurface: data.
	^nil
]

{ #category : #'system primitives' }
QuicktimePlugin >> primitiveSetFrameCompletedSemaphore: semaIndex for: data [

	self primitive: 'primitiveSetFrameCompletedSemaphore'  parameters:#(SmallInteger SmallInteger).
	self stQuicktimeSetSemaphore: semaIndex for: data.
	^nil
]

{ #category : #'system primitives' }
QuicktimePlugin >> primitiveSetGWorldPtrOntoExistingSurface: surfaceID gWorld: bitMapPtr width: width height: height rowBytes: rowBytes depth: depth movie: moviePtr [
	| buffer movie |

	<var: #buffer type: #'char *'>
	<var: #movie type: #'sqIntptr_t'>
	self primitive: 'primitiveSetGWorldPtrOntoExistingSurface'  parameters:#(SmallInteger Oop SmallInteger SmallInteger SmallInteger SmallInteger Oop).
	buffer := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: bitMapPtr) to: 'char *'.
	movie := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: moviePtr) to: #'sqIntptr_t'.
	self stQuicktimeSetToExistingSurface: surfaceID gworld: buffer width: width height: height rowBytes: rowBytes depth: depth movie: movie.
	
]

{ #category : #'system primitives' }
QuicktimePlugin >> primitiveSetGWorldPtrOntoSurface: bitMapPtr width: width height: height rowBytes: rowBytes depth: depth movie: moviePtr [
	| buffer movie results |

	<var: #buffer type: #'char *'>
	<var: #movie type: #'sqIntptr_t'>
	self primitive: 'primitiveSetGWorldPtrOntoSurface'  parameters:#(Oop SmallInteger SmallInteger SmallInteger SmallInteger Oop).
	buffer := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: bitMapPtr) to: 'char *'.
	movie := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: moviePtr) to: #'sqIntptr_t'.
	results := self stQuicktimeSetSurface: buffer width: width height: height rowBytes: rowBytes depth: depth movie: movie.
	^results asOop: SmallInteger 
]
