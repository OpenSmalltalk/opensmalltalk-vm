Class {
	#name : #ThreadedFFIX64SixteenByteReturn,
	#superclass : #VMStructType,
	#instVars : [
		'a',
		'b'
	],
	#category : 'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedFFIX64SixteenByteReturn class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a BlockStart struct."

	self instVarNames do:
		[:ivn|
		aBinaryBlock value: ivn value: #sqInt]
]

{ #category : #translation }
ThreadedFFIX64SixteenByteReturn class >> structTypeName [
	^'SixteenByteReturn'
]

{ #category : #accessing }
ThreadedFFIX64SixteenByteReturn >> a [

	^ a
]

{ #category : #accessing }
ThreadedFFIX64SixteenByteReturn >> a: anObject [

	^a := anObject
]

{ #category : #accessing }
ThreadedFFIX64SixteenByteReturn >> b [

	^ b
]

{ #category : #accessing }
ThreadedFFIX64SixteenByteReturn >> b: anObject [

	^b := anObject
]
