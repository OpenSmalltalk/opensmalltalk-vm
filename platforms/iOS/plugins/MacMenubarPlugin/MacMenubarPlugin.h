#if __LP64__
typedef unsigned int                    UInt32;
typedef signed int                      SInt32;
#else
typedef unsigned long                   UInt32;
typedef signed long                     SInt32;
#endif

typedef void * MenuHandle;
typedef unsigned char Boolean;
typedef const unsigned char *           ConstStr255Param;
typedef	int	MenuCommand;
typedef char *                          Ptr;
typedef Ptr *                           Handle;
typedef int MenuItemIndex;
typedef short CharParameter;
typedef unsigned char                   Style;
typedef int MenuID;
typedef short SInt16;
typedef UInt32                          TextEncoding;
typedef unsigned char                   Str255[256];
typedef UInt32                          FourCharCode;
typedef FourCharCode                    ResType;
typedef void*							MenuBarHandle;
typedef SInt16                          OSErr;
typedef SInt32                          OSStatus;
typedef short                           StyleParameter;
typedef unsigned char                   UInt8;
typedef unsigned char *                 StringPtr;
typedef unsigned short                  UInt16;
typedef UInt32                          OptionBits;

typedef void*           MenuRef;


Boolean ioCheckMenuHandle(MenuHandle menuHandle);
//#define TARGET_API_MAC_CARBON 1
#define kHICommandHide 'hide'

MenuRef GetMenuHandle(MenuID menuID);
void 
DisableMenuItem(
				MenuRef         theMenu,
				MenuItemIndex   item);
void 
GetMenuItemText(
				MenuRef         theMenu,
				MenuItemIndex   item,
				Str255          itemString);
OSErr 
SetMenuItemCommandID(
					 MenuRef         inMenu,
					 MenuItemIndex   inItem,
					 MenuCommand     inCommandID);
void 
DisposeMenu(MenuRef theMenu);
OSErr 
GetMenuItemFontID(
				  MenuRef         inMenu,
				  MenuItemIndex   inItem,
				  SInt16 *        outFontID);
OSErr 
SetMenuItemHierarchicalID(
						  MenuRef         inMenu,
						  MenuItemIndex   inItem,
						  MenuID          inHierID);
OSErr 
GetMenuItemCommandID(
					 MenuRef         inMenu,
					 MenuItemIndex   inItem,
					 MenuCommand *   outCommandID);
void 
SetItemIcon(
			MenuRef         theMenu,
			MenuItemIndex   item,
			short           iconIndex) ;
void 
SetItemCmd(
		   MenuRef         theMenu,
		   MenuItemIndex   item,
		   CharParameter   cmdChar);
MenuRef 
NewMenu(
		MenuID             menuID,
		ConstStr255Param   menuTitle);
void 
SetItemMark(
			MenuRef         theMenu,
			MenuItemIndex   item,
			CharParameter   markChar);
extern Boolean 
IsMenuBarVisible(void);
void 
DeleteMenu(MenuID menuID);
void 
ShowMenuBar(void);
OSStatus 
AppendMenuItemText(
				   MenuRef            menu,
				   ConstStr255Param   inString) ;
OSErr 
SetMenuItemKeyGlyph(
					MenuRef         inMenu,
					MenuItemIndex   inItem,
					SInt16          inGlyph);
void 
DeleteMenuItem(
			   MenuRef         theMenu,
			   MenuItemIndex   item) ;
OSErr 
GetMenuItemKeyGlyph(
					MenuRef         inMenu,
					MenuItemIndex   inItem,
					SInt16 *        outGlyph);
void 
ClearMenuBar(void);
void 
SetItemStyle(
			 MenuRef          theMenu,
			 MenuItemIndex    item,
			 StyleParameter   chStyle) ;
void 
GetItemIcon(
			MenuRef         theMenu,
			MenuItemIndex   item,
			short *         iconIndex);
void 
MacEnableMenuItem(
				  MenuRef         theMenu,
				  MenuItemIndex   item);
MenuBarHandle 
GetMenuBar(void);
void 
GetItemMark(
			MenuRef          theMenu,
			MenuItemIndex    item,
			CharParameter *  markChar);
void 
HideMenuBar(void);
void 
GetItemStyle(
			 MenuRef         theMenu,
			 MenuItemIndex   item,
			 Style *         chStyle);
void
EnableMenuItemIcon(
				   MenuRef         theMenu,
				   MenuItemIndex   item);
void 
HiliteMenu(MenuID menuID);
void 
InsertMenuItem(
			   MenuRef            theMenu,
			   ConstStr255Param   itemString,
			   MenuItemIndex      afterItem);
void 
DisableMenuItemIcon(
					MenuRef         theMenu,
					MenuItemIndex   item);
OSErr 
SetMenuItemModifiers(
					 MenuRef         inMenu,
					 MenuItemIndex   inItem,
					 UInt8           inModifiers);
void 
SetMenuItemText(
				MenuRef            theMenu,
				MenuItemIndex      item,
				ConstStr255Param   itemString);
OSErr 
SetMenuItemTextEncoding(
						MenuRef         inMenu,
						MenuItemIndex   inItem,
						TextEncoding    inScriptID);
OSStatus 
SetMenuTitle(
			 MenuRef            menu,
			 ConstStr255Param   title) ;
void 
CheckMenuItem(
			  MenuRef         theMenu,
			  MenuItemIndex   item,
			  Boolean         checked);
Boolean 
IsMenuItemIconEnabled(
					  MenuRef         menu,
					  MenuItemIndex   item);
OSErr 
SetMenuItemFontID(
				  MenuRef         inMenu,
				  MenuItemIndex   inItem,
				  SInt16          inFontID);
void 
InsertIntlResMenu(
				  MenuRef         theMenu,
				  ResType         theType,
				  MenuItemIndex   afterItem,
				  short           scriptFilter);
Boolean 
IsMenuItemEnabled(
				  MenuRef         menu,
				  MenuItemIndex   item);
extern void 
DrawMenuBar(void);
OSErr 
GetMenuItemModifiers(
					 MenuRef         inMenu,
					 MenuItemIndex   inItem,
					 UInt8 *         outModifiers);
OSErr 
GetMenuItemHierarchicalID(
						  MenuRef         inMenu,
						  MenuItemIndex   inItem,
						  MenuID *        outHierID);
StringPtr 
GetMenuTitle(
			 MenuRef   menu,
			 Str255    title);
void 
SetMenuBar(MenuBarHandle mbar);
UInt16 
CountMenuItems(MenuRef theMenu);
void 
GetItemCmd(
		   MenuRef          theMenu,
		   MenuItemIndex    item,
		   CharParameter *  cmdChar);
MenuID 
GetMenuID(MenuRef menu);
void 
InsertMenu(
		   MenuRef   theMenu,
		   MenuID    beforeID) ;
void 
InsertFontResMenu(
				  MenuRef         theMenu,
				  MenuItemIndex   afterItem,
				  short           scriptFilter);
void 
AppendMenu(
		   MenuRef            menu,
		   ConstStr255Param   data);
OSErr 
GetMenuItemTextEncoding(
						MenuRef         inMenu,
						MenuItemIndex   inItem,
						TextEncoding *  outScriptID);
void 
InvalMenuBar(void);

void 
EnableMenuCommand(
				  MenuRef       inMenu,
				  MenuCommand   inCommandID);

OSStatus 
CreateStandardWindowMenu(
						 OptionBits   inOptions,
						 MenuRef *    outMenu);

void 
DisableMenuCommand(
				   MenuRef       inMenu,
				   MenuCommand   inCommandID);

OSStatus 
DisposeMenuBar(MenuBarHandle inMbar);

OSStatus 
GetIndMenuItemWithCommandID(
							MenuRef          inMenu,
							MenuCommand      inCommandID,
							UInt32           inItemIndex,
							MenuRef *        outMenu,           /* can be NULL */
							MenuItemIndex *  outIndex);
