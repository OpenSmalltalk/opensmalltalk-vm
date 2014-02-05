"
A simple package of data that is manipulated by the tasks.  The exact layout of the payload data carried by a packet is not importaint, and neither is the nature of the work performed on packets by the tasks. Besides carrying data, packets form linked lists and are hence used both as data and worklists.
"
Class {
	#name : #RichPacket,
	#superclass : #RichObject,
	#instVars : [
		'data',
		'datum',
		'identity',
		'kind',
		'link'
	],
	#category : #'Cog-Benchmarks-Richards'
}

{ #category : #'instance creation' }
RichPacket class >> create: link identity: identity kind: kind [ 
    ^ self new
		link: link
		identity: identity
		kind: kind
]

{ #category : #accessing }
RichPacket >> data [
	^ data
]

{ #category : #accessing }
RichPacket >> datum [
	^ datum
]

{ #category : #accessing }
RichPacket >> datum: anObject [
	datum := anObject
]

{ #category : #accessing }
RichPacket >> identity [
	^ identity
]

{ #category : #accessing }
RichPacket >> identity: anObject [
	identity := anObject
]

{ #category : #accessing }
RichPacket >> kind [
	^ kind
]

{ #category : #accessing }
RichPacket >> link [
	^ link
]

{ #category : #accessing }
RichPacket >> link: anObject [
	link := anObject
]

{ #category : #initialize }
RichPacket >> link: aLink identity: anIdentity kind: aKind [ 
    link := aLink.
    identity := anIdentity. 
    kind := aKind.
    datum := 1.
    data := ByteArray new: 4
]
