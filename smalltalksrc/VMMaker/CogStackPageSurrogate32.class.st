"
Here's a doit to generate most of my code:
	| offset crtab |
	offset := 1.
	crtab := String with: Character cr with: Character tab.
	CogStackPage instVarNamesAndTypesForTranslationDo:
		[:name :type| | isByte |
		isByte := type = 'unsigned char'.
		CogStackPageSurrogate32
			compile: name, crtab, '^memory unsigned', (isByte ifTrue: ['ByteAt:'] ifFalse: ['LongAt:']), ' address + ', offset printString
			classified: #accessing.
		CogStackPageSurrogate32
			compile: name, ': aValue', crtab, '^memory unsigned', (isByte ifTrue: ['ByteAt:'] ifFalse: ['LongAt:']), ' address + ', offset printString,
					' put: aValue'
			classified: #accessing.
		offset := offset + (isByte ifTrue: [1] ifFalse: [4])].
	CogStackPageSurrogate32 class compile: 'alignedByteSize', crtab, '^', (offset - 1 + 3 bitAnd: -4) printString classified: #'instance creation'

"
Class {
	#name : #CogStackPageSurrogate32,
	#superclass : #CogStackPageSurrogate,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogStackPageSurrogate32 class >> alignedByteSize [
	^40
]

{ #category : #accessing }
CogStackPageSurrogate32 >> baseAddress [
	^memory unsignedLongAt: address + 17
]

{ #category : #accessing }
CogStackPageSurrogate32 >> baseAddress: aValue [
	self assert: (address + 16 >= zoneBase and: [address + 19 < zoneLimit]).
	^memory unsignedLongAt: address + 17 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> baseFP [
	^memory unsignedLongAt: address + 13
]

{ #category : #accessing }
CogStackPageSurrogate32 >> baseFP: aValue [
	self assert: (address + 12 >= zoneBase and: [address + 15 < zoneLimit]).
	^memory unsignedLongAt: address + 13 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> headFP [
	^memory unsignedLongAt: address + 9
]

{ #category : #accessing }
CogStackPageSurrogate32 >> headFP: aValue [
	self assert: (address + 8 >= zoneBase and: [address + 11 < zoneLimit]).
	^memory unsignedLongAt: address + 9 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> headSP [
	^memory unsignedLongAt: address + 5
]

{ #category : #accessing }
CogStackPageSurrogate32 >> headSP: aValue [
	self assert: (address + 4 >= zoneBase and: [address + 7 < zoneLimit]).
	^memory unsignedLongAt: address + 5 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> lastAddress [
	^memory unsignedLongAt: address + 25
]

{ #category : #accessing }
CogStackPageSurrogate32 >> lastAddress: aValue [
	self assert: (address + 24 >= zoneBase and: [address + 27 < zoneLimit]).
	^memory unsignedLongAt: address + 25 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> nextPage [
	^stackPages surrogateAtAddress: (memory unsignedLongAt: address + 33)
]

{ #category : #accessing }
CogStackPageSurrogate32 >> nextPage: aValue [
	self assert: (address + 32 >= zoneBase and: [address + 35 < zoneLimit]).
	memory unsignedLongAt: address + 33 put: aValue asInteger.
	^aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> padToWord [
	^memory longAt: address + 33
]

{ #category : #accessing }
CogStackPageSurrogate32 >> padToWord: aValue [
	self assert: (address + 32 >= zoneBase and: [address + 35 < zoneLimit]).
	^memory longAt: address + 33 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> prevPage [
	^stackPages surrogateAtAddress: (memory unsignedLongAt: address + 37)
]

{ #category : #accessing }
CogStackPageSurrogate32 >> prevPage: aValue [
	self assert: (address + 36 >= zoneBase and: [address + 39 < zoneLimit]).
	memory unsignedLongAt: address + 37 put: aValue asInteger.
	^aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> realStackLimit [
	^memory unsignedLongAt: address + 21
]

{ #category : #accessing }
CogStackPageSurrogate32 >> realStackLimit: aValue [
	self assert: (address + 20 >= zoneBase and: [address + 23 < zoneLimit]).
	^memory unsignedLongAt: address + 21 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> stackLimit [
	^memory unsignedLongAt: address + 1
]

{ #category : #accessing }
CogStackPageSurrogate32 >> stackLimit: aValue [
	self assert: (address + 0 >= zoneBase and: [address + 3 < zoneLimit]).
	^memory unsignedLongAt: address + 1 put: aValue
]

{ #category : #accessing }
CogStackPageSurrogate32 >> trace [
	^memory longAt: address + 29
]

{ #category : #accessing }
CogStackPageSurrogate32 >> trace: aValue [
	self assert: (address + 28 >= zoneBase and: [address + 31 < zoneLimit]).
	^memory longAt: address + 29 put: aValue
]
