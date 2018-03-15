Class {
	#name : #NSSendCacheSurrogate64,
	#superclass : #NSSendCacheSurrogate,
	#category : 'VMMaker-JITSimulation'
}

{ #category : #accessing }
NSSendCacheSurrogate64 class >> alignedByteSize [
	^48
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> classTag [
	^memory unsignedLong64At: address + 1
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> classTag: aValue [
	^memory
		unsignedLong64At: address + 1
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> depth [
	^memory unsignedLong64At: address + 41
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> depth: aValue [
	^memory
		unsignedLong64At: address + 41
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> enclosingObject [
	^memory unsignedLong64At: address + 9
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> enclosingObject: aValue [
	^memory
		unsignedLong64At: address + 9
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> numArgs [
	^memory unsignedLong64At: address + 33
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> numArgs: aValue [
	^memory
		unsignedLong64At: address + 33
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> selector [
	^memory unsignedLong64At: address + 25
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> selector: aValue [
	^memory
		unsignedLong64At: address + 25
		put: aValue
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> target [
	^memory unsignedLong64At: address + 17
]

{ #category : #accessing }
NSSendCacheSurrogate64 >> target: aValue [
	^memory
		unsignedLong64At: address + 17
		put: aValue
]
