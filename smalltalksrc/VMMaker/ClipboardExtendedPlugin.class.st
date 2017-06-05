Class {
	#name : #ClipboardExtendedPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #io }
ClipboardExtendedPlugin >> ioAddClipboardData: clipboard data: data dataFormat: aFormat [
	| clipboardAddress formatLength dataLength |
	<var: #clipboardAddress type: #'usqIntptr_t'>
	self primitive: 'ioAddClipboardData' parameters: #(Oop ByteArray String).

	clipboardAddress := interpreterProxy positiveMachineIntegerValueOf: clipboard.
	dataLength := interpreterProxy slotSizeOf: data cPtrAsOop.
	formatLength := interpreterProxy slotSizeOf: aFormat cPtrAsOop.

	self sqPasteboardPutItemFlavor: clipboardAddress data: data length: dataLength formatType: aFormat formatLength: formatLength.

]

{ #category : #io }
ClipboardExtendedPlugin >> ioClearClipboard: clipboard [
	| clipboardAddress |
	<var: #clipboardAddress type: #'usqIntptr_t'>
	self primitive: 'ioClearClipboard' parameters: #(Oop).
	clipboardAddress :=  interpreterProxy positiveMachineIntegerValueOf: clipboard.
	self sqPasteboardClear: clipboardAddress.
]

{ #category : #io }
ClipboardExtendedPlugin >> ioCreateClipboard [
	| clipboardAddress |
	self primitive: 'ioCreateClipboard' parameters: #().

	clipboardAddress := interpreterProxy positiveMachineIntegerFor: self sqCreateClipboard.

	^ clipboardAddress.
]

{ #category : #io }
ClipboardExtendedPlugin >> ioGetClipboardFormat: clipboard formatNumber: formatNumber [ 
	| clipboardAddress itemCount |
	<var: #clipboardAddress type: #'usqIntptr_t'>
	self primitive: 'ioGetClipboardFormat' parameters: #(#Oop #SmallInteger ).
	clipboardAddress := interpreterProxy positiveMachineIntegerValueOf: clipboard.
	itemCount := self sqPasteboardGetItemCount: clipboardAddress.
	itemCount > 0
		ifTrue: [^ self sqPasteboardCopyItemFlavors: clipboardAddress itemNumber: formatNumber].
	^ interpreterProxy nilObject
]

{ #category : #io }
ClipboardExtendedPlugin >> ioReadClipboardData: clipboard format: format [
	| clipboardAddress formatLength |
	<var: #clipboardAddress type: #'usqIntptr_t'>
	self primitive: 'ioReadClipboardData' parameters: #(Oop String).
	clipboardAddress := interpreterProxy positiveMachineIntegerValueOf: clipboard.
	formatLength := interpreterProxy slotSizeOf: format cPtrAsOop.
	^ self sqPasteboardCopyItemFlavorData: clipboardAddress format: format formatLength: formatLength.

]
