//
//  MacMenuOS9ToOSX.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-12-26.
//  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
//

#import "MacMenuOS9ToOSX.h"
#import <Cocoa/Cocoa.h>


Boolean ioCheckMenuHandle(MenuHandle menuHandle) {
	int menuID;
	if (menuHandle == 0) return true;
	menuID = GetMenuID(menuHandle);
	if (menuID == 0) return false;
	return true;
}


MenuRef GetMenuHandle(MenuID menuID){
	NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
	NSMenuItem *menuRef =  [mainMenu itemAtIndex: menuID];
	MenuRef handle = (__bridge MenuRef)menuRef;
	return handle; 
};

void 
DisableMenuItem(
				MenuRef         theMenu,
				MenuItemIndex   item){};
void 
GetMenuItemText(
				MenuRef         theMenu,
				MenuItemIndex   item,
				Str255          itemString){};
OSErr 
SetMenuItemCommandID(
					 MenuRef         inMenu,
					 MenuItemIndex   inItem,
					 MenuCommand     inCommandID){};

void DisposeMenu(MenuRef theMenu){
	//Do nothing I think
};

OSErr 
GetMenuItemFontID(
				  MenuRef         inMenu,
				  MenuItemIndex   inItem,
				  SInt16 *        outFontID){};
OSErr 
SetMenuItemHierarchicalID(
						  MenuRef         inMenu,
						  MenuItemIndex   inItem,
						  MenuID          inHierID){};
OSErr 
GetMenuItemCommandID(
					 MenuRef         inMenu,
					 MenuItemIndex   inItem,
					 MenuCommand *   outCommandID){};
void 
SetItemIcon(
			MenuRef         theMenu,
			MenuItemIndex   item,
			short           iconIndex) {};
void 
SetItemCmd(
		   MenuRef         theMenu,
		   MenuItemIndex   item,
		   CharParameter   cmdChar){};
MenuRef 
NewMenu(
		MenuID             menuID,
		ConstStr255Param   menuTitle){};
void 
SetItemMark(
			MenuRef         theMenu,
			MenuItemIndex   item,
			CharParameter   markChar){};
extern Boolean 
IsMenuBarVisible(void){};

void DeleteMenu(MenuID menuID){
	NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
	[mainMenu removeItemAtIndex: menuID];
};

void 
ShowMenuBar(void){};
OSStatus 
AppendMenuItemText(
				   MenuRef            menu,
				   ConstStr255Param   inString) {};
OSErr 
SetMenuItemKeyGlyph(
					MenuRef         inMenu,
					MenuItemIndex   inItem,
					SInt16          inGlyph){};
void 
DeleteMenuItem(
			   MenuRef         theMenu,
			   MenuItemIndex   item) {};
OSErr 
GetMenuItemKeyGlyph(
					MenuRef         inMenu,
					MenuItemIndex   inItem,
					SInt16 *        outGlyph){};
void 
ClearMenuBar(void){};
void 
SetItemStyle(
			 MenuRef          theMenu,
			 MenuItemIndex    item,
			 StyleParameter   chStyle) {};
void 
GetItemIcon(
			MenuRef         theMenu,
			MenuItemIndex   item,
			short *         iconIndex){};
void 
EnableMenuItem(
				  MenuRef         theMenu,
				  MenuItemIndex   item){};
MenuBarHandle 
GetMenuBar(void){};
void 
GetItemMark(
			MenuRef          theMenu,
			MenuItemIndex    item,
			CharParameter *  markChar){};
void 
HideMenuBar(void){};
void 
GetItemStyle(
			 MenuRef         theMenu,
			 MenuItemIndex   item,
			 Style *         chStyle){};
void
EnableMenuItemIcon(
				   MenuRef         theMenu,
				   MenuItemIndex   item){};
void 
HiliteMenu(MenuID menuID){};
void 
InsertMenuItem(
			   MenuRef            theMenu,
			   ConstStr255Param   itemString,
			   MenuItemIndex      afterItem){};
void 
DisableMenuItemIcon(
					MenuRef         theMenu,
					MenuItemIndex   item){};
OSErr 
SetMenuItemModifiers(
					 MenuRef         inMenu,
					 MenuItemIndex   inItem,
					 UInt8           inModifiers){};
void 
SetMenuItemText(
				MenuRef            theMenu,
				MenuItemIndex      item,
				ConstStr255Param   itemString){};
OSErr 
SetMenuItemTextEncoding(
						MenuRef         inMenu,
						MenuItemIndex   inItem,
						TextEncoding    inScriptID){};
OSStatus 
SetMenuTitle(
			 MenuRef            menu,
			 ConstStr255Param   title) {};
void 
CheckMenuItem(
			  MenuRef         theMenu,
			  MenuItemIndex   item,
			  Boolean         checked){};
Boolean 
IsMenuItemIconEnabled(
					  MenuRef         menu,
					  MenuItemIndex   item){};
OSErr 
SetMenuItemFontID(
				  MenuRef         inMenu,
				  MenuItemIndex   inItem,
				  SInt16          inFontID){};
void 
InsertIntlResMenu(
				  MenuRef         theMenu,
				  ResType         theType,
				  MenuItemIndex   afterItem,
				  short           scriptFilter){};
Boolean 
IsMenuItemEnabled(
				  MenuRef         menu,
				  MenuItemIndex   item){};
extern void 
DrawMenuBar(void){};
OSErr 
GetMenuItemModifiers(
					 MenuRef         inMenu,
					 MenuItemIndex   inItem,
					 UInt8 *         outModifiers){};
OSErr 
GetMenuItemHierarchicalID(
						  MenuRef         inMenu,
						  MenuItemIndex   inItem,
						  MenuID *        outHierID){};
StringPtr 
GetMenuTitle(
			 MenuRef   menu,
			 Str255    title){};
void 
SetMenuBar(MenuBarHandle mbar){};
UInt16 
CountMenuItems(MenuRef theMenu){};
void 
GetItemCmd(
		   MenuRef          theMenu,
		   MenuItemIndex    item,
		   CharParameter *  cmdChar){};

MenuID  GetMenuID(MenuRef menu){
	NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
	NSMenuItem *menuItem = (__bridge NSMenuItem *) menu;
	return (MenuID) [mainMenu indexOfItem: menuItem]; 
};

void 
InsertMenu(
		   MenuRef   theMenu,
		   MenuID    beforeID) {};
void 
InsertFontResMenu(
				  MenuRef         theMenu,
				  MenuItemIndex   afterItem,
				  short           scriptFilter){};
void 
AppendMenu(
		   MenuRef            menu,
		   ConstStr255Param   data){};
OSErr 
GetMenuItemTextEncoding(
						MenuRef         inMenu,
						MenuItemIndex   inItem,
						TextEncoding *  outScriptID){};
void 
InvalMenuBar(void){};

void 
EnableMenuCommand(
				  MenuRef       inMenu,
				  MenuCommand   inCommandID){};

OSStatus 
CreateStandardWindowMenu(
						 OptionBits   inOptions,
						 MenuRef *    outMenu){};

void 
DisableMenuCommand(
				   MenuRef       inMenu,
				   MenuCommand   inCommandID){};

OSStatus 
DisposeMenuBar(MenuBarHandle inMbar){};

OSStatus GetIndMenuItemWithCommandID(
							MenuRef          inMenu,
							MenuCommand      inCommandID,
							UInt32           inItemIndex,
							MenuRef *        outMenu,           /* can be NULL */
							MenuItemIndex *  outIndex){

	NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
	NSMenuItem *inputMenu = (__bridge NSMenuItem *) inMenu;
	OSType		inputCommandID = inCommandID;
};
