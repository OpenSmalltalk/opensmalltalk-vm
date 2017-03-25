"
This plugin pulls together a number of translatable methods with no particularly meaningful home. See class>translatedPrimitives for the list
"
Class {
	#name : #MiscPrimitivePlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
MiscPrimitivePlugin class >> monticelloDescription [
	"Override to include the primitive-supplying classes."
	"self monticelloDescription"
	^super monticelloDescription, '\' withCRs,
	 ((self translatedPrimitives
		collect: [:pair| CCodeGenerator monticelloDescriptionFor: (Smalltalk classNamed: pair first)])
			asSet asArray sort reduce: [:a :b| a, '\' withCRs, b])
]

{ #category : #translation }
MiscPrimitivePlugin class >> translatedPrimitives [
	"an assorted list of various primitives"
	(ByteString compiledMethodAt: #findSubstringViaPrimitive:in:startingAt:matchTable: ifAbsent: []) ifNotNil:
		[^#("Pharo uses findSubstringViaPrimitive:in:startingAt:matchTable:"
			(Bitmap compress:toByteArray:)
			(Bitmap decompress:fromByteArray:at:)
			(Bitmap encodeBytesOf:in:at:)
			(Bitmap encodeInt:in:at:)
			(ByteString compare:with:collated:)
			(ByteString translate:from:to:table:)	
			(ByteString findFirstInString:inSet:startingAt:)
			(ByteString indexOfAscii:inString:startingAt:)
			(String findSubstringViaPrimitive:in:startingAt:matchTable:)
			(ByteArray hashBytes:startingWith:)
			(SampledSound convert8bitSignedFrom:to16Bit:))].
	^#(
		(Bitmap compress:toByteArray:)
		(Bitmap decompress:fromByteArray:at:)
		(Bitmap encodeBytesOf:in:at:)
		(Bitmap encodeInt:in:at:)
		(ByteString compare:with:collated:)
		(ByteString translate:from:to:table:)	
		(ByteString findFirstInString:inSet:startingAt:)
		(ByteString indexOfAscii:inString:startingAt:)
		(ByteString findSubstring:in:startingAt:matchTable:)
		(ByteArray hashBytes:startingWith:)
		(SampledSound convert8bitSignedFrom:to16Bit:)
	)

	"| tps |
	'This opens a list browser on all translated primitives in the image'.
	 tps := (SystemNavigation default allImplementorsOf: #translatedPrimitives)
				inject: Set new
				into: [:tp :mr|
					tp addAll: (mr actualClass theNonMetaClass translatedPrimitives collect:
								[:pair|
								MethodReference
									class: (((Smalltalk at: pair first) canUnderstand: pair last)
												ifTrue: [Smalltalk at: pair first]
												ifFalse: [(Smalltalk at: pair first) class])
									selector: pair last]);
						yourself].
	SystemNavigation default browseMessageList: tps asArray sort name: 'Translated Primitives' "
]

{ #category : #'helper functions' }
MiscPrimitivePlugin >> asciiValue: aCharacter [
	<cmacro: '(aCharacter) aCharacter'>
	^aCharacter asciiValue
]
