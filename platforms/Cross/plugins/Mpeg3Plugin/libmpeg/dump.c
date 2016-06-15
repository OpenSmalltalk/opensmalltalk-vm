#include "libmpeg3.h"
#include <stdlib.h>
#include <string.h>
#include <Types.h>
#include <Fonts.h>
#include <Memory.h>
#include <Windows.h>
#include <Quickdraw.h>
#include <TextEdit.h>
#include <Dialogs.h>
#include <QDOffscreen.h>
#include <Quickdraw.h>
#include <Memory.h>
#include <profiler.h>

void * memoryAllocate(int number,unsigned size);
void memoryFree(void *stuff);

int			strncasecmp(const char *str1, const char *str2, size_t nchars);
int			strcasecmp (const char *str1, const char *str2);
inline BitMap * GetPortBitMapForCopyBits (CGrafPtr w) { return &((GrafPtr)w)->portBits;}
inline Rect *GetPortBounds(CGrafPtr w,Rect *r) { *r = w->portRect; return &w->portRect;} 

void mpeg3video_init_scantables(mpeg3video_t *video);
WindowPtr	pWindow;
GWorldPtr   gpGWOffScreen = NULL;				
long counter = 0;

#define BUFSIZE 1000000
int main2();

int main ()
{
	int ret;
	Rect windRect;
	long start,end,amount;
	
	/* Initialize all the needed managers. */
	InitGraf(&qd.thePort);
	InitFonts();
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(nil);
	InitCursor();

	//ProfilerInit(collectDetailed, bestTimeBase, 1000, 50);
	//ProfilerSetStatus(true);

	windRect = qd.screenBits.bounds;
	InsetRect(&windRect, 50, 50);
	pWindow = NewCWindow(nil, &windRect, "\pMpeg", true, documentProc, (WindowPtr) -1, false, 0);
    
    start = TickCount();
    main2();
    end = TickCount();
    amount = end - start;
    fprintf(stderr, "Time taken %d memoryAllocator %d \n", amount,counter);

   //	ProfilerDump("\pProfile.out");
     
    do {
	} while (!Button());


}

int main2()
{
	mpeg3_t *file;
	int i, result = 0;
	unsigned char *output, **output_rows;
	float *audio_output_f;
	short *audio_output_i;
	long 			total_samples = 0;
	Rect 			sourceRect;
	OSErr           error;
	PixMapHandle 	hPixmap;
    Ptr       		gBaseLocation;
	long			targetRowBytes;
	
	file = mpeg3_open("randomAlien.mpg");
	if(file)
	{

		mpeg3_set_cpus(file, 1);
  		//audio_output_f = (float *) memoryAllocate(1,BUFSIZE * sizeof(float)); 
		//audio_output_i = (short *) memoryAllocate(1,BUFSIZE * sizeof(short));
 		//mpeg3_set_sample(file, 11229518, 0); 
        //result = mpeg3_read_audio(file, audio_output_f, 0, 0, BUFSIZE, 0); 
    	// result = mpeg3_read_audio(file, 0, audio_output_i, 1, BUFSIZE, 0);
 		// fwrite(audio_output_i, BUFSIZE, 1, stdout);

  		//mpeg3_set_frame(file, 1000, 0);
  		
		sourceRect.top = 0;
		sourceRect.left = 0;
		sourceRect.bottom = mpeg3_video_height(file, 0);
		sourceRect.right = mpeg3_video_width(file, 0);

		error = NewGWorld (&gpGWOffScreen, 32, &sourceRect, NULL, NULL,  keepLocal);
		if (error != noErr)
			{
		    DebugStr ("\pUnable to allocate off screen image");
		 	}
	 
		hPixmap = GetGWorldPixMap (gpGWOffScreen);
		error = LockPixels (hPixmap);
		gBaseLocation = GetPixBaseAddr(hPixmap);
		targetRowBytes = ((**hPixmap).rowBytes & 0x3FFF)/4;

  		output_rows = (unsigned char **) memoryAllocate(1,sizeof(unsigned char*) * mpeg3_video_height(file, 0));
  		for(i = 0; i < mpeg3_video_height(file, 0); i++)
  			output_rows[i] = (unsigned char*) gBaseLocation + i * targetRowBytes*4;

		for (i=0;i < mpeg3_video_frames(file, 0);i++) {
			result = mpeg3_read_frame(file, 
 					output_rows, 
 					0, 
 					0, 
 					mpeg3_video_width(file, 0), 
					mpeg3_video_height(file, 0), 
 					mpeg3_video_width(file, 0), 
 					mpeg3_video_height(file, 0), 
					MPEG3_RGBAF8888, 
 					0);
  	    	CopyBits (GetPortBitMapForCopyBits(gpGWOffScreen), GetPortBitMapForCopyBits(GetWindowPort(pWindow)), &sourceRect, &sourceRect, srcCopy, NULL); 
		}
		UnlockPixels (hPixmap);
		DisposeGWorld(gpGWOffScreen);
        memoryFree(output_rows);
        
		fprintf(stderr, "Audio streams: %d\n", mpeg3_total_astreams(file));
		for(i = 0; i < mpeg3_total_astreams(file); i++)
		{
			 fprintf(stderr, "  Stream %d: channels %d sample rate %d total samples %ld\n", 
				i, 
				mpeg3_audio_channels(file, i), 
				mpeg3_sample_rate(file, i),
				mpeg3_audio_samples(file, i));
		}
		fprintf(stderr, "Video streams: %d\n", mpeg3_total_vstreams(file));
		for(i = 0; i < mpeg3_total_vstreams(file); i++)
		{
			fprintf(stderr, "  Stream %d: width %d height %d frame rate %0.3f total frames %ld\n", 
				i, 
				mpeg3_video_width(file, i), 
				mpeg3_video_height(file, i), 
				mpeg3_frame_rate(file, i),
				mpeg3_video_frames(file, i));
		}
		
		mpeg3_close(file);
	}
	return 0;
}
int			strncasecmp(const char *str1, const char *str2, size_t nchars)
{
    return strncmp(str1,str2,nchars);
}
int			strcasecmp (const char *str1, const char *str2) {
    return strcmp(str1,str2);
}


void * memoryAllocate(int number,unsigned size) {
    char * stuff;
    stuff = NewPtrClear(size*number);
    if (stuff == 0L) 
        Debugger();
    counter ++;
    return stuff;
}

void memoryFree(void *stuff) {
    counter --;
    DisposePtr((char *)stuff);
}

int bzero(char *block,long size) {
    BlockZero(block,size);
}

