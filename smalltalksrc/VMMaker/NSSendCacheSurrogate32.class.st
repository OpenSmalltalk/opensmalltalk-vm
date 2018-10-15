Class {
	#name : #NSSendCacheSurrogate32,
	#superclass : #NSSendCacheSurrogate,
	#category : 'VMMaker-JITSimulation'
}

{ #category : #accessing }
NSSendCacheSurrogate32 class >> alignedByteSize [
	^24
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> classTag [
	^memory unsignedLongAt: address + 1
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> classTag: aValue [
	^memory
		unsignedLongAt: address + 1
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> depth [
	^memory unsignedLongAt: address + 21
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> depth: aValue [
	^memory
		unsignedLongAt: address + 21
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> enclosingObject [
	^memory unsignedLongAt: address + 5
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> enclosingObject: aValue [
	^memory
		unsignedLongAt: address + 5
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> numArgs [
	^memory unsignedLongAt: address + 17
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> numArgs: aValue [
	^memory
		unsignedLongAt: address + 17
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> selector [
	^memory unsignedLongAt: address + 13
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> selector: aValue [
	^memory
		unsignedLongAt: address + 13
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> target [
	^memory unsignedLongAt: address + 9
]

{ #category : #accessing }
NSSendCacheSurrogate32 >> target: aValue [
	^memory
		unsignedLongAt: address + 9
		put: aValue
]
