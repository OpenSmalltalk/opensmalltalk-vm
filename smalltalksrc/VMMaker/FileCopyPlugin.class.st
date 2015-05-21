"
This plugin is a simple workaround for the lamentable state of the Squeak file handling system; it provides a primitive to copy a file or tree via the OS facility and thus preserve all the OS attributes in the most trivial possible manner. Not intended for a long life and should be replaced by better code as soon as possible. The key benefit it offers is maintenance of any OS flags, tags, bits and bobs belonging to the file.  Since it requires platform support it will only be built when supported on your platform
"
Class {
	#name : #FileCopyPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
FileCopyPlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #'system primitives' }
FileCopyPlugin >> primitiveFile: srcName copyTo: dstName [

	|srcSz dstSz ok |
	self primitive: 'primitiveFileCopyNamedTo'
		parameters: #(String String).

	srcSz := interpreterProxy slotSizeOf: srcName cPtrAsOop.
	dstSz := interpreterProxy slotSizeOf: dstName cPtrAsOop.
	ok := self sqCopyFile: srcName size: srcSz to: dstName size: dstSz.
	ok ifFalse:[interpreterProxy primitiveFail].

]
