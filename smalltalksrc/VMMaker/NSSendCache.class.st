Class {
	#name : #NSSendCache,
	#superclass : #VMStructType,
	#instVars : [
		'classTag',
		'enclosingObject',
		'target',
		'selector',
		'numArgs',
		'depth'
	],
	#pools : [
		'CogMethodConstants',
		'VMBasicConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'class initialization' }
NSSendCache class >> initialize [
	"self initialize"
	(Smalltalk classNamed: #NSSendCacheSurrogate32) ifNotNil:
		[:scs32|
		self checkGenerateSurrogate: scs32 bytesPerWord: 4].
	(Smalltalk classNamed: #NSSendCacheSurrogate64) ifNotNil:
		[:scs64|
		self checkGenerateSurrogate: scs64 bytesPerWord: 8]
]

{ #category : #translation }
NSSendCache class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [

	self allInstVarNames do:
		[:ivn| aBinaryBlock
				value: ivn
				value: #'sqInt']
]

{ #category : #accessing }
NSSendCache >> classTag [

	^ classTag
]

{ #category : #accessing }
NSSendCache >> classTag: anObject [

	^classTag := anObject
]

{ #category : #accessing }
NSSendCache >> depth [

	^ depth
]

{ #category : #accessing }
NSSendCache >> depth: anObject [

	^depth := anObject
]

{ #category : #accessing }
NSSendCache >> enclosingObject [

	^ enclosingObject
]

{ #category : #accessing }
NSSendCache >> enclosingObject: anObject [

	^enclosingObject := anObject
]

{ #category : #accessing }
NSSendCache >> numArgs [

	^ numArgs
]

{ #category : #accessing }
NSSendCache >> numArgs: anObject [

	^numArgs := anObject
]

{ #category : #accessing }
NSSendCache >> selector [

	^ selector
]

{ #category : #accessing }
NSSendCache >> selector: anObject [

	^selector := anObject
]

{ #category : #accessing }
NSSendCache >> target [

	^ target
]

{ #category : #accessing }
NSSendCache >> target: anObject [

	^target := anObject
]
