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
	^32 + self baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate64 class >> offsetOf: aByteSymbol [
	"These should be generated!!"
	| baseHeaderSize |
	baseHeaderSize := self objectMemoryClass baseHeaderSize.
	^aByteSymbol caseOf:
		{	[#methodObject]		-> [8 + baseHeaderSize].
			[#methodHeader]		-> [16 + baseHeaderSize].
			[#selector]				-> [24 + baseHeaderSize].
			[#blockEntryOffset]	-> [6 + baseHeaderSize].
		}
]

{ #category : #accessing }
CogMethodSurrogate64 >> blockEntryOffset [
	^memory unsignedShortAt: address + 7 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate64 >> blockEntryOffset: aValue [
	^memory
		unsignedShortAt: address + baseHeaderSize + 7
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate64 >> blockSize [
	^memory unsignedShortAt: address + 5 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate64 >> blockSize: aValue [
	^memory
		unsignedShortAt: address + baseHeaderSize + 5
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate64 >> methodHeader [
	^memory unsignedLong64At: address + 17 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate64 >> methodHeader: aValue [
	^memory
		unsignedLong64At: address + baseHeaderSize + 17
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate64 >> methodObject [
	^memory unsignedLong64At: address + 9 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate64 >> methodObject: aValue [
	^memory
		unsignedLong64At: address + baseHeaderSize + 9
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate64 >> selector [
	^memory unsignedLong64At: address + 25 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate64 >> selector: aValue [
	^memory
		unsignedLong64At: address + baseHeaderSize + 25
		put: aValue
]
