#ifndef _VIDEOLIB_H
#define _VIDEOLIB_H

#include "palettes.h"

#include <linux/videodev.h>

typedef int BOOLEAN;
#define TRUE  1
#define FALSE 0

struct dev {
   char* deviceName;

   unsigned int desiredWidth;
   unsigned int desiredHeight;

   char desiredPalette;

   int fd;

   struct video_capability vcapability;
   struct video_window     vwindow;
   struct video_picture    vpicture;

   char *buffer;

   struct video_mbuf  memoryBuffer;
   char*              memoryMap;
   struct video_mmap* mmaps;
   int  imageSize;
   int  bufferIndex;

   char *buffer24;

   BOOLEAN forceRead;
   BOOLEAN usingMMap;

   // Bitmap conversor
   Converter converterFunction;

   // V4L2 stuff
   BOOLEAN isV4L2;
   struct v4l2_capability v4l2Capability;
};

typedef struct dev* Device;

#define SIZE_OF_DEVICE     sizeof(struct dev)

void    describeDevice(int deviceID, char* deviceName);

Device  createDevice(int deviceID,
		     int width, int height,
		     int palette);

BOOLEAN convertBufferTo24     (Device device);
BOOLEAN captureFrameFromDevice(Device device);
BOOLEAN nextFrameFromDevice   (Device device);

int getPalette(Device device);

/*
int     getBrightness(Device device);
int     getContrast  (Device device);
int     getSaturation(Device device);
int     getHue       (Device device);

void    setBrightness(Device device, int brightness);
void    setContrast  (Device device, int contrast);
void    setSaturation(Device device, int saturation);
void    setHue       (Device device, int hue);
*/
BOOLEAN updatePicture(Device device);

void    closeDevice(Device device);


void savePPM(char* fileName, Device device);

#endif
