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
	"MiscPrimitivePlugin browseTranslatedPrimitives"
	^#((Bitmap compress:toByteArray:)
		(Bitmap decompress:fromByteArray:at:)
		(Bitmap encodeBytesOf:in:at:)	"merely a support function"
		(Bitmap encodeInt:in:at:)		"merely a support function"
		(ByteString compare:with:collated:)
		(ByteString translate:from:to:table:)	
		(ByteString findFirstInString:inSet:startingAt:)
		(ByteString indexOfAscii:inString:startingAt:)
		(ByteString findSubstring:in:startingAt:matchTable:)
		(ByteArray hashBytes:startingWith:)
		(SampledSound convert8bitSignedFrom:to16Bit:))
]

{ #category : #'helper functions' }
MiscPrimitivePlugin >> asciiValue: aCharacter [
	<cmacro: '(aCharacter) aCharacter'>
	^aCharacter asciiValue
]
