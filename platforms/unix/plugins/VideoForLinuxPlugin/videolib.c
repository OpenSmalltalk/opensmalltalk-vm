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


void showDeviceInformation(Device device) {
   fprintf(stderr, "    - Device Information:\n");
   fprintf(stderr, "      ================================================================\n");
   fprintf(stderr, "       Name: %s\n", device->vcapability.name);
   fprintf(stderr, "       Type: %d\n", device->vcapability.type);

   if (device->vcapability.type & VID_TYPE_CAPTURE) {
      fprintf(stderr, "             Can capture to memory\n");
   }
   if (device->vcapability.type & VID_TYPE_TUNER) {
      fprintf(stderr, "             Has a tuner of some form\n");
   }
   if (device->vcapability.type & VID_TYPE_TELETEXT) {
      fprintf(stderr, "             Has teletext capability\n");
   }
   if (device->vcapability.type & VID_TYPE_OVERLAY) {
      fprintf(stderr, "             Can overlay its image onto the frame buffer\n");
   }
   if (device->vcapability.type & VID_TYPE_CHROMAKEY) {
      fprintf(stderr, "             Overlay is Chromakeyed\n");
   }
   if (device->vcapability.type & VID_TYPE_CLIPPING) {
      fprintf(stderr, "             Overlay clipping is supported\n");
   }
   if (device->vcapability.type & VID_TYPE_FRAMERAM) {
      fprintf(stderr, "             Overlay overwrites frame buffer memory\n");
   }
   if (device->vcapability.type & VID_TYPE_SCALES) {
      fprintf(stderr, "             The hardware supports image scaling\n");
   }
   if (device->vcapability.type & VID_TYPE_MONOCHROME) {
      fprintf(stderr, "             Image capture is grey scale only\n");
   }
   if (device->vcapability.type & VID_TYPE_SUBCAPTURE) {
      fprintf(stderr, "             Capture can be of only part of the image\n");
   }
   fprintf(stderr,
           "       Channels: %d  Audios: %d  MinExtent: %d@%d  MaxExtent: %d@%d\n",
           device->vcapability.channels,
           device->vcapability.audios,
           device->vcapability.minwidth,
           device->vcapability.minheight,
           device->vcapability.maxwidth,
           device->vcapability.maxheight);
   fprintf(stderr, "      ================================================================\n");

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

   device->haveTuner = FALSE;
   device->isBttv    = FALSE;

   device->currentChannel = 0;
}


void setupMMap(Device device) {
   int i;
   int mmapsSize;
   device->usingMMap = FALSE;

   fprintf(stderr, "    - Seting up MMAP for device %p\n", device);

   if (EINTR_RETRY(ioctl(device->fd, VIDIOCGMBUF, &device->memoryBuffer)) < 0) {
      /* failed to retrieve information about capture memory space */
      perror("VIDIOCGMBUF");
      return;
   }

   fprintf(stderr, "        - The device has %d buffers\n", device->memoryBuffer.frames);

   /* obtain memory mapped area */
   device->memoryMap = (char*) mmap(0,
                                    device->memoryBuffer.size,
                                    PROT_READ /*| PROT_WRITE*/,
                                    MAP_SHARED, device->fd, 0);
   if (device->memoryMap < (char*)0) {
      fprintf(stderr, "        * Failed to retrieve pointer to memory mapped area\n");
      return;
   }

   /* allocate structures */
   mmapsSize = device->memoryBuffer.frames * 32 * 4 /* sizeof(struct video_mmap)*/;
   fprintf(stderr, "        - Allocing %d bytes\n", mmapsSize);
   device->mmaps = (struct video_mmap*) malloc(mmapsSize);

   if (device->mmaps == 0) {
      fprintf(stderr, "        * Not enough memory\n");
      return;
   }

   /* fill out the fields */
   for (i = 0; i < device->memoryBuffer.frames; i++) {
      fprintf(stderr, "        - Creating the mmap #%d\n", i);

      device->mmaps[i].frame  = i;
      device->mmaps[i].width  = device->vwindow.width;
      device->mmaps[i].height = device->vwindow.height;
      device->mmaps[i].format = device->vpicture.palette;
   }

   device->usingMMap = TRUE;
   /*device->usingMMap = FALSE; */
}


BOOLEAN startCaptureInBuffers(Device device) {
   int i;
   for (i = 0; i < (device->memoryBuffer.frames - 1); i++) {
      fprintf(stderr, "- Capturing buffer #%d (1st pass)\n", i);
      if (EINTR_RETRY(ioctl(device->fd, VIDIOCMCAPTURE, &device->mmaps[i])) < 0) {
      //if (ioctl(device->fd, VIDIOCMCAPTURE, &device->mmaps[i]) < 0) {
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
      fprintf(stderr, "* Out of memory.\n");
      return FALSE;
   }

   return TRUE;
}


BOOLEAN deviceFindAndSetTuner(Device device) {
   int tunerNumber = -1;
   BOOLEAN found = FALSE;
   int i;

   for (i = 0; i < device->vchannel.tuners; i++ ) {
      device->vtuner.tuner = i;

      if (EINTR_RETRY(ioctl(device->fd, VIDIOCGTUNER, &device->vtuner)) >= 0 ) {
        if (device->vtuner.flags & VIDEO_TUNER_PAL) {
           found = TRUE;
           tunerNumber = i;
           break;
        }
      }
   }

   if (found) {
      BOOLEAN mustChange = FALSE;

      device->vtuner.tuner = tunerNumber;

      if (device->vtuner.mode != VIDEO_MODE_PAL) {
         mustChange = TRUE;
         device->vtuner.mode = VIDEO_MODE_PAL;
      }

      if (mustChange) {
         if (EINTR_RETRY(ioctl(device->fd, VIDIOCSTUNER, &device->vtuner)) < 0 ) {
            perror("VIDIOCSTUNER");
            return FALSE;
         }


         device->vchannel.channel = device->currentChannel;
         device->vchannel.norm    = VIDEO_MODE_PAL;

         if (EINTR_RETRY(ioctl(device->fd, VIDIOCSCHAN, &device->vchannel )) < 0 ) {
            perror("VIDIOCSCHAN");
            return FALSE;
         }

         /* vidin->numtuners = device->vchannel.tuners */;
      }
   }

   if (device->vchannel.tuners > 0) {
      device->vtuner.tuner = tunerNumber;

      if (EINTR_RETRY(ioctl(device->fd, VIDIOCGTUNER, &device->vtuner)) < 0 ) {
         perror("VIDIOCGTUNER");
         return FALSE;
      }

      fprintf(stderr, "    - Using tuner \"%s\"\n", device->vtuner.name);
      fprintf(stderr, "        - Range %ld %ld \n", device->vtuner.rangelow, device->vtuner.rangehigh);
      fprintf(stderr, "        - Signal=%d\n", device->vtuner.signal);

      if (device->vtuner.mode == VIDEO_MODE_PAL) {
         fprintf(stderr, "        - The tuner is in PAL mode\n");
      }
      else if (device->vtuner.mode == VIDEO_MODE_NTSC) {
         fprintf(stderr, "        - The tuner is in NTSC mode\n");
      }
      else if (device->vtuner.mode == VIDEO_MODE_SECAM) {
         fprintf(stderr, "        - The tuner is in SECAM mode\n");
      }
      else if (device->vtuner.mode == VIDEO_MODE_AUTO) {
         fprintf(stderr, "        - The tuner auto switches, or mode does not apply\n");
      }
      else {
         fprintf(stderr, "        * The tuner is in UNDEFINED mode!\n");
      }

      if (device->vtuner.flags & VIDEO_TUNER_PAL) {
         fprintf(stderr, "        - PAL tuning is supported\n");
      }
      if (device->vtuner.flags & VIDEO_TUNER_NTSC) {
         fprintf(stderr, "        - NTSC tuning is supported\n");
      }
      if (device->vtuner.flags & VIDEO_TUNER_SECAM) {
         fprintf(stderr, "        - SECAM tuning is supported\n");
      }
      if (device->vtuner.flags & VIDEO_TUNER_LOW) {
         fprintf(stderr, "        - Frequency is in a lower range\n");
      }
      if (device->vtuner.flags & VIDEO_TUNER_NORM) {
         fprintf(stderr, "        - The norm for this tuner is settable\n");
      }
      if (device->vtuner.flags & VIDEO_TUNER_STEREO_ON) {
         fprintf(stderr, "        - The tuner is seeing stereo audio\n");
      }
      if (device->vtuner.flags & VIDEO_TUNER_RDS_ON) {
         fprintf(stderr, "        - The tuner is seeing a RDS datastream\n");
      }
      if (device->vtuner.flags & VIDEO_TUNER_MBS_ON) {
         fprintf(stderr, "        - The tuner is seeing a MBS datastream\n");
      }
   }

   /* device->tunerlow = (device->vtuner.flags & VIDEO_TUNER_LOW) ? 1 : 0; */
   /* vidin->hastuner = 1; */

   return TRUE;
}


BOOLEAN deviceSetChannel(Device device, int channel) {
   if (channel >= device->vcapability.channels) {
      fprintf(stderr,
              "videoinput: Requested input number %d not valid, max is %d.\n",
              channel,
              device->vcapability.channels );
      return FALSE;
   }

   device->vchannel.channel = channel;
   if (EINTR_RETRY(ioctl(device->fd, VIDIOCGCHAN, &device->vchannel)) < 0 ) {
      perror("VIDIOCGCHAN");
      return FALSE;
   }
   
   device->vchannel.channel = channel;
   device->vchannel.norm    = VIDEO_MODE_PAL;

   if (EINTR_RETRY(ioctl(device->fd, VIDIOCSCHAN, &device->vchannel)) < 0 ) {
      perror("VIDIOCSCHAN");
      return FALSE;
   }

   device->currentChannel = channel;
   if(EINTR_RETRY(ioctl(device->fd, VIDIOCGCHAN, &device->vchannel)) < 0 ) {
      perror("VIDIOCGCHAN");
      return FALSE;
   }

   /* Once we've set the input, go look for a tuner. */
   if (!deviceFindAndSetTuner(device)) {
      return FALSE;
   }

   return TRUE;
}


BOOLEAN setupTuner(Device device) {
   int i;
   /* Check if this is a bttv-based card.  Code taken from xawtv. */
#define BTTV_VERSION            _IOR('v' , BASE_VIDIOCPRIVATE+6, int)
   /* dirty hack time / v4l design flaw -- works with bttv only
    * this adds support for a few less common PAL versions */
   if (!(EINTR_RETRY(ioctl(device->fd, BTTV_VERSION, &i)) < 0) ) {
      device->isBttv = TRUE;
      fprintf(stderr, "    - The device is is a BTTV\n");
   }
#undef BTTV_VERSION

   /* on initialization set to channel 0 */
   if (!deviceSetChannel(device, 0)) {
      return FALSE;
   }


   /* test for audio. see: ~/Video4Linux/tvtime-0.9.12/src/videoinput.c line 581 */

   return TRUE;
}



BOOLEAN setupDevice(Device device) {
   BOOLEAN change;
   fprintf(stderr, "- Seting up device %p\n", device);


   /* check (again) for a valid device */
   if (!(device->vcapability.type & VID_TYPE_CAPTURE)) {
      fprintf(stderr, "    * The device can't capture video\n");
      return FALSE;
   }

   if (device->vcapability.channels == 0) {
      fprintf(stderr, "    * The device hasn't inputs\n");
      return FALSE;
   }

   if (device->vcapability.type & VID_TYPE_TUNER) {
      device->haveTuner = TRUE;
   }

   /* ---------------------------------------------------------------------- */
   /* tuner setup */
   if (device->haveTuner) {
      if (!setupTuner(device)) {
         return FALSE;
      }
   }
   /* ---------------------------------------------------------------------- */


   /* ---------------------------------------------------------------------- */
   /* let's try to change the capture width & height */
   change = FALSE;
   if (EINTR_RETRY(ioctl(device->fd, VIDIOCGWIN, &device->vwindow)) < 0) {
      perror("VIDIOCGWIN1");
      return FALSE;
   }

   if (device->desiredWidth && (device->vwindow.width != device->desiredWidth)) {
     fprintf(stderr, "    - Changing the width from %d to %d\n", device->vwindow.width, device->desiredWidth);

     device->vwindow.width = device->desiredWidth;
     change = TRUE;
   }
   if (device->desiredHeight && (device->vwindow.height != device->desiredHeight)) {
     fprintf(stderr, "    - Changing the height from %d to %d\n", device->vwindow.height, device->desiredHeight);

     device->vwindow.height = device->desiredHeight;
     change = TRUE;
   }

   if (change) {
      if (EINTR_RETRY(ioctl(device->fd, VIDIOCSWIN, &device->vwindow)) < 0) {
         perror("VIDIOCGWIN2");
         return FALSE;
      }

      if (EINTR_RETRY(ioctl(device->fd, VIDIOCGWIN, &device->vwindow)) < 0) {
         perror("VIDIOCGWIN3");
         return FALSE;
      }
      if (device->desiredWidth != device->vwindow.width) {
         fprintf(stderr,
                 "    * The device can't change the capture width (now=%d)\n",
                 device->vwindow.width);
         return FALSE;
      }
      if (device->desiredHeight != device->vwindow.height) {
         fprintf(stderr,
                 "    * The device can't change the capture height (now=%d)\n",
                 device->vwindow.height);
         return FALSE;
      }

   }

   fprintf(stderr,
           "    - Extent=%d@%d\n",
           device->vwindow.width,
           device->vwindow.height);

   if (EINTR_RETRY(ioctl(device->fd, VIDIOCGPICT, &device->vpicture)) < 0) {
      perror("VIDIOCGPICT");
      return FALSE;
   }

   fprintf(stderr,
           "    - Brightness=%d, Contrast=%d, Saturation=%d, Hue=%d\n",
           getBrightness(device),
           getContrast(device),
           getSaturation(device),
           getHue(device));
   /* ---------------------------------------------------------------------- */


   /* ---------------------------------------------------------------------- */
   /* let's try to change the bit depth and palette */
   if (device->desiredPalette && (device->vpicture.palette != device->desiredPalette)) {
      fprintf(stderr,
              "    - Changing the palette from %d (%s) to %d (%s) and depth from %d to %d\n",
              device->vpicture.palette,
              paletteName(device->vpicture.palette),
              device->desiredPalette,
              paletteName(device->desiredPalette),
              device->vpicture.depth,
              paletteDepth(device->desiredPalette));

      device->vpicture.palette = device->desiredPalette;
      device->vpicture.depth   = paletteDepth(device->desiredPalette);

      if (EINTR_RETRY(ioctl(device->fd, VIDIOCSPICT, &device->vpicture)) < 0) {
         perror("VIDIOCSPICT");
         return FALSE;
      }
      if (paletteDepth(device->desiredPalette) != device->vpicture.depth) {
         fprintf(stderr, "    * The device can't change the depth\n");
         return FALSE;
      }
      if (device->desiredPalette != device->vpicture.palette) {
         fprintf(stderr, "    * The device can't change the palette\n");
         return FALSE;
      }
   }

   fprintf(stderr,
           "    - Depth=%d Palette=%d (%s)\n",
           device->vpicture.depth,
           device->vpicture.palette,
           paletteName(device->vpicture.palette));
   /* ---------------------------------------------------------------------- */

   device->imageSize = (int) device->vwindow.width * device->vwindow.height * (paletteBytesPerPixel(device->vpicture.palette));
   device->buffer24  = (char*) malloc(device->vwindow.width * device->vwindow.height * 3);

   if (device->forceRead) {
      fprintf(stderr, "    - Capturing using (forced) read()\n");
      if (!switchToRead(device)) {
         return FALSE;
      }
   }
   else {
      setupMMap(device);

      if (device->usingMMap) {
         fprintf(stderr, "    - Capturing using mmap()\n");
         if (!startCaptureInBuffers(device)) {
            fprintf(stderr, "    * Falling back to read()\n");
            if (!switchToRead(device)) {
               return FALSE;
            }
         }
      }
      else {
         fprintf(stderr, "    - Capturing using read()\n");
         if (!switchToRead(device)) {
            return FALSE;
         }
      }
   }

   return TRUE;
}


BOOLEAN openDevice(Device device) {
   fprintf(stderr, "- Opening device in %p\n", device);

   /* open the video device */
   device->fd = EINTR_RETRY(open(device->deviceName, O_RDWR));
   if (device->fd < 0) {
      perror(device->deviceName);
      return FALSE;
   }
   fprintf(stderr, "    - Opened %s with fd=%d\n", device->deviceName, device->fd);

   /* try to lock the device */
   if (EINTR_RETRY(flock(device->fd, LOCK_EX | LOCK_NB)) < 0) {
      perror("FLOCK");
      fprintf(stderr, "    * Can't lock device\n");
      return FALSE;
   }

   /* check for a valid device */
   if (EINTR_RETRY(ioctl(device->fd, VIDIOCGCAP, &device->vcapability)) < 0) {
      perror("VIDIOCGCAP");
      return FALSE;
   }

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
   fprintf(stderr,
           "- Creating Device: id=%d, deviceName=%s, extent=%d@%d, palette=%d-%s\n",
           deviceID,
           deviceName,
           width, height,
           palette, paletteName(palette));

   device = (Device) malloc(SIZE_OF_DEVICE);
   if (device == 0) {
      fprintf(stderr, "    * Not enough memory\n");
      return 0;
   }
   fprintf(stderr, "    - Structure created in %p\n", device);

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
   /* fprintf(stderr, "- capturing buffer #%d\n", device->bufferIndex); */

   /* send a request to begin capturing to the currently indexed buffer */
   //if (EINTR_RETRY(ioctl(device->fd, VIDIOCMCAPTURE, &device->mmaps[device->bufferIndex])) < 0) {
   if (ioctl(device->fd, VIDIOCMCAPTURE, &device->mmaps[device->bufferIndex]) < 0) {
      perror("VIDIOCMCAPTURE2");
      return FALSE;
   }

   /* move bufferIndex to the next frame */
   device->bufferIndex++;
   /* if bufferIndex is indexing beyond the last buffer set it to the first buffer */
   device->bufferIndex %= device->memoryBuffer.frames;

   /* fprintf(stderr, "- syncing buffer #%d\n", device->bufferIndex); */

   /* wait for the currently indexed frame to complete capture */
   if (EINTR_RETRY(ioctl(device->fd, VIDIOCSYNC, &(device->mmaps[device->bufferIndex]))) < 0) {
   //if (ioctl(device->fd, VIDIOCSYNC, &(device->mmaps[device->bufferIndex])) < 0) {
      /* sync request failed */
      perror("VIDIOCSYNC");
      return FALSE;
   }

   /* fprintf(stderr, "- processing buffer #%d\n", device->bufferIndex); */
   /* return the address of the frame data for the current buffer index */
   device->buffer = device->memoryMap + device->memoryBuffer.offsets[device->bufferIndex];

   return TRUE;
}



void closeDevice(Device device) {
   fprintf(stderr, "- Closing device in %p\n", device);

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
         fprintf(stderr, "    * Can't unlock device\n");
      }

      close(device->fd);
      device->fd = 0;
   }

   fprintf(stderr, "- Destroying device in %p\n", device);
   free(device);
}


BOOLEAN nextFrameFromDevice(Device device) {
   /* fprintf(stderr, "- Capturing from device in %p\n", device); */

   if (device->usingMMap) {
      if (!nextFrameMMap(device)) {
         return FALSE;
      }
   }
   else {
      /* fprintf(stderr, "- reading...\n"); */

      if (read(device->fd, device->buffer, device->imageSize) != device->imageSize) {
         fprintf(stderr, "\nThe device didn't answered the correct bytes.\n");
         return FALSE;
      }
   }

   if (paletteConvert(device->vpicture.palette,
                      device->vwindow.width,
                      device->vwindow.height,
                      device->buffer,
                      device->buffer24)) {
      return TRUE;
   }
   else {
      return FALSE;
   }
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


BOOLEAN updatePicture(Device device) {
   if (EINTR_RETRY(ioctl(device->fd, VIDIOCSPICT, &device->vpicture)) < 0) {
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

   //fprintf(stderr, "** trying to open: %d...\n", deviceID);
   fd = EINTR_RETRY(open(device, O_RDWR));
   if (fd < 0) {
      return;
   }

   //fprintf(stderr, "** trying to lock: %d...\n", deviceID);
   /* try to lock the device */
   if (EINTR_RETRY(flock(fd, LOCK_EX | LOCK_NB)) < 0) {
      close(fd);
      return;
   }

   struct video_capability vcapability;

   //fprintf(stderr, "** trying to see if it's a video device: %d...\n", deviceID);
   if (EINTR_RETRY(ioctl(fd, VIDIOCGCAP, &vcapability)) < 0) {
      close(fd);
      return;
   }

   memcpy(deviceName, vcapability.name, 32);
   fprintf(stderr, "- Detected Device: id=%d name=%s\n", deviceID, deviceName);

   close(fd);
}
