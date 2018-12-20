/*
 * Plan9 Squeak display/io functions.
 *
 * Author: Alex Franchuk (alex.franchuk@gmail.com)
 */

#define _PLAN9_SOURCE

#include "sq.h"

#include <draw.h>
#include <cursor.h>
#include <stdio.h>

void resizeWindow(int width, int height) {
	int fd;

	fd = open("/dev/wctl", ORDWR);
	if(fd < 0)
		return;
	fprint(fd, "resize -dx %d -dy %d", width, height);
	close(fd);
}

void positionWindow(int x, int y) {
	int fd;

	fd = open("/dev/wctl", ORDWR);
	if(fd < 0)
		return;
	fprint(fd, "move -minx %d -miny %d", x, y);
	close(fd);
}

int displayInit(void) {
	if (newwindow("-dx 800 -dy 600") == -1) {
		printf("Could not create new window: %r\n");
		return -1;
	}
	if (initdraw(0,0,0) == -1) {
		printf("Could not initialize display: %r\n");
		return -1;
	}
	return 0;
}

void displayDestroy(void) {
}
