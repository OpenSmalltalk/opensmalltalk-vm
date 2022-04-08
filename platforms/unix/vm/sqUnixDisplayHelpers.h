#ifndef __sqUnixDisplayHelpers_h
#define __sqUnixDisplayHelpers_h

#include <stdbool.h>

/***************  Display Scale Factor Helpers ************************/

#pragma mark Important Environment Variables
/*
 * Setting this environment variable causes Squeak to always report
 * the specified scale factor. Float.
 * NB. Squeak also recoginzes other common environment variables with
 * this effect set by some GUI frameworks (GTK/Qt/...)
 */
#define DISPLAY_SCALE_FACTOR "SQUEAK_DISPLAY_SCALE_FACTOR"
/*
 * Setting this to anything but 0/false/False/FALSE/f/NO/no/No/n will
 * cause Squeak to try hard and give an acurate scale factor from
 * nominal 96 DPI to the actual screens DPI.
 * Does nothing if DISPLAY_SCALE_FACTOR/SQUEAK_DISPLAY_SCALE_FACTOR is
 * set.
 * Truth value.
 */
#define DISPLAY_PREFER_PHYSICAL_SCALE  "SQUEAK_DISPLAY_PREFER_PHYSICAL_SCALE"
/*
 * Setting this to anything but 0/false/False/FALSE/f/NO/no/No/n will
 * cause Squeak to try and find the scale factor for the _current_
 * montior Squeak is running on.
 * Note: the same monitor may report different factors with or without
 * this setting.
 * Does nothing if DISPLAY_SCALE_FACTOR/SQUEAK_DISPLAY_SCALE_FACTOR is
 * set.
 * Truth value.
 */
#define DISPLAY_PER_MONITOR_SCALE  "SQUEAK_DISPLAY_PER_MONITOR_SCALE"


#pragma mark Interface

/*
 * Scale factor to use if all else fails.
 */
double
sqDefaultScale(void);

/*
 * Checks whether a scaling-relevant environment-variable is present
 * and whether to use it.
 */
bool
sqUseEnvironmentScale(void);


/*
 * Produce a scale factor from a scale-relevant variable in the
 * environment.
 *
 */
double
sqEnvironmentScale(void);

/*
 * True when users want per-monitor scale. 
 * Note: the same monitor may report different factors with or without
 * this setting.
 */
extern bool
sqPerMonitorScale(void);
/*
 * True when users prefer physical scale factors.
 */
extern bool
sqPreferPhysicalScale(void);


extern double
sqScaleFromPhysical(int hpix, int vpix, double hinches, double vinches);



#endif /* __sqUnixDisplayHelpers_h */
