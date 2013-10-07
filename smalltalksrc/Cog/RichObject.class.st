"
This class mostly adds some constants that are used in the Richards benchmarks.
"
Class {
	#name : #RichObject,
	#superclass : #Object,
	#classVars : [
		'DeviceA',
		'DeviceB',
		'DevicePacketKind',
		'HandlerA',
		'HandlerB',
		'Idler',
		'WorkPacketKind',
		'Worker'
	],
	#category : #'Cog-Benchmarks-Richards'
}

{ #category : #initialize }
RichObject class >> initialize [
	super initialize.
    	DeviceA := 5.
    	DeviceB := 6.
    	DevicePacketKind := 1.
    	HandlerA := 3.
    	HandlerB := 4.
    	Idler := 1.
    	Worker := 2.
    	WorkPacketKind := 2
]

{ #category : #utilities }
RichObject >> append: packet head: queueHead [
    | mouse link |
    packet link: nil.
    queueHead ifNil: [ ^ packet ].
    mouse := queueHead.
    [ (link := mouse link) isNil]
	whileFalse: [ mouse := link ].
    mouse link: packet.
    ^ queueHead
]
