"
Here's a doit to generate my code:
	| offset crtab |
	offset := 1.
	crtab := String with: Character cr with: Character tab.
	CogMethod instVarNamesAndTypesForTranslationDo:
		[:name :type| | isByte class |
		(isByte := type = 'unsigned char') ifFalse:
			[offset := (offset - 1 + 7 bitAnd: -8) + 1].
		class := (CogBlockMethod instVarNames includes: name)
					ifTrue: [CogBlockMethodSurrogate64]
					ifFalse: [CogMethodSurrogate64].
		class
			compile: name, crtab, '^memory unsigned', (isByte ifTrue: ['ByteAt:'] ifFalse: ['LongLongAt:']), ' address + ', offset printString
			classified: #accessing.
		class
			compile: name, ': aValue', crtab, '^memory unsigned', (isByte ifTrue: ['ByteAt:'] ifFalse: ['LongLongAt:']), ' address + ', offset printString,
					' put: aValue'
			classified: #accessing.
		offset := offset + (isByte ifTrue: [1] ifFalse: [8])].
	CogMethodSurrogate64 class compile: 'alignedByteSize', crtab, '^', (offset + 7 bitAnd: -8) printString classified: #'instance creation'

"
Class {
	#name : #CogMethodSurrogate64,
	#superclass : #CogBlockMethodSurrogate64,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogMethodSurrogate64 class >> alignedByteSize [
	^40
]

{ #category : #accessing }
CogMethodSurrogate64 class >> offsetOf: aByteSymbol [
	"These should be generated!!"
	self assert: self objectMemoryClass baseHeaderSize = BaseHeaderSize.
	^aByteSymbol caseOf:
		{	[#methodObject]		-> [8 + BaseHeaderSize].
			[#selector]				-> [24 + BaseHeaderSize].
			[#blockEntryOffset]	-> [6 + BaseHeaderSize].
		}
]

{ #category : #accessing }
CogMethodSurrogate64 >> blockEntryOffset [
	^memory unsignedShortAt: address + 15
]

{ #category : #accessing }
CogMethodSurrogate64 >> blockEntryOffset: aValue [
	^memory
		unsignedShortAt: address + 15
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate64 >> blockSize [
	^memory unsignedShortAt: address + 13
]

{ #category : #accessing }
CogMethodSurrogate64 >> blockSize: aValue [
	^memory
		unsignedShortAt: address + 13
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate64 >> methodHeader [
	^memory unsignedLongLongAt: address + 25
]

{ #category : #accessing }
CogMethodSurrogate64 >> methodHeader: aValue [
	^memory
		unsignedLongLongAt: address + 25
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate64 >> methodObject [
	^memory unsignedLongLongAt: address + 17
]

{ #category : #accessing }
CogMethodSurrogate64 >> methodObject: aValue [
	^memory
		unsignedLongLongAt: address + 17
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate64 >> selector [
	^memory unsignedLongLongAt: address + 33
]

{ #category : #accessing }
CogMethodSurrogate64 >> selector: aValue [
	^memory
		unsignedLongLongAt: address + 33
		put: aValue
]
