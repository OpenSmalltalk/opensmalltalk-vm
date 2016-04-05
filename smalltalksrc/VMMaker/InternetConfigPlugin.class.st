"
This plugin provides access to the Mac's internet configuration toolkit - so long as you are running on a Mac.
"
Class {
	#name : #InternetConfigPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
InternetConfigPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
InternetConfigPlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #initialize }
InternetConfigPlugin >> initialiseModule [
	<export: true>
	^self cCode: 'sqInternetConfigurationInit()' inSmalltalk:[true]
]

{ #category : #'system primitives' }
InternetConfigPlugin >> primitiveGetMacintoshFileTypeAndCreatorFrom: aFileName [
	| oop ptr keyLength creator |

	<var: #creator declareC: 'char creator[8]'>
	<var: #ptr type: 'char *'>
	self primitive: 'primitiveGetMacintoshFileTypeAndCreatorFrom'
		parameters: #(String).

	keyLength := interpreterProxy byteSizeOf: aFileName cPtrAsOop.
	self sqInternetGetMacintoshFileTypeAndCreatorFrom: aFileName keySize: keyLength into: creator.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: 8.
	ptr := interpreterProxy firstIndexableField: oop.
	0 to: 7 do:[:i|
		ptr at: i put: (creator at: i)].
	^oop.

]

{ #category : #'system primitives' }
InternetConfigPlugin >> primitiveGetStringKeyedBy: aKey [
	| oop ptr size aString keyLength |

	<var: #aString declareC: 'char aString[1025]'>
	<var: #ptr type: 'char *'>
	self primitive: 'primitiveGetStringKeyedBy'
		parameters: #(String).
	
	keyLength := interpreterProxy byteSizeOf: aKey cPtrAsOop.
	size := self sqInternetConfigurationGetStringKeyedBy: aKey keySize: keyLength into: aString.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: size.
	ptr := interpreterProxy firstIndexableField: oop.
	0 to: size-1 do:[:i|
		ptr at: i put: (aString at: i)].
	^oop.

]

{ #category : #initialize }
InternetConfigPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'sqInternetConfigurationShutdown()' inSmalltalk:[true]
]
