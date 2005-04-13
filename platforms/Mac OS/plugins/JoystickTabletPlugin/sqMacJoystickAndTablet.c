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


#if TARGET_API_MAC_CARBON

#pragma mark Joystick support for Mac OS X

#include <Carbon/Carbon.h>
#include <IOKit/HID/IOHIDKeys.h>
#include <IOKit/hid/IOHIDUsageTables.h>
#include "HID_Utilities_External.h"

/* joystickDevice should contain a valid HID GamePad */
pRecDevice joystickDevice = NULL;
pRecElement* joystickCapability;
enum { XAXIS  = 0, YAXIS = 1, BTN1 = 2, BTN2 = 3, BTN3 = 4, BTN4 = 5, MAXCAPABILITY = 6 };

int joystickInit(void) {
    pRecDevice deviceCandidate = NULL;
    int numberOfDevices = 0, i = 0;
    
    /* Build list of Generic Desktop devices. */
    HIDBuildDeviceList(kHIDPage_GenericDesktop, NULL);
    
    if (HIDHaveDeviceList()) {
		numberOfDevices = HIDCountDevices();
		/* We only support one device at a time. We will select the first valid one. */
		deviceCandidate = HIDGetFirstDevice();
		
		while (i < numberOfDevices) {
			if (deviceCandidate) {
				if ( (deviceCandidate->usage == kHIDUsage_GD_Joystick) || (deviceCandidate->usage == kHIDUsage_GD_GamePad) ) {
					if (HIDIsValidDevice(deviceCandidate)) {
					/* The device is valid. */
					joystickDevice = deviceCandidate;
					} 
				} else {
					/* The device is not valid, check the next one. */
					deviceCandidate = HIDGetNextDevice(deviceCandidate);
				}
			}
			i++;
		}
		
		joystickDevice = deviceCandidate;
    }
    
    if (joystickDevice) {
		/* Now that we have a valid device, we try to find its capabilities. */
		joystickCapability = calloc(MAXCAPABILITY, sizeof(pRecElement));
		joystickCapabilities(joystickDevice, joystickCapability);
		return 1;
    } else {
		return 0;
    }
}

int joystickShutdown() {
    if (joystickDevice) {
		free(joystickCapability);
    }
    /* Release the device list */
    HIDReleaseDeviceList();
    return 1;
}

int joystickCapabilities(pRecDevice device, pRecElement* capability) {
    /* Find the device capabilities. */
    pRecElement element = NULL;
    
    for (element = HIDGetFirstDeviceElement(device, kHIDElementTypeInput); element != NULL; element = HIDGetNextDeviceElement(element, kHIDElementTypeInput)) {
		if (element) {
			switch (element->usagePage) {
				case kHIDPage_GenericDesktop:
					switch (element->usage) {
						/* X axis */
						case kHIDUsage_GD_X:
							joystickCapability[XAXIS] = element;
							break;
						/* Y axis */
						case kHIDUsage_GD_Y:
							joystickCapability[YAXIS] = element;
							break;
					}
					break;
				case kHIDPage_Button:
					switch (element->usage) {
						/* Primary/Trigger */
						case kHIDUsage_Button_1:
							joystickCapability[BTN1] = element;
							break;
							/* Secondary */
						case kHIDUsage_Button_2:
							joystickCapability[BTN2] = element;
							break;
							/* Tertiary */
						case kHIDUsage_Button_3:
							joystickCapability[BTN3] = element;
							break;
							/* 5th button */
						case kHIDUsage_Button_4:
							joystickCapability[BTN4] = element;
							break;
					}
					break;
			}
		}
    }
}

int joystickScaleValue(pRecDevice device, pRecElement element) {
    /* Get a calibrated value on a scale from 0 to 255. */ 
    SInt32 valueRaw = 0, valueCalibrated = 0, valueScaled = 0;
    
    if (HIDIsValidElement(device, element)) {
		valueRaw = HIDGetElementValue(device, element); 
		valueCalibrated = HIDCalibrateValue(valueRaw, element);
		valueScaled = HIDScaleValue(valueCalibrated, element);
    }
    
    return (int)valueScaled;
}

int joystickRead(int stickIndex) {
    /* Read the current state of the device. */
    int buttons = 0, xBits, yBits, value;
    
    if (joystickDevice) {
		value = HIDGetElementValue(joystickDevice, joystickCapability[BTN1]);
		value += (HIDGetElementValue(joystickDevice, joystickCapability[BTN2]) + 1);
		value += (HIDGetElementValue(joystickDevice, joystickCapability[BTN3]) + 2);
		value += (HIDGetElementValue(joystickDevice, joystickCapability[BTN4]) + 3);
		buttons = value & 0x0F;
		
		// Generic Desktop X
		value = joystickScaleValue(joystickDevice, joystickCapability[XAXIS]);
		xBits = value & 0xFF;
		
		// Generic Desktop Y
		value = joystickScaleValue(joystickDevice, joystickCapability[YAXIS]);  
		yBits = value & 0xFF;
		
		//return (1 << 27) | (buttons << 22) | (yBits << 11) | xBits;
		
		/* The x/y range is between 0 and 255, convert to 0..2047 by shifting left 3 bits */
		return (1 << 27) | (buttons << 22) | (yBits << 14) | (xBits << 3);
    } else {
		return 0;
    }
}

#else

#pragma mark Joystick support for older versions of Mac OS

#include <DeskBus.h>
#include <Devices.h>
#include <Timer.h>

#define MOUSESTICK_SIGNATURE 0x4A656666
#define MAX_STICKS 4

/* Joystick Record */

typedef struct {
    short		rawX;			/* absolute stick position */
    short		rawY;
    unsigned char	buttons;
    char		private1;
    short		cursorX;		/* cursor position */
    short		cursorY;
    char		oldStickType;
    char		private2;
    char		stickOn;		/* true if stick is connected */
    char		private3;
    char		stickControlsCursor;
    char		applicationAware;	/* settings change with application changes */
    char		private4[152];
} MouseStickRec;

typedef struct {
    long		signature;
    char		private1[18];
    short		stickCount;
    char		private2[22];
    MouseStickRec	stick[MAX_STICKS];
} MouseStickSetRec, *MouseStickSetPtr;

/*** Variables ***/

MouseStickSetPtr joySticks = nil;	/* pointer to a joystick set or nil */

int joystickInit(void) {
    /* If a joystick is plugged in and its control panel is installed,
	   initialize the global pointer 'joySticks' to the joystick set
	   data structure. Otherwise, set it to nil.
    */
    
    ADBDataBlock adbGetInfo;
    MouseStickSetPtr sticks;
    int count, i;
    
    joySticks = nil;  /* set to nil in case we don't find any joysticks */
    
    count = CountADBs();
    for (i = 1; i <= count; i++) {
	GetADBInfo(&adbGetInfo, GetIndADB(&adbGetInfo, i));
	sticks = (MouseStickSetPtr) adbGetInfo.dbDataAreaAddr;
	if ((sticks != nil) && (sticks->signature == MOUSESTICK_SIGNATURE)) {
	    joySticks = sticks;
	    return true;
	}
    }
    return true;
}

int joystickShutdown() {
    return 1;
}

int joystickRead(int stickIndex) {
    /* Return input word for the joystick with the given index (in range [1..2]
    on the Macintosh; other platforms may vary). This word is encoded as follows:

    <onFlag (1 bit)><buttonFlags (5 bits)><x-value (11 bits)><y-value (11 bits)>

    The highest four bits of the input word are zero. If the onFlag bit is zero,
    there is no joystick at the given index. This may be because no joystick
    is connected or the joystick control panel is not installed. In such,
    cases, the entire word will be zero. A maximum of two joysticks are supported
    by Gravis's current version of the control panel. The x and y values are
    11-bit signed values in the range [-1024..1023] representing the raw (unencoded)
    joystick position. The MouseStick II only uses the approximate range [-650..650].
    The range and center values of poorly adjusted joysticks may vary; the client
    software should provide a way to adjust the center and scaling to correct.
    */
    
    MouseStickRec stickData;
    int buttons, xBits, yBits;
    
    if ((joySticks == nil) || (stickIndex < 1) || (stickIndex > 2) ||
	(stickIndex > joySticks->stickCount)) {
	return 0;  /* no joystick at the given index */
    }
    stickData = joySticks->stick[stickIndex - 1];  /* 1-based index */
    buttons = ~stickData.buttons & 0x1F;
    xBits = (0x400 + stickData.rawX) & 0x7FF;
    yBits = (0x400 + stickData.rawY) & 0x7FF;
    return (1 << 27) | (buttons << 22) | (yBits << 11) | xBits;
}

#endif

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

#if TARGET_API_MAC_CARBON
    return false;
#else
	CntrlParam	pb;
	short		driverRefNum;

	if (OpenDriver("\p.Wacom", &driverRefNum) != noErr) {
		return false;
	}

	pb.ioCRefNum = driverRefNum;
	pb.csCode = 20;  /* requests the address of the current tablet record */
	if (PBStatusSync((ParmBlkPtr) (&pb)) != noErr) {
		return false;
	}

	tablet = *((TabletRecPtr *) &pb.csParam);
	return tablet->tabletID == 0x54424c54;  /* verify that id is 'TBLT' */
#endif 
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
