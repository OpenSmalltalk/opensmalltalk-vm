Class {
	#name : #SpurBootstrapSqueak43Prototypes,
	#superclass : #SpurBootstrapSqueakFamilyPrototypes,
	#category : #'CogAttic-Bootstrapping'
}

{ #category : #accessing }
SpurBootstrapSqueak43Prototypes class >> imageType [
	^ 'squeak 4.3'
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> BlockClosurePROTOTYPEsimulateValueWithArguments: anArray caller: aContext [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> CharacterPROTOTYPEshouldBePrintedAsLiteral [

	^(self asInteger between: 33 and: 255) and: [self asInteger ~= 127]
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> CompiledMethodPROTOTYPEencoderClass [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> DecompilerPROTOTYPEdecompile: aSelector in: aClass method: aMethod using: aConstructor [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> InstructionStreamPROTOTYPEinterpretExtension: offset in: method for: client [
	^self interpretV3ClosuresExtension: offset in: method for: client
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> InstructionStreamPROTOTYPEnextPc: currentByte [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> InstructionStreamPROTOTYPEskipCallPrimitive [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> MCClassDefinitionPROTOTYPEkindOfSubclass [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> MCMethodDefinitionPROTOTYPEinitializeWithClassName: classString
classIsMeta: metaBoolean
selector: selectorString
category: catString
timeStamp: timeString
source: sourceString [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapSqueak43Prototypes >> MethodNodePROTOTYPEprintPropertiesOn: aStream [
	<indirect>
]
