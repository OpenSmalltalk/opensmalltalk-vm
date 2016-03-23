"
This class defines the necessary primitives for dropping files from the OS onto Squeak.

Implementation notes:
The drop support is really a two phase process. The first thing the OS code needs to do is to signal an event of type EventTypeDragDropFiles to Squeak. This event needs to include the following information (see sq.h for the definition of sqDragDropFilesEvent):
* dragType:
		DragEnter - dragging mouse entered Squeak window
		DragMove - dragging mouse moved within Squeak window
		DragLeave - dragging mouse left Squeak window
		DragDrop - dropped files onto Squeak window
* numFiles:
		The number of files in the drop operation.
* x, y, modifiers:
		Associated mouse state.

When these events are received, the primitives implemented by this plugin come into play. The two primitives can be used to either receive a list of file names or to receive a list of (read-only) file handles. Because drag and drop operations are intended to work in a restricted (plugin) environment, certain security precautions need to be taken:
* Access to the contents of the files (e.g., the file streams) must only be granted after a drop occured. Simply dragging the file over the Squeak window is not enough to grant access.
* Access to the contents of the files after a drop is allowed to bypass the file sandbox and create a read-only file stream directly.
* Access to the names of files can be granted even if the files are only dragged over Squeak (but not dropped). This is so that appropriate user feedback can be given.

If somehow possible, the support code should track the location of the drag-and-drop operation and generate appropriate DragMove type events. While not important right now, it will allow us to integrate OS DnD operations with Morphic DnD operation in a seemless manner.

"
Class {
	#name : #DropPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
DropPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
DropPlugin class >> requiresPlatformFiles [
	"default is ok for most, any plugin needing platform specific files must say so"
	^true
]

{ #category : #initialize }
DropPlugin >> initialiseModule [
	<export: true>
	^self cCode: 'dropInit()' inSmalltalk:[true]
]

{ #category : #primitives }
DropPlugin >> primitiveDropRequestFileHandle [
	"Note: File handle creation needs to be handled by specific support code explicitly bypassing the plugin file sand box."
	| dropIndex handleOop |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 1 
		ifFalse:[^interpreterProxy primitiveFail].
	dropIndex := interpreterProxy stackIntegerValue: 0.
	handleOop := self dropRequestFileHandle: dropIndex.
	"dropRequestFileHandle needs to return the actual oop returned"
	interpreterProxy failed ifFalse:[
		interpreterProxy pop: 2.
		interpreterProxy push: handleOop.
	].
]

{ #category : #primitives }
DropPlugin >> primitiveDropRequestFileName [
	"Note: File handle creation needs to be handled by specific support code explicitly bypassing the plugin file sand box."
	| dropIndex dropName nameLength nameOop namePtr |
	<export: true>
	<inline: false>
	<var: #dropName type: 'char *'>
	<var: #namePtr type: 'char *'>
	interpreterProxy methodArgumentCount = 1 
		ifFalse:[^interpreterProxy primitiveFail].
	dropIndex := interpreterProxy stackIntegerValue: 0.
	dropName := self dropRequestFileName: dropIndex.
	"dropRequestFileName returns name or NULL on error"
	dropName == nil 
		ifTrue:[^interpreterProxy primitiveFail].
	nameLength := self strlen: dropName.
	nameOop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: nameLength.
	namePtr := interpreterProxy firstIndexableField: nameOop.
	0 to: nameLength-1 do:[:i| namePtr at: i put: (dropName at: i)].
	interpreterProxy pop: 2.
	interpreterProxy push: nameOop.

]

{ #category : #primitives }
DropPlugin >> setFileAccessCallback: address [
	<export: true>
	^self sqSecFileAccessCallback: address asVoidPointer
]

{ #category : #initialize }
DropPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'dropShutdown()' inSmalltalk:[true]
]
