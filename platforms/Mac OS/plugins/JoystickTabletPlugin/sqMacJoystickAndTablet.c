/* Adjustments for pluginized VM
 *
 * Note: The Mac support files have not yet been fully converted to
 * pluginization. For the time being, it is assumed that they are linked
 * with the VM. When conversion is complete, they will no longer import
 * "sq.h" and they will access all VM functions and variables through
 * the interpreterProxy mechanism.
 */

#include "sq.h"
#include "JoystickTabletPlugin.h"

/* End of adjustments for pluginized VM */


#pragma mark Joystick support for Mac OS X

#include "HID_Utilities.h"
long HIDGetElementValue (pRecDevice pDevice, pRecElement pElement);

int joystickInit(void)
{
    HIDBuildDeviceList(kHIDPage_GenericDesktop, 0);
	return true;
}
 
int joystickShutdown()
{
    HIDReleaseDeviceList();
    return true;
}

static pRecDevice getJoystickDevice(int stickIndex)
{
	pRecDevice device = HIDGetFirstDevice();
	int stickCount = 0;
	while (device)
	{
		if ( (device->usage == kHIDUsage_GD_Joystick) || (device->usage == kHIDUsage_GD_GamePad) )
		{
			stickCount++;
			if (stickCount == stickIndex)
				return device;
		}
		device = HIDGetNextDevice(device);
	}
	return NULL;
}


static int getScaledAxisValue(pRecDevice device, pRecElement element, int userMin, int userMax)
{
	SInt32 raw = HIDGetElementValue(device, element);
	element -> userMin = userMin;
	element -> userMax = userMax;
	return (int) HIDScaleValue(raw, element);
}

int joystickRead(int stickIndex)
{
   /* Return input word for the joystick with the given index (starting at 1).
	This word is encoded as follows:

    <onFlag (1 bit)><buttonFlags (5 bits)><x-value (11 bits)><y-value (11 bits)>

    The highest four bits of the input word are zero. If the onFlag bit is zero,
    there is no joystick at the given index. The x and y values are
    11-bit signed values in the range [-1024..1023] representing the raw (unencoded)
    joystick position.
    */

	int onFlag = 0;
	int buttons = 0;
	int xValue = 0;
	int yValue = 0;
	
	pRecDevice device = getJoystickDevice(stickIndex);	
	if (device)
	{
		onFlag = 1;
	
		pRecElement element = HIDGetFirstDeviceElement(device, kHIDElementTypeAll);
		while (element)
		{
			switch (element->usagePage)
			{
				case kHIDPage_GenericDesktop:
					switch (element->usage)
					{
						case kHIDUsage_GD_X:
							xValue = getScaledAxisValue(device, element, -1024, 1023);
							break;
						case kHIDUsage_GD_Y:
							yValue = getScaledAxisValue(device, element, -1024, 1023);
							break;
					}
					break;
				case kHIDPage_Button:
					{
						int button = element->usage - kHIDUsage_Button_1;
						if ((button >= 0) && (button <= 4) ) 
							buttons |= (HIDGetElementValue(device, element) << button);
					}
					break;
			}
			element = HIDGetNextDeviceElement(element, kHIDElementTypeAll);	
		}
	}
	return (onFlag << 27) | (buttons << 22) | ((yValue + 1024) << 11) | (xValue + 1024);
}


#pragma mark Tablet support for older versions of Mac OS

/* Tablet Record (see  Apple Tech. Note 266, version 2) */

#define MAX_TRANSDUCERS 4

typedef struct {
    char	DOFTrans;			/* degrees of freedom and transducer type */
    char	orientFlag;			/* type of orientation information */
    short	pressLevels;		/* pressure support and number of levels */
    unsigned short xScale;		/* x scale factor for screen mapping */
    short	xTrans;				/* x translation factor for screen */
    unsigned short yScale;		/* y scale factor for screen mapping */
    short	yTrans;				/* y translation factor for screen */
    unsigned char flags;		/* proximity, update flag, and # buttons */
    unsigned char pressThresh;	/* pressure threshold - normally unused */
    short	buttonMask;			/* button mask of driver-reserved buttons */
    short	errorFlag;			/* error code generated */
    short	buttons;			/* buttons pressed */
    short	tangPress;			/* tangential pressure level */
    short	pressure;			/* normal pressure level */
    long	timeStamp;			/* ticks at latest update */
    long	xCoord;				/* x coordinate in resolution units */
    long	yCoord;				/* y coordinate in resolution units */
    long	zCoord;				/* z coordinate in resolution units */
    short	xTilt;				/* x tilt */
    short	yTilt;				/* y tilt */
    short	unused[8];			/* remainder of unused attitude matrix */
} TransducerRec, *TransducerRecPtr;

typedef struct {
    char	version;			/* version of this data format */
    char	semaphore;			/* for future use -- tells if drvr is enabled */
    char	cursors;			/* number of cursors with tablet */
    char	updateFlags;		/* flags used when updating structure */
    short	angleRes;			/* metric bit & angular resolution */
    short	spaceRes;			/* spatial resolution of the tablet */
    long	xDimension;			/* x dimension in resolution units */
    long	yDimension;			/* y dimension in resolution units */
    long	zDimension;			/* z dimension in resolution units */
    long	xDisplace;			/* x displacement - minimum x value */
    long	yDisplace;			/* y displacement - minimum y value */
    long	zDisplace;			/* z displacement - minimum z value */
    long	reserved;			/* reserved */
    long	tabletID;			/* contains 'TBLT' identifying the device */
	TransducerRec transducer[MAX_TRANSDUCERS];
} TabletRec, *TabletRecPtr;

/*** Variables ***/

TabletRecPtr tablet = nil;  		/* pointer to a tablet record or nil */

int tabletInit(void);
int tabletInit(void) {
	/* Open the tablet driver and initialize the global pointer to its status
	   record. Return true if a tablet exists, false otherwise. */

    return false;
}

int tabletGetParameters(int cursorIndex, int result[]) {
	/* Fill in the integer array 'result' with tablet parameter information.
	   For cursor-specific parameters, such as the number of pressure levels,
	   return the information for the cursor with the given index, an integer
	   between 1 and tablet->cursors. */

	TransducerRecPtr cursorPtr;
	int cursor;

	/* open tablet if necessary; return false if no tablet */
	if (tablet == nil) {
		if (!tabletInit()) return false;
	}

	cursor = cursorIndex - 1;
	if ((cursor < 0)  || (cursor >= tablet->cursors)) {
		return false;
	}
	cursorPtr = &tablet->transducer[cursor];

	result[0] = tablet->xDimension;
	result[1] = tablet->yDimension;
	result[2] = tablet->spaceRes;
	result[3] = tablet->cursors;  /* number of cursors */

	result[4] = cursor + 1;
	result[5] = cursorPtr->xScale;
	result[6] = cursorPtr->xTrans;
	result[7] = cursorPtr->yScale;
	result[8] = cursorPtr->yTrans;
	result[9] = cursorPtr->pressLevels;
	result[10] = cursorPtr->pressThresh;

	if (tablet->angleRes == 0) {
		result[11] = 0;  /* no pen tilt support */
	} else {
		result[11] = tablet->angleRes >> 1;  /* number of pen tilt levels */
	}

	return true;
}

int tabletRead(int cursorIndex, int result[]) {
	/* Fill in the integer array 'result' with the current data
	   the cursor with the given index, an integer between 1 and
	   tablet->cursors. Note that the timestamp changes only
	   when some new data has arrived from the tablet. */

	TransducerRecPtr cursorPtr;
	int cursor;

	/* open tablet if necessary; return false if no tablet */
	if (tablet == nil) {
		if (!tabletInit()) return false;
	}

	cursor = cursorIndex - 1;
	if ((cursor < 0)  || (cursor >= tablet->cursors)) {
		return false;
	}
	cursorPtr = &tablet->transducer[cursor];

	result[0] = cursor + 1;
	result[1] = cursorPtr->timeStamp;
	result[2] = cursorPtr->xCoord;
	result[3] = cursorPtr->yCoord;
	result[4] = cursorPtr->zCoord;
	result[5] = cursorPtr->xTilt;
	result[6] = cursorPtr->yTilt;
	result[7] = (cursorPtr->DOFTrans & 0x30) >> 4;  /* cursor type; 1-pen, 2-puck, 3-eraser */
	result[8] = cursorPtr->buttons;
	result[9] = cursorPtr->pressure;
	result[10] = cursorPtr->tangPress;
	result[11] = cursorPtr->flags;
	return true;
}

int tabletResultSize(void) {
	/* Return the size of the integer array required to hold the results of
	   either a tabletGetParameters() or tabletRead() call. The VM allocates
	   an array of this length and passes it as a parameter to be filled in. */

	return 12;
}
