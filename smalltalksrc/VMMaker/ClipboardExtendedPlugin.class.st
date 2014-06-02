Class {
	#name : #ClipboardExtendedPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #io }
ClipboardExtendedPlugin >> ioAddClipboardData: clipboard data: data dataFormat: aFormat [
| clipboardAddress formatLength dataLength |
self primitive: 'ioAddClipboardData' parameters: #(Oop ByteArray String).

clipboardAddress := interpreterProxy positive32BitValueOf: clipboard.

dataLength := interpreterProxy slotSizeOf: data cPtrAsOop.
formatLength := interpreterProxy slotSizeOf: aFormat cPtrAsOop.

self sqPasteboardPutItemFlavor: clipboardAddress data: data length: dataLength formatType: aFormat formatLength: formatLength.

]

{ #category : #io }
ClipboardExtendedPlugin >> ioClearClipboard: clipboard [
| clipboardAddress |
self primitive: 'ioClearClipboard' parameters: #(Oop).
clipboardAddress :=  interpreterProxy positive32BitValueOf: clipboard.
self sqPasteboardClear: clipboardAddress.
]

{ #category : #io }
ClipboardExtendedPlugin >> ioCreateClipboard [
| clipboardAddress |
self primitive: 'ioCreateClipboard' parameters: #().

clipboardAddress := interpreterProxy positive32BitIntegerFor: self sqCreateClipboard.

^ clipboardAddress.
]

{ #category : #io }
ClipboardExtendedPlugin >> ioGetClipboardFormat: clipboard formatNumber: formatNumber [ 
	| clipboardAddress itemCount |
	self primitive: 'ioGetClipboardFormat' parameters: #(#Oop #SmallInteger ).
	clipboardAddress := interpreterProxy positive32BitValueOf: clipboard.
	itemCount := self sqPasteboardGetItemCount: clipboardAddress.
	itemCount > 0
		ifTrue: [^ self sqPasteboardCopyItemFlavors: clipboardAddress itemNumber: formatNumber].
	^ interpreterProxy nilObject
]

{ #category : #io }
ClipboardExtendedPlugin >> ioReadClipboardData: clipboard format: format [
| clipboardAddress formatLength |
self primitive: 'ioReadClipboardData' parameters: #(Oop String).
clipboardAddress := interpreterProxy positive32BitValueOf: clipboard.
formatLength := interpreterProxy slotSizeOf: format cPtrAsOop.
^ self sqPasteboardCopyItemFlavorData: clipboardAddress format: format formatLength: formatLength.

]
