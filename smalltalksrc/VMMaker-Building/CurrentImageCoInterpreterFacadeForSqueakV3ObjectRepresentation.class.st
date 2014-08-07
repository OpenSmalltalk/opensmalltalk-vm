Class {
	#name : #CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation,
	#superclass : #CurrentImageCoInterpreterFacade,
	#category : #'VMMaker-Support'
}

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation class >> objectMemoryClass [
	^NewCoObjectMemory
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation class >> objectRepresentationClass [
	^CogObjectRepresentationForSqueakV3
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> baseHeaderSize [
	^ObjectMemory baseHeaderSize
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> characterTable [
	^self oopForObject: Character characterTable
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> compactClassIndexOfClass: classOop [
	"Ugh, can't reply on the host.  Spur doesn't have compact classes"
	| aClass |
	aClass := self objectForOop: classOop.
	^false
		ifTrue: [aClass indexIfCompact]
		ifFalse:
			[aClass caseOf: {
				[CompiledMethod]		->	[1].
				[Array]					->	[3].
				[LargeNegativeInteger]	->	[4].
				[LargePositiveInteger]	->	[5].
				[Float]					->	[6].
				[Association]			->	[8].
				[Point]					->	[9].
				[Rectangle]				->	[10].
				[ByteString]			->	[11].
				[MethodContext]		->	[14].
				[Bitmap]				->	[16]
				}
				otherwise: [0]]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> formatOfClass: classOop [ 
	^(self objectForOop: classOop) format << 1
]

{ #category : #accessing }
CurrentImageCoInterpreterFacadeForSqueakV3ObjectRepresentation >> youngStartAddress [
	^16r4E5E400
]
