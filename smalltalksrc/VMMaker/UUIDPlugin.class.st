"
A class to generate UUID
by John M McIntosh johnmci@smalltalkconsulting.com, since it requires platform support it will only be built when supported on your platform.
See http://www.webdav.org/specs/draft-leach-uuids-guids-01.txt

If a plugin does not exist then we generate a UUID version 4 type GUUID in Smalltalk
"
Class {
	#name : #UUIDPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
UUIDPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
UUIDPlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #simulation }
UUIDPlugin class >> simulatorClass [
	^SmartSyntaxPluginSimulator
]

{ #category : #initialize }
UUIDPlugin >> initialiseModule [
	<export: true>
	^self cCode: 'sqUUIDInit()' inSmalltalk:[true]
]

{ #category : #'system primitives' }
UUIDPlugin >> primitiveMakeUUID [
	| oop location |
	<export: true>
	<var: #location type: 'char*'>
	oop := interpreterProxy stackObjectValue: 0.
	(interpreterProxy failed
	or: [interpreterProxy methodArgumentCount ~= 0
	or: [(interpreterProxy isBytes: oop) not
	or: [(interpreterProxy byteSizeOf: oop) ~= 16]]]) ifTrue:
		[^interpreterProxy primitiveFail].
	location := interpreterProxy firstIndexableField: oop.
	self cCode: [self MakeUUID: location]
		inSmalltalk:
			[| uuid |
			uuid := UUID new.
			1 to: 16 do:
				[:i| location at: i - 1 put: (uuid at: i)]].
	^oop
]

{ #category : #initialize }
UUIDPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'sqUUIDShutdown()' inSmalltalk:[true]
]
