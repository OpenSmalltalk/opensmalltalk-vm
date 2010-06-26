#include <Menus.h>

Boolean ioCheckMenuHandle(MenuHandle menuHandle);

Boolean ioCheckMenuHandle(MenuHandle menuHandle) {
	int menuID;
	if (menuHandle == 0) return true;
	menuID = GetMenuID(menuHandle);
	if (menuID == 0) return false;
	return true;
}
