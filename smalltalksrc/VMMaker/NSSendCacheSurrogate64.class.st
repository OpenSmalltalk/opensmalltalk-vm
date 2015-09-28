Class {
	#name : #NSSendCacheSurrogate64,
	#superclass : #NSSendCacheSurrogate,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
NSSendCacheSurrogate64 class >> alignedByteSize [
	^48
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> classTag [
	^memory unsignedLongLongAt: address + 1
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> classTag: aValue [
	^memory
		unsignedLongLongAt: address + 1
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> depth [
	^memory unsignedLongLongAt: address + 41
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> depth: aValue [
	^memory
		unsignedLongLongAt: address + 41
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> enclosingObject [
	^memory unsignedLongLongAt: address + 9
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> enclosingObject: aValue [
	^memory
		unsignedLongLongAt: address + 9
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> numArgs [
	^memory unsignedLongLongAt: address + 33
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> numArgs: aValue [
	^memory
		unsignedLongLongAt: address + 33
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> selector [
	^memory unsignedLongLongAt: address + 25
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> selector: aValue [
	^memory
		unsignedLongLongAt: address + 25
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> target [
	^memory unsignedLongLongAt: address + 17
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> target: aValue [
	^memory
		unsignedLongLongAt: address + 17
		put: aValue
]
