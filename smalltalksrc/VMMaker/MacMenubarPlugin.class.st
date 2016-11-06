Class {
	#name : #MacMenubarPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
MacMenubarPlugin class >> hasHeaderFile [
	^true
]

{ #category : #translation }
MacMenubarPlugin class >> requiresCrossPlatformFiles [
	^false
]

{ #category : #translation }
MacMenubarPlugin class >> requiresPlatformFiles [
	^true
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveAppendMenu: menuHandleOop data: str255 [
	<var: #menuHandle type: #MenuHandle>
	<var: #constStr255 type: #ConstStr255Param>
	| menuHandle constStr255 |
	self primitive: 'primitiveAppendMenu'
		parameters: #(Oop ByteArray).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	constStr255 := self cCoerce: str255 to: #ConstStr255Param.	
	self cCode: 'AppendMenu(menuHandle,constStr255)' inSmalltalk:[menuHandle].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveAppendMenuItemText: menuHandleOop data: str255 [
	<var: #menuHandle type: #MenuHandle>
	<var: #constStr255 type: #ConstStr255Param>
	| menuHandle constStr255 |
	self primitive: 'primitiveAppendMenuItemText'
		parameters: #(Oop ByteArray).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	constStr255 := self cCoerce: str255 to: #ConstStr255Param.	
	self cCode: 'AppendMenuItemText(menuHandle,constStr255)' inSmalltalk:[menuHandle].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveCheckMenuItem: menuHandleOop item: anInteger checked: aBoolean [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveCheckMenuItem'
		parameters: #(Oop SmallInteger Boolean).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'CheckMenuItem(menuHandle,anInteger,aBoolean)' inSmalltalk:[menuHandle].
	^nil


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveClearMenuBar [ 
	self primitive: 'primitiveClearMenuBar'
		parameters: #().
	
	self cCode: 'ClearMenuBar()' inSmalltalk:[].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveCountMenuItems: menuHandleOop [ 
	<var: #menuHandle type: #MenuHandle>
	| menuHandle returnValue |
	self primitive: 'primitiveCountMenuItems'
		parameters: #(Oop).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	returnValue := self cCode: 'CountMenuItems(menuHandle)' inSmalltalk:[0].
	^returnValue asSmallIntegerObj

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveCreateStandardWindowMenu: inOptions [ 
	<var: #menuHandle type: #MenuHandle>
	| menuHandle result |
	self primitive: 'primitiveCreateStandardWindowMenu'
		parameters: #(SmallInteger).
	self cppIf: #'TARGET_API_MAC_CARBON'
		ifTrue: [result := self cCode: 'CreateStandardWindowMenu(inOptions,&menuHandle);' inSmalltalk:[0]].
	^interpreterProxy positiveMachineIntegerFor: (self cCoerce: menuHandle to: #'usqIntptr_t')
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveDeleteMenu: menuID [ 
	<var: #menuID type: #MenuID>
	self primitive: 'primitiveDeleteMenu'
		parameters: #(SmallInteger).
	self cCode: 'DeleteMenu(menuID)' inSmalltalk:[].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveDeleteMenuItem: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveDeleteMenuItem'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'DeleteMenuItem(menuHandle,anInteger)' inSmalltalk:[menuHandle].
	^nil

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveDisableMenuCommand: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	<var: #commandID type: #MenuCommand>
	| menuHandle commandID |
	self primitive: 'primitiveDisableMenuCommand'
		parameters: #(Oop Oop).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	commandID := self cCoerce: (interpreterProxy positive32BitValueOf: anInteger) to: #MenuCommand.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cppIf: #'TARGET_API_MAC_CARBON'
		ifTrue: [self cCode: 'DisableMenuCommand(menuHandle,commandID);' inSmalltalk: [menuHandle]].
	^nil

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveDisableMenuItem: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveDisableMenuItem'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'DisableMenuItem(menuHandle,anInteger)' inSmalltalk:[menuHandle].
	^nil

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveDisableMenuItemIcon: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveDisableMenuItemIcon'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'DisableMenuItemIcon(menuHandle,anInteger)' inSmalltalk:[menuHandle].
	^nil

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveDisposeMenu: menuHandleOop [ 
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveDisposeMenu'
		parameters: #(Oop).	
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'DisposeMenu(menuHandle)' inSmalltalk:[menuHandle].
	^nil

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveDisposeMenuBar: menuHandleOop [ 
	<var: #menuBarHandle type: #Handle>
	| menuBarHandle |
	self primitive: 'primitiveDisposeMenuBar'
		parameters: #(Oop).
	menuBarHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #Handle.
	self cppIf: #'TARGET_API_MAC_CARBON'
		ifTrue: [self cCode: 'DisposeMenuBar(menuBarHandle);' inSmalltalk: [menuBarHandle]]
		ifFalse: [self cCode: 'DisposeHandle(menuBarHandle);' inSmalltalk: [menuBarHandle]].
	^nil

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveDrawMenuBar [
	self primitive: 'primitiveDrawMenuBar'
		parameters: #().
	
	self cCode: 'DrawMenuBar()' inSmalltalk:[].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveEnableMenuCommand: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	<var: #commandID type: #MenuCommand>
	| menuHandle commandID |
	self primitive: 'primitiveEnableMenuCommand'
		parameters: #(Oop Oop).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	commandID := self cCoerce: (interpreterProxy positive32BitValueOf: anInteger) to: #MenuCommand.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cppIf: #'TARGET_API_MAC_CARBON'
		ifTrue: [self cCode: 'EnableMenuCommand(menuHandle,commandID);' inSmalltalk: [menuHandle]].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveEnableMenuItem: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveEnableMenuItem'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'EnableMenuItem(menuHandle,anInteger)' inSmalltalk:[menuHandle].
	^nil

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveEnableMenuItemIcon: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveEnableMenuItemIcon'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'EnableMenuItemIcon(menuHandle,anInteger)' inSmalltalk:[menuHandle].
	^nil

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetIndMenuItemWithCommandID: menuHandleOop commandID: aCommandID [
	<var: #menuHandle type: #MenuHandle>
	<var: #commandID type: #MenuCommand>
	<var: #applicationMenu type: #MenuHandle>
	<var: #outIndex type: #MenuItemIndex>
	| menuHandle commandID applicationMenu outIndex |
	self primitive: 'primitiveGetIndMenuItemWithCommandID'
		parameters: #(Oop Oop).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	commandID := self cCoerce: (interpreterProxy positive32BitValueOf: aCommandID) to: #MenuCommand.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cppIf: #'TARGET_API_MAC_CARBON'
		ifTrue: [self cCode: 'GetIndMenuItemWithCommandID(menuHandle, kHICommandHide, 1,
                   &applicationMenu, &outIndex);' inSmalltalk: [menuHandle]].
	^outIndex asSmallIntegerObj

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetIndMenuWithCommandID: menuHandleOop commandID: aCommandID [
	<var: #menuHandle type: #MenuHandle>
	<var: #commandID type: #MenuCommand>
	<var: #applicationMenu type: #MenuHandle>
	<var: #outIndex type: #MenuItemIndex>
	| menuHandle commandID applicationMenu outIndex |
	self primitive: 'primitiveGetIndMenuWithCommandID'
		parameters: #(Oop Oop).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: 'MenuHandle'.
	commandID := self cCoerce: (interpreterProxy positive32BitValueOf: aCommandID) to: 'MenuCommand'.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cppIf: #'TARGET_API_MAC_CARBON'
		ifTrue: [self cCode: 'GetIndMenuItemWithCommandID(menuHandle, kHICommandHide, 1,
                   &applicationMenu, &outIndex);' inSmalltalk: [menuHandle]].
	outIndex asSmallIntegerObj. "to avoid elimination of the variable..."
	^interpreterProxy positiveMachineIntegerFor: (self cCoerce: applicationMenu to: #'usqIntptr_t')


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetItemCmd: menuHandleOop item: anInteger [
	| menuHandle aCharacter |
	<var: #menuHandle type: #MenuHandle>
	<var: #aCharacter type: #CharParameter>
	self primitive: 'primitiveGetItemCmd'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	aCharacter := 0.
	self cCode: 'GetItemCmd(menuHandle,anInteger,&aCharacter)' inSmalltalk:[menuHandle].
	^aCharacter asSmallIntegerObj


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetItemIcon: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	<var: #iconIndex type: #short>
	| menuHandle iconIndex |
	self primitive: 'primitiveGetItemIcon'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	iconIndex := 0.
	self cCode: 'GetItemIcon(menuHandle,anInteger,&iconIndex)' inSmalltalk:[menuHandle].
	^iconIndex asSmallIntegerObj

]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetItemMark: menuHandleOop item: anInteger [
	| menuHandle aCharacter |
	<var: #menuHandle type: #MenuHandle>
	<var: #aCharacter type: #CharParameter>
	self primitive: 'primitiveGetItemMark'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	aCharacter := 0.
	self cCode: 'GetItemMark(menuHandle,anInteger,&aCharacter)' inSmalltalk:[menuHandle].
	^aCharacter asSmallIntegerObj


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetItemStyle: menuHandleOop item: anInteger [ 
	<var: #menuHandle type: #MenuHandle>
	<var: #chStyle type: #Style>
	| menuHandle chStyle |
	self primitive: 'primitiveGetItemStyle'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	chStyle := 0.
	self cCode: 'GetItemStyle(menuHandle,anInteger,&chStyle)' inSmalltalk:[menuHandle].
	^chStyle asSmallIntegerObj


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuBar [ 
	<var: #menuHandle type: #Handle>
	| menuHandle |
	self primitive: 'primitiveGetMenuBar'
		parameters: #().
	menuHandle := self cCode: 'GetMenuBar()' inSmalltalk:[0].
	^interpreterProxy positiveMachineIntegerFor: (self cCoerce: menuHandle to: #'usqIntptr_t')
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuHandle: menuID [ 
	<var: #menuHandle type: #MenuHandle>
	<var: #menuID type: #MenuID>
	| menuHandle |
	self primitive: 'primitiveGetMenuHandle'
		parameters: #(SmallInteger).
	menuHandle := self cCode: 'GetMenuHandle(menuID)' inSmalltalk:[0].
	^interpreterProxy positiveMachineIntegerFor: (self cCoerce: menuHandle to: #'usqIntptr_t')
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuID: menuHandleOop [ 
	<var: #menuHandle type: #MenuHandle>
	<var: #menuID type: #MenuID>
	| menuHandle menuID |
	self primitive: 'primitiveGetMenuID'
		parameters: #(Oop ).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'menuID = GetMenuID(menuHandle)' inSmalltalk:[menuHandle].
	^menuID asSmallIntegerObj
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuItemCommandID: menuHandleOop item: anInteger [ 
	<var: #menuHandle type: #MenuHandle>
	<var: #outCommandID type: #MenuCommand>
	| menuHandle outCommandID |
	self primitive: 'primitiveGetMenuItemCommandID'
		parameters: #(Oop SmallInteger).
	outCommandID := 0.
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'GetMenuItemCommandID(menuHandle,anInteger,&outCommandID)' inSmalltalk:[menuHandle].
	^interpreterProxy positive32BitIntegerFor: outCommandID
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuItemFontID: menuHandleOop item: anInteger [ 
	<var: #menuHandle type: #MenuHandle>
	<var: #outFontID type: #SInt16>
	| menuHandle outFontID |
	self primitive: 'primitiveGetMenuItemFontID'
		parameters: #(Oop SmallInteger).
	outFontID := 0.
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'GetMenuItemFontID(menuHandle,anInteger,&outFontID)' inSmalltalk:[menuHandle].
	^outFontID asSmallIntegerObj
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuItemHierarchicalID: menuHandleOop item: anInteger [ 
	<var: #menuHandle type: #MenuHandle>
	<var: #outHierID type: #MenuID>
	| menuHandle outHierID |
	self primitive: 'primitiveGetMenuItemHierarchicalID'
		parameters: #(Oop SmallInteger ).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	outHierID := 0.
	self cCode: 'GetMenuItemHierarchicalID(menuHandle,anInteger,&outHierID)' inSmalltalk:[menuHandle].
	^outHierID asSmallIntegerObj


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuItemKeyGlyph: menuHandleOop item: anInteger [ 
	<var: #menuHandle type: #MenuHandle>
	<var: #outGlyph type: #SInt16>
	| menuHandle outGlyph |
	self primitive: 'primitiveGetMenuItemKeyGlyph'
		parameters: #(Oop SmallInteger).
	outGlyph := 0.
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'GetMenuItemKeyGlyph(menuHandle,anInteger,&outGlyph)' inSmalltalk:[menuHandle].
	^interpreterProxy positive32BitIntegerFor: outGlyph
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuItemModifiers: menuHandleOop item: anInteger [ 
	<var: #menuHandle type: #MenuHandle>
	<var: #outModifers type: #Style>
	| menuHandle outModifers |
	self primitive: 'primitiveGetMenuItemModifiers'
		parameters: #(Oop SmallInteger ).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	outModifers := 0.
	self cCode: 'GetMenuItemModifiers(menuHandle,anInteger,&outModifers)' inSmalltalk:[menuHandle].
	^outModifers asSmallIntegerObj
	


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuItemText: menuHandleOop item: anInteger [
	| menuHandle size oop ptr aString |
	<var: #menuHandle type: #MenuHandle>
	<var: #aString type: #Str255>
	<var: #ptr type: 'char *'>
	self primitive: 'primitiveGetMenuItemText'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	aString at: 0 put: 0.
	self cCode: 'GetMenuItemText(menuHandle,anInteger,aString)' inSmalltalk:[menuHandle].
	size := self cCode: 'aString[0]' inSmalltalk: [0].
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize:  size.
	ptr := interpreterProxy firstIndexableField: oop.
	0 to: size-1 do:[:i|
		ptr at: i put: (aString at: (i+1))].
	^oop


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuItemTextEncoding: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	<var: #outScriptID type: #TextEncoding>
	| menuHandle outScriptID |
	self primitive: 'primitiveGetMenuItemTextEncoding'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'GetMenuItemTextEncoding(menuHandle,anInteger,&outScriptID)' inSmalltalk:[menuHandle].
	^interpreterProxy positive32BitIntegerFor: outScriptID
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveGetMenuTitle: menuHandleOop [
	| menuHandle size oop ptr aString |
	<var: #menuHandle type: #MenuHandle>
	<var: #aString type: #Str255>
	<var: #ptr type: 'char *'>
	self primitive: 'primitiveGetMenuTitle'
		parameters: #(Oop).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	aString at: 0 put: 0.
	self cCode: 'GetMenuTitle(menuHandle,aString)' inSmalltalk:[menuHandle].
	size := self cCode: 'aString[0]' inSmalltalk: [0].
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize:  size.
	ptr := interpreterProxy firstIndexableField: oop.
	0 to: size-1 do:[:i|
		ptr at: i put: (aString at: (i+1))].
	^oop


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveHideMenuBar [ 
	self primitive: 'primitiveHideMenuBar'
		parameters: #().
	
	self cCode: 'HideMenuBar()' inSmalltalk:[].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveHiliteMenu: menuID [ 
	<var: #menuID type: #MenuID>
	self primitive: 'primitiveHiliteMenu'
		parameters: #(SmallInteger).
	self cCode: 'HiliteMenu(menuID)' inSmalltalk:[].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveInsertFontResMenu: menuHandleOop afterItem: afterItemInteger scriptFilter:  scriptFilterInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveInsertFontResMenu'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'InsertFontResMenu(menuHandle,afterItemInteger,scriptFilterInteger)' inSmalltalk:[menuHandle].
	^nil
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveInsertIntlResMenu: menuHandleOop theType: aResType afterItem: afterItemInteger scriptFilter:  scriptFilterInteger [
	<var: #menuHandle type: #MenuHandle>
	<var: #resType type: #ResType>
	| menuHandle resType |
	self primitive: 'primitiveInsertIntlResMenu'
		parameters: #(Oop SmallInteger SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	resType := self cCoerce: (interpreterProxy positive32BitValueOf: aResType) to: #ResType.
	self cCode: 'InsertIntlResMenu(menuHandle,resType,afterItemInteger,scriptFilterInteger)' inSmalltalk:[menuHandle].
	^nil
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveInsertMenu: menuHandleOop beforeID: anInteger [
	<var: #menuHandle type: #MenuHandle>
	<var: #anInteger type: #MenuID>
	| menuHandle |
	self primitive: 'primitiveInsertMenu'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'InsertMenu(menuHandle,anInteger)' inSmalltalk:[menuHandle].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveInsertMenuItem: menuHandleOop itemString: str255 afterItem: anInteger [
	<var: #menuHandle type: #MenuHandle>
	<var: #constStr255 type: #ConstStr255Param>
	| menuHandle constStr255 |
	self primitive: 'primitiveInsertMenuItem'
		parameters: #(Oop ByteArray SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	constStr255 := self cCoerce: str255 to: #ConstStr255Param.
	self cCode: 'InsertMenuItem(menuHandle,constStr255,anInteger)' inSmalltalk:[menuHandle].
	^nil
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveInvalMenuBar [
	self primitive: 'primitiveInvalMenuBar'
		parameters: #().
	
	self cCode: 'InvalMenuBar()' inSmalltalk:[].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveIsMenuBarVisible [
	| result |
	self primitive: 'primitiveIsMenuBarVisible'
		parameters: #().
	result := self cCode: 'IsMenuBarVisible()' inSmalltalk:[true].
	^result asOop: Boolean
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveIsMenuItemEnabled: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle result |
	self primitive: 'primitiveIsMenuItemEnabled'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	result := self cCode: 'IsMenuItemEnabled(menuHandle,anInteger)' inSmalltalk:[0].
	^result asOop: Boolean
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveIsMenuItemIconEnabled: menuHandleOop item: anInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle result |
	self primitive: 'primitiveIsMenuItemIconEnabled'
		parameters: #(Oop SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	result := self cCode: 'IsMenuItemIconEnabled(menuHandle,anInteger)' inSmalltalk:[0].
	^result asOop: Boolean
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveNewMenu: menuID menuTitle: menuTitle [
	<var: #menuHandle type: #MenuHandle>
	<var: #constStr255 type: #ConstStr255Param>
	<var: #menuID type: #MenuID>
	| menuHandle constStr255 |
	self primitive: 'primitiveNewMenu'
		parameters: #(SmallInteger ByteArray).
	constStr255 := self cCoerce: menuTitle to: #ConstStr255Param.	
	menuHandle := self cCode: 'NewMenu(menuID,constStr255)' inSmalltalk:[0].
	^interpreterProxy positiveMachineIntegerFor: (self cCoerce: menuHandle to: #'usqIntptr_t')
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetItemCmd: menuHandleOop item: anInteger cmdChar: anIntegerCmdChar [
	<var: #menuHandle type: #MenuHandle>
	<var: #aCharacter type: #CharParameter>
	| menuHandle aCharacter |
	self primitive: 'primitiveSetItemCmd'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	aCharacter := anIntegerCmdChar.
	self cCode: 'SetItemCmd(menuHandle,anInteger,aCharacter)' inSmalltalk:[menuHandle].
	^nil


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetItemIcon: menuHandleOop item: anInteger iconIndex: aIconIndexInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveSetItemIcon'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'SetItemIcon(menuHandle,anInteger,aIconIndexInteger)' inSmalltalk:[menuHandle].
	^nil


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetItemMark: menuHandleOop item: anInteger markChar: aMarkChar [
	<var: #menuHandle type: #MenuHandle>
	<var: #aCharacter type: #CharParameter>
	| menuHandle aCharacter |
	self primitive: 'primitiveSetItemMark'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	aCharacter := aMarkChar.
	self cCode: 'SetItemMark(menuHandle,anInteger,aCharacter)' inSmalltalk:[menuHandle].
	^nil


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetItemStyle: menuHandleOop item: anInteger styleParameter: chStyleInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveSetItemStyle'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'SetItemStyle(menuHandle,anInteger,chStyleInteger)' inSmalltalk:[menuHandle].
	^nil


]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuBar: menuHandleOop [
	<var: #menuBarHandle type: #MenuBarHandle>
	| menuBarHandle |
	self primitive: 'primitiveSetMenuBar'
		parameters: #(Oop).
	menuBarHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuBarHandle.
	self cCode: 'SetMenuBar(menuBarHandle)' inSmalltalk:[menuBarHandle].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuItemCommandID: menuHandleOop item: anInteger menuCommand:  inCommandID [
	<var: #menuHandle type: #MenuHandle>
	<var: #commandID type: #MenuCommand>
	| menuHandle commandID |
	self primitive: 'primitiveSetMenuItemCommandID'
		parameters: #(Oop SmallInteger Oop).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	commandID := self cCoerce: (interpreterProxy positive32BitValueOf: inCommandID) to: #MenuCommand.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'SetMenuItemCommandID(menuHandle,anInteger,commandID)' inSmalltalk:[menuHandle].
	^nil
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuItemFontID: menuHandleOop item: anInteger fontID: aFontIDInteger [  
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveSetMenuItemFontID'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'SetMenuItemFontID(menuHandle,anInteger,aFontIDInteger)' inSmalltalk:[menuHandle].
	^nil
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuItemHierarchicalID: menuHandleOop item: anInteger hierID: aMenuID [
	<var: #menuHandle type: #MenuHandle>
	<var: #aMenuID type: #MenuID>
	| menuHandle |
	self primitive: 'primitiveSetMenuItemHierarchicalID'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'SetMenuItemHierarchicalID(menuHandle,anInteger,aMenuID)' inSmalltalk:[menuHandle].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuItemKeyGlyph: menuHandleOop item: anInteger glyph:  inGlyphInteger [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveSetMenuItemKeyGlyph'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'SetMenuItemKeyGlyph(menuHandle,anInteger,inGlyphInteger)' inSmalltalk:[menuHandle].
	^nil
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuItemModifiers: menuHandleOop item: anInteger inModifiers: aUInt8 [
	<var: #menuHandle type: #MenuHandle>
	| menuHandle |
	self primitive: 'primitiveSetMenuItemModifiers'
		parameters: #(Oop SmallInteger SmallInteger).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	self cCode: 'SetMenuItemModifiers(menuHandle,anInteger,aUInt8)' inSmalltalk:[menuHandle].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuItemText: menuHandleOop item: anInteger itemString: str255 [
	<var: #menuHandle type: #MenuHandle>
	<var: #constStr255 type: #ConstStr255Param>
	| menuHandle constStr255 |
	self primitive: 'primitiveSetMenuItemText'
		parameters: #(Oop SmallInteger ByteArray).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	constStr255 := self cCoerce: str255 to: #ConstStr255Param.
	self cCode: 'SetMenuItemText(menuHandle,anInteger,constStr255)' inSmalltalk:[menuHandle].
	^nil
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuItemTextEncoding: menuHandleOop item: anInteger inScriptID: aTextEncodingOop [
	<var: #menuHandle type: #MenuHandle>
	<var: #inScriptID type: #TextEncoding>
	| menuHandle inScriptID |
	self primitive: 'primitiveSetMenuItemTextEncoding'
		parameters: #(Oop SmallInteger Oop).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	inScriptID := self cCoerce: (interpreterProxy positive32BitValueOf: aTextEncodingOop) to: #TextEncoding.
	self cCode: 'SetMenuItemTextEncoding(menuHandle,anInteger,inScriptID)' inSmalltalk:[menuHandle].
	^nil
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveSetMenuTitle: menuHandleOop  title: str255 [
	<var: #menuHandle type: #MenuHandle>
	<var: #constStr255 type: #ConstStr255Param>
	| menuHandle constStr255 |
	self primitive: 'primitiveSetMenuTitle'
		parameters: #(Oop ByteArray).
	menuHandle := self cCoerce: (interpreterProxy positiveMachineIntegerValueOf: menuHandleOop) to: #MenuHandle.
	(self ioCheckMenuHandle: menuHandle) ifFalse: [^interpreterProxy success: false].
	constStr255 := self cCoerce: str255 to: #ConstStr255Param.
	self cCode: 'SetMenuTitle(menuHandle,constStr255)' inSmalltalk:[menuHandle].
	^nil
	
]

{ #category : #'system primitives' }
MacMenubarPlugin >> primitiveShowMenuBar [ 
	self primitive: 'primitiveShowMenuBar'
		parameters: #().
	
	self cCode: 'ShowMenuBar()' inSmalltalk:[].
	^nil
]
