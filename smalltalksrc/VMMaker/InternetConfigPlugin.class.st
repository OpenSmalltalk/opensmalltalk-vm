"
This plugin provides access to the Mac's internet configuration toolkit - so long as you are running on a Mac.
"
Class {
	#name : #InternetConfigPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
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
	self export: true.
	^self cCode: 'sqInternetConfigurationInit()' inSmalltalk:[true]
]

{ #category : #'system primitives' }
InternetConfigPlugin >> primitiveGetMacintoshFileTypeAndCreatorFrom: aFileName [
	| oop ptr keyLength creator |

	self primitive: 'primitiveGetMacintoshFileTypeAndCreatorFrom'
		parameters: #(String).
	self var: #aFile declareC: 'char aFile[256]'.
	self var: #creator declareC: 'char creator[8]'.
	self var: #ptr type: 'char *'.
	
	keyLength _ interpreterProxy byteSizeOf: aFileName cPtrAsOop.
	self sqInternetGetMacintoshFileTypeAndCreatorFrom: aFileName keySize: keyLength into: creator.
	oop _ interpreterProxy instantiateClass: interpreterProxy classString indexableSize: 8.
	ptr _ interpreterProxy firstIndexableField: oop.
	0 to: 7 do:[:i|
		ptr at: i put: (creator at: i)].
	^oop.

]

{ #category : #'system primitives' }
InternetConfigPlugin >> primitiveGetStringKeyedBy: aKey [
	| oop ptr size aString keyLength |

	self primitive: 'primitiveGetStringKeyedBy'
		parameters: #(String).
	self var: #aString declareC: 'char aString[1025]'.
	self var: #ptr type: 'char *'.
	
	keyLength _ interpreterProxy byteSizeOf: aKey cPtrAsOop.
	size _ self sqInternetConfigurationGetStringKeyedBy: aKey keySize: keyLength into: aString.
	oop _ interpreterProxy instantiateClass: interpreterProxy classString indexableSize: size.
	ptr _ interpreterProxy firstIndexableField: oop.
	0 to: size-1 do:[:i|
		ptr at: i put: (aString at: i)].
	^oop.

]

{ #category : #initialize }
InternetConfigPlugin >> shutdownModule [
	self export: true.
	^self cCode: 'sqInternetConfigurationShutdown()' inSmalltalk:[true]
]
