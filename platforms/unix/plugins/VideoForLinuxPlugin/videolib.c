#include <errno.h>
#include <fcntl.h>
#include <linux/videodev.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>

#include "palettes.h"
#include "videolib.h"


#define DEVICE_NAME_SIZE 12
static const char* videoDeviceBaseName = "/dev/video0";

/* thanks ned! */
#define EINTR_RETRY(expression)                                                   \
   (__extension__                                                                 \
      ({                                                                          \
         long int __result;                                                       \
         do {                                                                     \
            sigset_t ss1, ss2;                                                    \
                                                                                  \
            sigemptyset(&ss1);          /* init empty set of signals */           \
            sigaddset(&ss1, SIGALRM);   /* add ALRM to set of blocked signals */  \
            /* can add more signals to block here */                              \
            sigprocmask(SIG_BLOCK, &ss1, &ss2); /* block some signals */          \
                                                                                  \
            __result = (long int) (expression);                                   \
                                                                                  \
            sigprocmask(SIG_SETMASK, &ss2, NULL); /* restore */                   \
         }                                                                        \
         while ((__result == -1L) && (errno == EINTR));                           \
         __result;                                                                \
      })                                                                          \
   )

static int xioctl(int fd, int request, void *arg) {
   int r;

   do
     r = ioctl(fd, request, arg);
   while (-1 == r && EINTR == errno);

   return r;
}

int getBrightness(Device device) {
   return device->vpicture.brightness;
}

int getContrast(Device device) {
   return device->vpicture.contrast;
}

int getSaturation(Device device) {
   return device->vpicture.colour;
}

int getHue(Device device) {
   return device->vpicture.hue;
}

void showDeviceInformation(Device device) {
   fprintf(stdout, "    - Device Information:\n");
   fprintf(stdout, "      ================================================================\n");
   fprintf(stdout, "       V4L1 Capabilities\n");
   fprintf(stdout, "       -----------------\n");
   fprintf(stdout, "       Name: %s\n", device->vcapability.name);
   fprintf(stdout, "       Type: %d\n", device->vcapability.type);

   if (device->vcapability.type & VID_TYPE_CAPTURE) {
      fprintf(stdout, "             Can capture to memory\n");
   }
   if (device->vcapability.type & VID_TYPE_TUNER) {
      fprintf(stdout, "             Has a tuner of some form\n");
   }
   if (device->vcapability.type & VID_TYPE_TELETEXT) {
      fprintf(stdout, "             Has teletext capability\n");
   }
   if (device->vcapability.type & VID_TYPE_OVERLAY) {
      fprintf(stdout, "             Can overlay its image onto the frame buffer\n");
   }
   if (device->vcapability.type & VID_TYPE_CHROMAKEY) {
      fprintf(stdout, "             Overlay is Chromakeyed\n");
   }
   if (device->vcapability.type & VID_TYPE_CLIPPING) {
      fprintf(stdout, "             Overlay clipping is supported\n");
   }
   if (device->vcapability.type & VID_TYPE_FRAMERAM) {
      fprintf(stdout, "             Overlay overwrites frame buffer memory\n");
   }
   if (device->vcapability.type & VID_TYPE_SCALES) {
      fprintf(stdout, "             The hardware supports image scaling\n");
   }
   if (device->vcapability.type & VID_TYPE_MONOCHROME) {
      fprintf(stdout, "             Image capture is grey scale only\n");
   }
   if (device->vcapability.type & VID_TYPE_SUBCAPTURE) {
      fprintf(stdout, "             Capture can be of only part of the image\n");
   }
   if (device->vcapability.type & VID_TYPE_MPEG_ENCODER) {
      fprintf(stdout, "             Can encode MPEG streams");
   }
   if (device->vcapability.type & VID_TYPE_MJPEG_DECODER) {
      fprintf(stdout, "             Can decode MJPEG streams");
   }
   if (device->vcapability.type & VID_TYPE_MJPEG_ENCODER) {
      fprintf(stdout, "             Can encode MJPEG streams");
   }
   if (device->vcapability.type & VID_TYPE_MPEG_DECODER) {
      fprintf(stdout, "             Can decode MPEG streams\n");
   }

   fprintf(stdout,
           "       Channels: %d  Audios: %d  MinExtent: %d@%d  MaxExtent: %d@%d\n",
           device->vcapability.channels,
           device->vcapability.audios,
           device->vcapability.minwidth,
           device->vcapability.minheight,
           device->vcapability.maxwidth,
           device->vcapability.maxheight);

   if (device->isV4L2) {
      fprintf(stdout, "      ----------------------------------------------------------------\n");
      fprintf(stdout, "       V4L2 Capabilities\n");
      fprintf(stdout, "       -----------------\n");


      printf("       Driver: %s\n",                 device->v4l2Capability.driver);
      printf("       Card: %s\n",                   device->v4l2Capability.card);
      printf("       BusInfo: %s\n",                device->v4l2Capability.bus_info);

      fprintf(stdout, "       Capabilities: %d\n", device->v4l2Capability.capabilities);

      if (device->v4l2Capability.capabilities & V4L2_CAP_VIDEO_CAPTURE ) {
        fprintf(stdout, "             Video Capture\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_VIDEO_OUTPUT ) {
        fprintf(stdout, "             Video Output\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_VIDEO_OVERLAY ) {
        fprintf(stdout, "             Video Overlay\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_VBI_CAPTURE ) {
        fprintf(stdout, "             VBI Capture\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_VBI_OUTPUT ) {
        fprintf(stdout, "             VBI Output\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_RDS_CAPTURE ) {
        fprintf(stdout, "             RDS Capture\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_TUNER ) {
        fprintf(stdout, "             Tuner\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_AUDIO ) {
        fprintf(stdout, "             Audio\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_READWRITE ) {
        fprintf(stdout, "             Read/Write\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_ASYNCIO ) {
        fprintf(stdout, "             Async IO\n");
      }
      if (device->v4l2Capability.capabilities & V4L2_CAP_STREAMING ) {
        fprintf(stdout, "             Streaming\n");
      }
   }

   fprintf(stdout, "      ================================================================\n");
}


void initDevice(Device device,
                char* deviceName,
                int width, int height,
                int palette) {
   device->deviceName = (char*) malloc(1024);
   memset(device->deviceName, 0, 1024);
   strcpy(device->deviceName, deviceName);

   device->desiredWidth  = width;
   device->desiredHeight = height;

   device->desiredPalette = palette;

   device->fd = 0;

   device->buffer = 0;

   device->memoryMap   = 0;
   device->mmaps       = 0;
   device->imageSize   = 0;
   device->bufferIndex = 0;
   device->buffer24    = 0;

   device->forceRead = FALSE;
   device->usingMMap = FALSE;

   device->isV4L2    = FALSE;

   device->converterFunction = 0;
}



void setupMMap(Device device) {
   int i;
   int mmapsSize;
   device->usingMMap = FALSE;

   fprintf(stdout, "    - Seting up MMAP for device %p\n", device);

   if (EINTR_RETRY(xioctl(device->fd, VIDIOCGMBUF, &device->memoryBuffer)) < 0) {
      /* failed to retrieve information about capture memory space */
      perror("VIDIOCGMBUF");
      return;
   }

   fprintf(stdout, "        - The device has %d buffers\n", device->memoryBuffer.frames);

   /* obtain memory mapped area */
   device->memoryMap = (char*) mmap(0,
                                    device->memoryBuffer.size,
                                    PROT_READ /*| PROT_WRITE*/,
                                    MAP_SHARED, device->fd, 0);
   if (device->memoryMap < (char*)0) {
      fprintf(stdout, "        * Failed to retrieve pointer to memory mapped area\n");
      return;
   }

   /* allocate structures */
   mmapsSize = device->memoryBuffer.frames * 32 * 4 /* sizeof(struct video_mmap)*/;
   fprintf(stdout, "        - Allocing %d bytes\n", mmapsSize);
   device->mmaps = (struct video_mmap*) malloc(mmapsSize);

   if (device->mmaps == 0) {
      fprintf(stdout, "        * Not enough memory\n");
      return;
   }

   /* fill out the fields */
   for (i = 0; i < device->memoryBuffer.frames; i++) {
      fprintf(stdout, "        - Creating the mmap #%d\n", i);

      device->mmaps[i].frame  = i;
      device->mmaps[i].width  = device->vwindow.width;
      device->mmaps[i].height = device->vwindow.height;
      device->mmaps[i].format = device->vpicture.palette;
   }

   device->usingMMap = TRUE;
}


BOOLEAN startCaptureInBuffers(Device device) {
   int i;
   for (i = 0; i < (device->memoryBuffer.frames - 1); i++) {
      fprintf(stdout, "- Capturing buffer #%d (1st pass)\n", i);
      if (EINTR_RETRY(xioctl(device->fd, VIDIOCMCAPTURE, &device->mmaps[i])) < 0) {
      //if (xioctl(device->fd, VIDIOCMCAPTURE, &device->mmaps[i]) < 0) {
         perror("VIDIOCMCAPTURE1");
         return FALSE;
      }
   }

   device->bufferIndex = device->memoryBuffer.frames - 1;
   return TRUE;
}


BOOLEAN switchToRead(Device device) {
   device->usingMMap = FALSE;
   device->buffer    = (char*) malloc(device->imageSize);
   if (!device->buffer) {
      fprintf(stdout, "* Out of memory.\n");
      return FALSE;
   }

   return TRUE;
}


BOOLEAN rawSetupPalette(Device device) {

   if (device->desiredPalette && (device->vpicture.palette != device->desiredPalette)) {
      fprintf(stdout,
              "    - Changing the palette from %d (%s) to %d (%s) and depth from %d to %d\n",
              device->vpicture.palette,
              paletteName(device->vpicture.palette),
              device->desiredPalette,
              paletteName(device->desiredPalette),
              device->vpicture.depth,
              paletteDepth(device->desiredPalette));

      device->vpicture.palette = device->desiredPalette;
      device->vpicture.depth   = paletteDepth(device->desiredPalette);

      if (EINTR_RETRY(xioctl(device->fd, VIDIOCSPICT, &device->vpicture)) < 0) {
         perror("VIDIOCSPICT");
         return FALSE;
      }
      if (paletteDepth(device->desiredPalette) != device->vpicture.depth) {
         fprintf(stdout, "    * The device can't change the depth\n");
         return FALSE;
      }
      if (device->desiredPalette != device->vpicture.palette) {
         fprintf(stdout, "    * The device can't change the palette\n");
         return FALSE;
      }
   }

   fprintf(stdout,
           "    - Depth=%d Palette=%d (%s)\n",
           device->vpicture.depth,
           device->vpicture.palette,
           paletteName(device->vpicture.palette));

   return TRUE;
}

/* let's try to change the bit depth and palette */
BOOLEAN setupPalette(Device device) {

   // The OLPC webcam supports palette 3 and 8, but 8 has better
   // quality.  Let's try to use palette 8 and let's fallback in a
   // good way.
   if (device->desiredPalette == 0) {
      if (device->vpicture.palette == 3) {
         device->desiredPalette = 8;
         fprintf(stdout, "    - Trying palette 8 instead of 3 (for better quality)\n");
         if (rawSetupPalette(device)) {
            fprintf(stdout, "    - Palette 8 set!\n");
            return TRUE;
         }
         fprintf(stdout, "    * Palette 8 can't be set!\n");
         device->desiredPalette = 0;
      }
   }

   return rawSetupPalette(device);
}


BOOLEAN setupDevice(Device device) {
   BOOLEAN change;
   fprintf(stdout, "- Seting up device %p\n", device);


   /* check (again) for a valid device */
   if (!(device->vcapability.type & VID_TYPE_CAPTURE)) {
      fprintf(stdout, "    * The device can't capture video\n");
      return FALSE;
   }

   if (device->vcapability.channels == 0) {
      fprintf(stdout, "    * The device hasn't inputs\n");
      return FALSE;
   }


   /* ---------------------------------------------------------------------- */
   /* let's try to change the capture width & height */
   change = FALSE;
   if (EINTR_RETRY(xioctl(device->fd, VIDIOCGWIN, &device->vwindow)) < 0) {
      perror("VIDIOCGWIN1");
      return FALSE;
   }

   if (device->desiredWidth && (device->vwindow.width != device->desiredWidth)) {
     fprintf(stdout, "    - Changing the width from %d to %d\n", device->vwindow.width, device->desiredWidth);

     device->vwindow.width = device->desiredWidth;
     change = TRUE;
   }
   if (device->desiredHeight && (device->vwindow.height != device->desiredHeight)) {
     fprintf(stdout, "    - Changing the height from %d to %d\n", device->vwindow.height, device->desiredHeight);

     device->vwindow.height = device->desiredHeight;
     change = TRUE;
   }

   if (change) {
      if (EINTR_RETRY(xioctl(device->fd, VIDIOCSWIN, &device->vwindow)) < 0) {
         perror("VIDIOCGWIN2");
         return FALSE;
      }

      if (EINTR_RETRY(xioctl(device->fd, VIDIOCGWIN, &device->vwindow)) < 0) {
         perror("VIDIOCGWIN3");
         return FALSE;
      }
      if (device->desiredWidth != device->vwindow.width) {
         fprintf(stdout,
                 "    * The device can't change the capture width (now=%d)\n",
                 device->vwindow.width);
         return FALSE;
      }
      if (device->desiredHeight != device->vwindow.height) {
         fprintf(stdout,
                 "    * The device can't change the capture height (now=%d)\n",
                 device->vwindow.height);
         return FALSE;
      }

   }

   fprintf(stdout,
           "    - Extent=%d@%d\n",
           device->vwindow.width,
           device->vwindow.height);

   if (EINTR_RETRY(xioctl(device->fd, VIDIOCGPICT, &device->vpicture)) < 0) {
      perror("VIDIOCGPICT");
      return FALSE;
   }

   fprintf(stdout,
           "    - Brightness=%d, Contrast=%d, Saturation=%d, Hue=%d\n",
           getBrightness(device),
           getContrast(device),
           getSaturation(device),
           getHue(device));
   /* ---------------------------------------------------------------------- */


   /* ---------------------------------------------------------------------- */
   if (!setupPalette(device)) {
      return FALSE;
   }
   /* ---------------------------------------------------------------------- */


   device->imageSize = (int) device->vwindow.width * device->vwindow.height * (paletteBytesPerPixel(device->vpicture.palette));
   device->buffer24  = (char*) malloc(device->vwindow.width * device->vwindow.height * 3);

   if (device->forceRead) {
      fprintf(stdout, "    - Capturing using (forced) read()\n");
      if (!switchToRead(device)) {
         return FALSE;
      }
   }
   else {
      setupMMap(device);

      if (device->usingMMap) {
         fprintf(stdout, "    - Capturing using mmap()\n");
         if (!startCaptureInBuffers(device)) {
            fprintf(stdout, "    * Falling back to read()\n");
            if (!switchToRead(device)) {
               return FALSE;
            }
         }
      }
      else {
         fprintf(stdout, "    - Capturing using read()\n");
         if (!switchToRead(device)) {
            return FALSE;
         }
      }
   }

   return TRUE;
}

void initializeDevice(Device device) {
   device->isV4L2 = FALSE;

   //if (EINTR_RETRY(xioctl(device->fd, VIDIOC_QUERYCAP, &cap)) < 0) {
   if (EINTR_RETRY(xioctl(device->fd, VIDIOC_QUERYCAP, &device->v4l2Capability)) < 0) {
      perror("VIDIOC_QUERYCAP");
      fprintf(stderr, "    - It doesn't appear to be a v4l2 device\n");
   }
   else {
      device->isV4L2 = TRUE;
   }
}


BOOLEAN openDevice(Device device) {
   fprintf(stdout, "- Opening device in %p\n", device);

   /* open the video device */
   device->fd = EINTR_RETRY(open(device->deviceName, O_RDWR));
   if (device->fd < 0) {
      perror(device->deviceName);
      return FALSE;
   }
   fprintf(stdout, "    - Opened %s with fd=%d\n", device->deviceName, device->fd);


   /* try to lock the device */
   if (EINTR_RETRY(flock(device->fd, LOCK_EX | LOCK_NB)) < 0) {
      perror("FLOCK");
      fprintf(stdout, "    * Can't lock device\n");
      return FALSE;
   }

   /* check for a valid device */
   if (EINTR_RETRY(xioctl(device->fd, VIDIOCGCAP, &device->vcapability)) < 0) {
      perror("VIDIOCGCAP");
      return FALSE;
   }

   initializeDevice(device);

   showDeviceInformation(device);

   return setupDevice(device);
}


Device createDevice(int deviceID,
                    int width, int height,
                    int palette) {

   char deviceName[DEVICE_NAME_SIZE];

   strcpy(deviceName, videoDeviceBaseName);
   deviceName[DEVICE_NAME_SIZE - 2] = deviceID + '0';

   Device device;
   fprintf(stdout,
           "- Creating Device: id=%d, deviceName=%s, extent=%d@%d, palette=%d-%s\n",
           deviceID,
           deviceName,
           width, height,
           palette, paletteName(palette));

   device = (Device) malloc(SIZE_OF_DEVICE);
   if (device == 0) {
      fprintf(stdout, "    * Not enough memory\n");
      return 0;
   }
   fprintf(stdout, "    - Structure created in %p\n", device);

   initDevice(device,
              deviceName,
              width, height,
              palette);

   if (openDevice(device)) {
      return device;
   }
   else {
      closeDevice(device);
      return 0;
   }
}


BOOLEAN nextFrameMMap(Device device) {
  //fprintf(stdout, "- capturing buffer #%d\n", device->bufferIndex);

   /* send a request to begin capturing to the currently indexed buffer */
   if (EINTR_RETRY(xioctl(device->fd, VIDIOCMCAPTURE, &device->mmaps[device->bufferIndex])) < 0) {
   //if (xioctl(device->fd, VIDIOCMCAPTURE, &device->mmaps[device->bufferIndex]) < 0) {
      perror("VIDIOCMCAPTURE2");
      return FALSE;
   }

   /* move bufferIndex to the next frame */
   device->bufferIndex++;
   /* if bufferIndex is indexing beyond the last buffer set it to the first buffer */
   device->bufferIndex %= device->memoryBuffer.frames;

   //fprintf(stdout, "- syncing buffer #%d\n", device->bufferIndex);

   /* wait for the currently indexed frame to complete capture */
   if (EINTR_RETRY(xioctl(device->fd, VIDIOCSYNC, &(device->mmaps[device->bufferIndex]))) < 0) {
   //if (xioctl(device->fd, VIDIOCSYNC, &(device->mmaps[device->bufferIndex])) < 0) {
      /* sync request failed */
      perror("VIDIOCSYNC");
      return FALSE;
   }

   //fprintf(stdout, "- processing buffer #%d\n", device->bufferIndex);
   /* return the address of the frame data for the current buffer index */
   device->buffer = device->memoryMap + device->memoryBuffer.offsets[device->bufferIndex];

   return TRUE;
}



void closeDevice(Device device) {
   fprintf(stdout, "- Closing device in %p\n", device);

   if (device->deviceName) {
      free(device->deviceName);
      device->deviceName = 0;
   }
  
   if (device->buffer24) {
      free(device->buffer24);
      device->buffer24 = 0;
   }

   if (device->usingMMap) {
      if (device->mmaps) {
         free(device->mmaps);
         device->mmaps = 0;

         munmap(device->memoryMap, device->memoryBuffer.size);
      }
   }
   else {
      if (device->buffer) {
         free(device->buffer);
      }
   }

   if (device->fd > 0) {
      if (EINTR_RETRY(flock(device->fd, LOCK_UN)) < 0) {
         perror("FLOCK");
         fprintf(stdout, "    * Can't unlock device\n");
      }

      close(device->fd);
      device->fd = 0;
   }

   fprintf(stdout, "- Destroying device in %p\n", device);
   free(device);
}

BOOLEAN convertBufferTo24(Device device) {
   if (device->converterFunction == 0) {
      device->converterFunction = converterFunction(device->vpicture.palette);
      if (device->converterFunction == 0) {
         return FALSE;
      }
   }

   device->converterFunction(device->vwindow.width,
                             device->vwindow.height,
                             device->buffer,
                             device->buffer24);

   return TRUE;
}

BOOLEAN captureFrameFromDevice(Device device) {
   /* fprintf(stdout, "- Capturing from device in %p\n", device); */

   if (device->usingMMap) {
      if (!nextFrameMMap(device)) {
         return FALSE;
      }
   }
   else {
      /* fprintf(stdout, "- reading...\n"); */

      if (read(device->fd, device->buffer, device->imageSize) != device->imageSize) {
         fprintf(stdout, "\nThe device didn't answered the correct bytes.\n");
         return FALSE;
      }
   }

   return TRUE;
}

BOOLEAN nextFrameFromDevice(Device device) {
   if (!captureFrameFromDevice(device)) {
      return FALSE;
   }

   return convertBufferTo24(device);
   //return TRUE;
}


void savePPM(char* fileName, Device device) {
   char *src = device->buffer24;

   char red, green, blue;
   unsigned int i;

   FILE* ppmFile = fopen(fileName, "w+");

   fprintf(ppmFile, "P6\n%d %d 255\n", device->vwindow.width, device->vwindow.height);

   for (i = 0; i < device->vwindow.width * device->vwindow.height; i++) {
      red   = *src++;
      green = *src++;
      blue  = *src++;

      fputc(red,   ppmFile);
      fputc(green, ppmFile);
      fputc(blue,  ppmFile);
   }

   fclose(ppmFile);
}

int getPalette(Device device) {
   return device->vpicture.palette;
}


/*
void setBrightness(Device device, int brightness) {
   device->vpicture.brightness = brightness;
}

void setContrast(Device device, int contrast) {
   device->vpicture.contrast = contrast;
}

void setSaturation(Device device, int saturation) {
   device->vpicture.colour = saturation;
}

void setHue(Device device, int hue) {
   device->vpicture.hue = hue;
}
*/

BOOLEAN updatePicture(Device device) {
   if (EINTR_RETRY(xioctl(device->fd, VIDIOCSPICT, &device->vpicture)) < 0) {
      perror("VIDIOCSPICT");
      return FALSE;
   }

   return TRUE;
}


void describeDevice(int deviceID, char* deviceName) {
   int fd;
   char device[DEVICE_NAME_SIZE];

   memset(deviceName, 0, 32);
   
   strcpy(device, videoDeviceBaseName);
   device[DEVICE_NAME_SIZE - 2] = deviceID + '0';

   //fprintf(stdout, "** trying to open: %d...\n", deviceID);
   fd = EINTR_RETRY(open(device, O_RDWR));
   if (fd < 0) {
      return;
   }

   //fprintf(stdout, "** trying to lock: %d...\n", deviceID);
   /* try to lock the device */
   if (EINTR_RETRY(flock(fd, LOCK_EX | LOCK_NB)) < 0) {
      close(fd);
      return;
   }

   struct video_capability vcapability;

   //fprintf(stdout, "** trying to see if it's a video device: %d...\n", deviceID);
   if (EINTR_RETRY(xioctl(fd, VIDIOCGCAP, &vcapability)) < 0) {
      close(fd);
      return;
   }

   memcpy(deviceName, vcapability.name, 32);
   fprintf(stdout, "- Detected Device: id=%d name=%s\n", deviceID, deviceName);

   close(fd);
}
