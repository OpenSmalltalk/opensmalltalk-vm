/*
 * Interface to access Plan9's functionality.
 *
 * Author: Alex Franchuk (alex.franchuk@gmail.com)
 */

#ifndef _P9IFACE_H
#define _P9IFACE_H

int displayInit(void);
void displayDestroy(void);

void resizeWindow(int width, int height);
void positionWindow(int x, int y);

int timeInit(void);

int ioInit(void);
void ioDestroy(void);

#endif
