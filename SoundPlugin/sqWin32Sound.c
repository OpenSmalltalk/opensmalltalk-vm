/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Sound.c
*   CONTENT: Sound management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*   RCSID:   $Id: sqWin32Sound.c,v 1.5 2003/11/02 19:52:40 andreasraab Exp $
*
*   NOTES:   For now we're supporting both, the DirectSound and the win32
*            based interface. In the future we'll switch to DSound exclusively.
*
*****************************************************************************/
#include <windows.h>
#include <mmsystem.h>
#include "sq.h"
#include "SoundPlugin.h"

#ifdef DEBUG
#warning "DEBUG printing enabled"
#define DPRINTF(x) warnPrintf x
#else
#define DPRINTF(x)
#endif

#ifndef NO_SOUND

#ifndef NO_RCSID
  static char RCSID[]="$Id: sqWin32Sound.c,v 1.5 2003/11/02 19:52:40 andreasraab Exp $";
#endif

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
#ifndef NO_DIRECT_SOUND
/* The new DirectSound based implementation of the sound primitives */
#define _LPCWAVEFORMATEX_DEFINED
#undef WINNT
#define DIRECTSOUND_VERSION 0x0600	/* use DirectSound 6.0 */
#ifdef __MINGW32__
#define HMONITOR_DECLARED
#endif
#include <dsound.h>

static int fUsingDirectSound = 0; /* when we're in direct sound */

LPDIRECTSOUND lpdSound = NULL;
LPDIRECTSOUNDBUFFER lpdPrimaryBuffer = NULL;
LPDIRECTSOUNDBUFFER lpdPlayBuffer = NULL;
WAVEFORMATEX waveOutFormat;
HANDLE hPlayEvent = NULL;
HANDLE hPlayThread = NULL;
int playBufferSize = 0;
int playBufferIndex = 0;
int playBufferAvailable = 0;
int playTerminate = 0;
int playSemaphore = -1;

LPDIRECTSOUNDCAPTURE lpdCapture = NULL;
LPDIRECTSOUNDCAPTUREBUFFER lpdRecBuffer = NULL;
WAVEFORMATEX waveInFormat;
HANDLE hRecEvent = NULL;
HANDLE hRecThread = NULL;
int recBufferSize = 0;
int recBufferIndex = 0;
int recBufferPosition = 0;
int recBufferAvailable = 0;
int recTerminate = 0;
int recSemaphore = -1;

/* module initialization/shutdown */
int dx_soundInit(void) {
  hRecEvent = CreateEvent( NULL, FALSE, FALSE, NULL );
  hPlayEvent = CreateEvent( NULL, FALSE, FALSE, NULL );
  return 1;
}

int dx_soundShutdown(void) {
  DPRINTF(("dx_soundShutDown\n"));
  dx_snd_StopPlaying();
  dx_snd_StopRecording();
  CloseHandle(hPlayEvent);
  CloseHandle(hRecEvent);
}

int dx_snd_StopPlaying(void) {
  playTerminate = 0;
  if(lpdPlayBuffer) {
    DPRINTF(("Shutting down DSound\n"));
    IDirectSoundBuffer_Stop(lpdPlayBuffer);
    IDirectSoundBuffer_Release(lpdPlayBuffer);
    lpdPlayBuffer = NULL;
  }
  if(lpdPrimaryBuffer) {
    IDirectSoundBuffer_Release(lpdPrimaryBuffer);
    lpdPrimaryBuffer = NULL;
  }
  if(lpdSound) {
    IDirectSound_Release(lpdSound);
    lpdSound = NULL;
  }
  if(hPlayThread) {
    ResetEvent(hPlayEvent);
    playTerminate = 1;
    SetEvent(hPlayEvent);
    WaitForSingleObject(hPlayThread, 100); /* wait until terminated */
    hPlayThread = NULL;
    playTerminate = 0;
  }
  ResetEvent(hPlayEvent);
  if(!lpdCapture) {
    fUsingDirectSound = 0; /* no longer */
  }
  return 1;
}

DWORD WINAPI playCallback( LPVOID ignored ) {
  while(1) {
    if(WaitForSingleObject(hPlayEvent, INFINITE) == WAIT_OBJECT_0) {
      if(playTerminate) {
	hPlayThread = NULL;
	DPRINTF(("playCallback shutdown\n"));
	dx_snd_StopPlaying();
	return 0; /* done playing */
      }
      playBufferAvailable = 1;
      playBufferIndex = ++playBufferIndex & 1;
      synchronizedSignalSemaphoreWithIndex(playSemaphore);
    }
  }
}

DWORD WINAPI recCallback( LPVOID ignored ) {
  while(1) {
    if(WaitForSingleObject(hRecEvent, INFINITE) == WAIT_OBJECT_0) {
      if(recTerminate) return 0; /* done playing */
      recBufferAvailable = 1;
      recBufferIndex = ++recBufferIndex & 1;
      synchronizedSignalSemaphoreWithIndex(recSemaphore);
    }
  }
}

/* sound output */
int dx_snd_AvailableSpace(void) {
  if(playBufferAvailable) {
    return playBufferSize;
  }
  return 0;
}

int dx_snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime)
{
  /* currently not supported */
  return 0;
}

int dx_snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{
  HRESULT hRes;
  int bytesWritten;
  DWORD dstLen;
  void *dstPtr;

  bytesWritten = waveOutFormat.nBlockAlign  * frameCount;

  if(bytesWritten > playBufferSize)
    bytesWritten = playBufferSize;

  if(bytesWritten < playBufferSize)
    return 0;

  DPRINTF(("[%d", frameCount));

  hRes = IDirectSoundBuffer_Lock(lpdPlayBuffer, 
				 playBufferSize * playBufferIndex,
				 playBufferSize, 
				 &dstPtr, &dstLen, 
				 NULL, NULL, 
				 0);
  if(FAILED(hRes)) {
    DPRINTF(("snd_Play: IDirectSoundBuffer_Lock failed (errCode: %x)\n", hRes));
    return 0;
  }
  /* mix in stuff */
  { 
    int i;
    short *shortSrc = (short*)(arrayIndex+startIndex);
    short *shortDst = (short*)dstPtr;
    dstLen /=2;
    DPRINTF(("|%d", dstLen));
    for(i=0;i<dstLen;i++) {
      *shortDst++ = *(shortSrc++);
    }
  }
  IDirectSoundBuffer_Unlock(lpdPlayBuffer, dstPtr, dstLen, NULL, 0);
  DPRINTF(("]"));
  playBufferAvailable = 0;
  return bytesWritten / waveOutFormat.nBlockAlign;
}

int dx_snd_PlaySilence(void) {
  /* no longer supported */
  return -1;
}

int dx_snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex) {
  DSBUFFERDESC dsbd;
  DSBPOSITIONNOTIFY  posNotify[2];
  LPDIRECTSOUNDNOTIFY lpdNotify = NULL;
  HRESULT hRes;
  DWORD threadID;
  int bytesPerFrame;
  int bufferSize;

  /* round up the size of the play buffers to multiple of 16 bytes*/
  bytesPerFrame = stereo ? 4 : 2;
  bufferSize = ((bytesPerFrame * frameCount) / 16) * 16;
  if((bufferSize != playBufferSize) || 
     (samplesPerSec != waveOutFormat.nSamplesPerSec) || 
     ((stereo == 0) != (waveOutFormat.nChannels == 1))) {
    /* format change */
    DPRINTF(("DXSound format change (%d, %d, %s)\n", frameCount, samplesPerSec, (stereo ? "stereo" : "mono")));
    dx_snd_StopPlaying();
  }

  if(lpdPlayBuffer) {
    /* keep playing */
    playTerminate = 0;
    playSemaphore = semaIndex; /* might have changed */
    DPRINTF(("Continuing DSound\n"));
    return 1;
  }

  DPRINTF(("Starting DSound\n"));
  if(!lpdSound) {
    /* Initialize DirectSound */
    DPRINTF(("# Creating lpdSound\n"));
    hRes = CoCreateInstance(&CLSID_DirectSound,
			    NULL, 
			    CLSCTX_INPROC_SERVER,
			    &IID_IDirectSound,
			    (void**)&lpdSound);
    if(FAILED(hRes)) {
      /* Well, well. If we can't create a DSound then we're
	 very likely to be on a non-DSound system (like NT3). */
      DPRINTF(("sndStart: CoCreateInstance() failed (errCode: %x)\n", hRes));
      DPRINTF(("Turning off DirectSound\n"));
      fUseDirectSound = 0;
      /* and try again */
      return snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
    }
    DPRINTF(("# Initializing lpdSound\n"));
    hRes = IDirectSound_Initialize(lpdSound, NULL);
    if(FAILED(hRes)) {
      DPRINTF(("sndStart: IDirectSound_Initialize() failed (errCode: %x)\n", hRes));
      IDirectSound_Release(lpdSound);
      lpdSound = NULL;
      DPRINTF(("Turning off DirectSound\n"));
      fUseDirectSound = 0;
      /* and try again */
      return snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
    }
    /* set the cooperative level (DSSCL_PRIORITY is recommended) */
    hRes = IDirectSound_SetCooperativeLevel(lpdSound, stWindow, DSSCL_PRIORITY);
    if(FAILED(hRes)) {
      DPRINTF(("sndStart: IDirectSound_SetCooperativeLevel failed (errCode: %x)\n", hRes));
      /* for now don't fail because of lack in cooperation */
    }
    /* grab the primary sound buffer for handling format changes */
    ZeroMemory(&dsbd, sizeof(dsbd));
    dsbd.dwSize = sizeof(dsbd);
    dsbd.dwFlags = DSBCAPS_PRIMARYBUFFER;
    DPRINTF(("# Creating primary buffer\n"));
    hRes = IDirectSound_CreateSoundBuffer(lpdSound, &dsbd, &lpdPrimaryBuffer, NULL);
    if(FAILED(hRes)) {
      DPRINTF(("sndStart: Failed to create primary buffer (errCode: %x)\n", hRes));
    }
  }

  fUsingDirectSound = 1; /* we are */
  playSemaphore = semaIndex;

  if(!hPlayThread) {
    /* create the playback notification thread */
    DPRINTF(("# Creating playback thread\n"));
    hPlayThread = CreateThread(NULL, 0, playCallback, NULL, 0, &threadID);
    if(hPlayThread == 0) {
      printLastError("sndStart: CreateThread failed");
      dx_snd_StopPlaying();
      DPRINTF(("Turning off DirectSound\n"));
      fUseDirectSound = 0;
      /* and try again */
      return snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
    }
    if(!SetThreadPriority(hPlayThread, THREAD_PRIORITY_HIGHEST))
      printLastError(TEXT("SetThreadPriority() failed"));
  }

  /* since we start from buffer 0 the first play index is one */
  playBufferIndex = 1; 

  /* round up the size of the play buffers to multiple of 16 bytes*/
  bytesPerFrame = stereo ? 4 : 2;
  playBufferSize = ((bytesPerFrame * frameCount) / 16) * 16;

  /* create the secondary sound buffer */
  dsbd.dwSize = sizeof(dsbd);
  dsbd.dwFlags = 
    DSBCAPS_CTRLPOSITIONNOTIFY |   /* position notification */
    DSBCAPS_GETCURRENTPOSITION2 |  /* accurate positioning */
    DSBCAPS_LOCSOFTWARE |          /* software buffers please */
    DSBCAPS_GLOBALFOCUS;           /* continue playing */
  dsbd.dwBufferBytes = 2 * playBufferSize;
  dsbd.dwReserved = 0;
    waveOutFormat.wFormatTag = WAVE_FORMAT_PCM;
    waveOutFormat.nChannels = stereo ? 2 : 1;
    waveOutFormat.nSamplesPerSec = samplesPerSec;
    waveOutFormat.nAvgBytesPerSec = samplesPerSec * bytesPerFrame;
    waveOutFormat.nBlockAlign = bytesPerFrame;
    waveOutFormat.wBitsPerSample = 16;
  dsbd.lpwfxFormat = &waveOutFormat;

  /* set the primary buffer format */
  if(lpdPrimaryBuffer) {
    hRes = IDirectSoundBuffer_SetFormat(lpdPrimaryBuffer, &waveOutFormat);
    if(FAILED(hRes)) {
      DPRINTF(("sndStart: Failed to set primary buffer format (errCode: %x)\n", hRes));
    }
  }

  DPRINTF(("# Creating play buffer\n"));
  hRes = IDirectSound_CreateSoundBuffer(lpdSound, &dsbd, &lpdPlayBuffer, NULL);
  if(FAILED(hRes)) {
    DPRINTF(("sndStart: IDirectSound_CreateSoundBuffer() failed (errCode: %x)\n", hRes));
    dx_snd_StopPlaying();
    DPRINTF(("Turning off DirectSound\n"));
    fUseDirectSound = 0;
    /* and try again */
    return snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
  }

  /* setup notifications */
  hRes = IDirectSoundBuffer_QueryInterface(lpdPlayBuffer,
					   &IID_IDirectSoundNotify, 
					   (void**)&lpdNotify );
  if(FAILED(hRes)) {
    DPRINTF(("sndStart: QueryInterface(IDirectSoundNotify) failed (errCode: %x)\n"));
    dx_snd_StopPlaying();
    DPRINTF(("Turning off DirectSound\n"));
    fUseDirectSound = 0;
    /* and try again */
    return snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
  }
  posNotify[0].dwOffset = 1 * playBufferSize - 1;
  posNotify[1].dwOffset = 2 * playBufferSize - 1;
  posNotify[0].hEventNotify = hPlayEvent;
  posNotify[1].hEventNotify = hPlayEvent;
  DPRINTF(("# Setting notifications\n"));
  hRes = IDirectSoundNotify_SetNotificationPositions(lpdNotify, 2, posNotify);
  IDirectSoundNotify_Release(lpdNotify);
  if(FAILED(hRes)) {
    DPRINTF(("sndStart: IDirectSoundNotify_SetNotificationPositions() failed (errCode: %x)\n", hRes));
    dx_snd_StopPlaying();
    DPRINTF(("Turning off DirectSound\n"));
    fUseDirectSound = 0;
    /* and try again */
    return snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
  }

  DPRINTF(("# Starting to play buffer\n"));
  hRes = IDirectSoundBuffer_Play(lpdPlayBuffer, 0, 0, DSBPLAY_LOOPING);
  if(FAILED(hRes)) {
    DPRINTF(("sndStart: IDirectSoundBuffer_Play() failed (errCode: %x)\n", hRes));
    dx_snd_StopPlaying();
    DPRINTF(("Turning off DirectSound\n"));
    fUseDirectSound = 0;
    /* and try again */
    return snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
  }
  return 1;
}

int dx_snd_Stop(void) {
  dx_snd_StopPlaying();
  return 1;
}

/* sound input */
int dx_snd_SetRecordLevel(int level) {
  /* not supported */
  return 0;
}

int dx_snd_StartRecording(int samplesPerSec, int stereo, int semaIndex) {
  DSCBUFFERDESC dscb;
  DSBPOSITIONNOTIFY  posNotify[2];
  LPDIRECTSOUNDNOTIFY lpdNotify = NULL;
  HRESULT hRes;
  DWORD threadID;
  int bytesPerFrame;

  if(lpdRecBuffer) {
    snd_StopRecording();
  }

  if(!lpdCapture) {
    hRes = CoCreateInstance(&CLSID_DirectSoundCapture,
			    NULL, 
			    CLSCTX_INPROC_SERVER,
			    &IID_IDirectSoundCapture,
			    (void**)&lpdCapture);
    if(FAILED(hRes)) {
      DPRINTF(("snd_StartRec: CoCreateInstance() failed (errCode: %x)\n", hRes));
      return 0;
    }
    hRes = IDirectSoundCapture_Initialize(lpdCapture, NULL);
    if(FAILED(hRes)) {
      DPRINTF(("snd_StartRec: IDirectSoundCapture_Initialize() failed (errCode: %x)\n", hRes));
      lpdCapture = NULL;
      return 0;
    }
  }

  fUsingDirectSound = 1; /* we are */

  /* create the recording notification thread */
  recSemaphore = semaIndex;
  hRecThread = CreateThread(NULL, 0, recCallback, NULL, 0, &threadID);
  if(hRecThread == 0) {
    printLastError("snd_StartRec: CreateThread failed");
    snd_StopRecording();
    return 0;
  }
  if(!SetThreadPriority(hRecThread, THREAD_PRIORITY_HIGHEST))
    printLastError(TEXT("SetThreadPriority() failed"));

  /* since we start from buffer 0 the first recording index is one */
  recBufferIndex = 1;

  /* round up the size of the record buffers to multiple of 16 bytes*/
  bytesPerFrame = stereo ? 4 : 2;
  recBufferSize = ((bytesPerFrame * 1024) / 16) * 16;

  /* create the secondary sound buffer */
  dscb.dwSize = sizeof(dscb);
  dscb.dwFlags = DSCBCAPS_WAVEMAPPED;
  dscb.dwBufferBytes = 2 * recBufferSize;
  dscb.dwReserved = 0;
    waveInFormat.wFormatTag = WAVE_FORMAT_PCM;
    waveInFormat.nChannels = stereo ? 2 : 1;
    waveInFormat.nSamplesPerSec = samplesPerSec;
    waveInFormat.nAvgBytesPerSec = samplesPerSec * bytesPerFrame;
    waveInFormat.nBlockAlign = bytesPerFrame;
    waveInFormat.wBitsPerSample = 16;
  dscb.lpwfxFormat = &waveInFormat;
  hRes = IDirectSoundCapture_CreateCaptureBuffer(lpdCapture, &dscb, &lpdRecBuffer, NULL);
  if(FAILED(hRes)) {
    DPRINTF(("snd_StartRec: IDirectSoundCapture_CreateCaptureBuffer() failed (errCode: %x)\n", hRes));
    return 0;
  }
  hRes = IDirectSoundCaptureBuffer_QueryInterface(lpdRecBuffer,
						  &IID_IDirectSoundNotify, 
						  (void**)&lpdNotify );
  if(FAILED(hRes)) {
    DPRINTF(("snd_StartRec: QueryInterface(IDirectSoundNotify) failed (errCode: %x)\n"));
    snd_StopRecording();
    return 0;
  }
  posNotify[0].dwOffset = 1 * recBufferSize - 1;
  posNotify[1].dwOffset = 2 * recBufferSize - 1;
  posNotify[0].hEventNotify = hRecEvent;
  posNotify[1].hEventNotify = hRecEvent;
  hRes = IDirectSoundNotify_SetNotificationPositions(lpdNotify, 2, posNotify);
  IDirectSoundNotify_Release(lpdNotify);
  if(FAILED(hRes)) {
    DPRINTF(("snd_StartRec: IDirectSoundNotify_SetNotificationPositions() failed (errCode: %x)\n", hRes));
    snd_StopRecording();
    return 0;
  }
  hRes = IDirectSoundCaptureBuffer_Start(lpdRecBuffer, DSCBSTART_LOOPING);
  if(FAILED(hRes)) {
    DPRINTF(("snd_StartRec: IDirectSoundCaptureBuffer_Start() failed (errCode: %x)\n", hRes));
    snd_StopRecording();
    return 0;
  }

  return 0;
}

int dx_snd_StopRecording(void) {
  if(lpdRecBuffer) {
    IDirectSoundCaptureBuffer_Stop(lpdRecBuffer);
    IDirectSoundCaptureBuffer_Release(lpdRecBuffer);
    lpdRecBuffer = NULL;
  }
  if(lpdCapture) {
    IDirectSoundCapture_Release(lpdCapture);
    lpdCapture = NULL;
  }
  if(hRecThread) {
    ResetEvent(hRecEvent);
    recTerminate = 1;
    SetEvent(hRecEvent);
    WaitForSingleObject(hRecThread, 100); /* wait until terminated */
    hRecThread = NULL;
    recTerminate = 0;
  }
  ResetEvent(hRecEvent);
  if(!lpdSound) {
    fUsingDirectSound = 0; /* no longer */
  }
  return 0;
}

double dx_snd_GetRecordingSampleRate(void) {
  if(!lpdRecBuffer) return 0.0;
  return (double) waveInFormat.nSamplesPerSec;
}

int dx_snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes) {
  /* if data is available, copy as many sample slices as possible into the
     given buffer starting at the given slice index. do not write past the
     end of the buffer, which is buf + bufferSizeInBytes. return the number
     of slices (not bytes) copied. a slice is one 16-bit sample in mono
     or two 16-bit samples in stereo. */
  int bytesPerSlice = (waveInFormat.nChannels * 2);
  int bytesCopied;
  char *srcPtr, *dstPtr;
  HRESULT hRes;
  DWORD srcLen;

  if(!lpdRecBuffer) {
    /* not recording */
    return 0;
  }
  if(!recBufferAvailable) {
    /* no data available */
    return 0;
  }
  bytesCopied = bufferSizeInBytes - (startSliceIndex * bytesPerSlice);
  if(bytesCopied > (recBufferSize - recBufferPosition)) 
    bytesCopied = recBufferSize - recBufferPosition;

  hRes = IDirectSoundCaptureBuffer_Lock(lpdRecBuffer, 
					(recBufferSize * recBufferIndex),
					recBufferSize,
					(void*)&srcPtr, &srcLen,
					NULL, NULL,
					0);
  if(FAILED(hRes)) {
    DPRINTF(("snd_Rec: IDirectSoundCaptureBuffer_Lock() failed (errCode: %x)\n", hRes));
    return 0;
  }

  dstPtr = (char*)(buf + startSliceIndex * bytesPerSlice);
  memcpy(dstPtr, srcPtr+recBufferPosition, bytesCopied);
  recBufferPosition = (recBufferPosition + bytesCopied) % recBufferSize;
  if(recBufferPosition == 0) {
    recBufferAvailable = 0;
  }
  hRes = IDirectSoundCaptureBuffer_Unlock(lpdRecBuffer,
					  srcPtr, srcLen,
					  NULL, 0);
  if(FAILED(hRes)) {
    DPRINTF(("snd_Rec: IDirectSoundCaptureBuffer_Unlock() failed (errCode: %x)\n", hRes));
  }

  return bytesCopied / bytesPerSlice;
}


/* NOTE: Both of the below functions use the default wave out device */
void dx_snd_Volume(double *left, double *right)
{
  DWORD volume = (DWORD)-1;

  waveOutGetVolume((HWAVEOUT)0, &volume);
  *left = (volume & 0xFFFF) / 65535.0;
  *right = (volume >> 16) / 65535.0;
}

void dx_snd_SetVolume(double left, double right)
{
  DWORD volume;

  if(left < 0.0) left = 0.0;
  if(left > 1.0) left = 1.0;
  volume = (int)(left * 0xFFFF);
  if(right < 0.0) right = 0.0;
  if(right > 1.0) right = 1.0;
  volume |= ((int)(right *0xFFFF)) << 16;

  waveOutSetVolume((HWAVEOUT) 0, volume);
}

#endif /* NO_DIRECT_SOUND */
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/

/* HACK! Define LPWAVEFORMAT as LPWAVEFORMATEX for WinVER >= 4 */
#if WINVER >= 0x0400
#define LPWAVEFORMAT LPWAVEFORMATEX
#endif

/* number of buffers used */
#define NUM_BUFFERS 4
/* initial buffer size */
#define BUFFER_SIZE 4096

/* Note: NUM_BUFFERS and BUFFER_SIZE should be carefully chosen.
   You better not touch it unless you know what you're doing, but
   ALWAYS use a multiple of 2 for NUM_BUFFERS. BUFFER_SIZE affects 
   only sound input. The output buffer size is determined by Squeak.
*/

HWAVEOUT hWaveOut = 0;
HWAVEIN hWaveIn = 0;
WAVEFORMATEX waveOutFormat;
WAVEFORMATEX waveInFormat;

HANDLE win32SyncMutex;

static WAVEOUTCAPS outCaps;
static int outBufferSize = 0;
static int outSemaIndex = -1;

static WAVEHDR *(playBuffers[NUM_BUFFERS]);
static WAVEHDR *(recordBuffers[NUM_BUFFERS]);

static int currentRecordBuffer = 0; /* Index of the buffer currently recorded */
static int currentPlayBuffer = 0;   /* Index of the buffer currently played */
static int playingStarted = 0;
static int lastPlayBuffer = -1;

/* Initialize wave headers */
static void
initWaveHeaders(WAVEHDR **buffers, DWORD bufferSize)
{ int i;

 for(i=0;i<NUM_BUFFERS;i++)
   {
     (buffers[i]) = GlobalAlloc(GMEM_ZEROINIT | GMEM_FIXED ,sizeof(WAVEHDR));
     (buffers[i])->dwBufferLength = bufferSize;
     (buffers[i])->lpData = GlobalAlloc(GMEM_ZEROINIT | GMEM_FIXED, bufferSize);
     (buffers[i])->dwFlags |= WHDR_DONE;
   }
}

/* Release wave headers */
static void
freeWaveHeaders(WAVEHDR **buffers)
{ int i;

  for(i=0;i<NUM_BUFFERS;i++)
    {
      /* Free data buffer */
      GlobalFree((buffers[i])->lpData);
      /* Free wave header */
      GlobalFree(buffers[i]);
      buffers[i] = 0;
    }
}

/* find the next empty header which can be used for sound output */
static WAVEHDR *
findEmptyHeader(WAVEHDR **buffers)
{ int i;
  int bufIndex = currentPlayBuffer;

  for(i=0;i<NUM_BUFFERS;i++)
    {
      if(((buffers[bufIndex])->dwFlags & WHDR_DONE) != 0) {
        return buffers[bufIndex];
      }
      bufIndex = (bufIndex+1) % NUM_BUFFERS;
    }
  return NULL;
}

/* provide a buffer for sound input */
static int 
provideRecordBuffer(WAVEHDR *header)
{
  header->dwUser = 0; /* reset read index */
  if(waveInPrepareHeader(hWaveIn,header,sizeof(WAVEHDR)) != 0)
    return 0;
  if(waveInAddBuffer(hWaveIn,header,sizeof(WAVEHDR)) != 0)
    return 0;
  return 1;
}

static int
providePlayBuffer(WAVEHDR *header)
{
  /* give us a time stamp for the mix-in of samples */
  if(!playingStarted) 
    {
      (playBuffers[currentPlayBuffer])->dwUser = (DWORD) ioMicroMSecs();
      playingStarted = 1;
    }
  if(waveOutPrepareHeader(hWaveOut,header,sizeof(WAVEHDR)) != 0)
    return 0;
  if(waveOutWrite(hWaveOut,header,sizeof(WAVEHDR)) != 0)
    return 0;
  return 1;
}

int win32_snd_StopPlaying(void)
{
  HWAVEOUT h;
  lastPlayBuffer = -1;

  WaitForSingleObject(win32SyncMutex, INFINITE);
  h = hWaveOut;
  hWaveOut = 0;
  ReleaseMutex(win32SyncMutex);
  if(!h) return 0;
  DPRINTF(("Shutting down W32Sound\n"));
  waveOutReset(h);
  waveOutClose(h);
  return 1;
}


/* The wave callback: Signal the associated semaphore that a buffer has completed.
   This means either that the buffer has been played and can be filled again (playing)
   or that the buffer is filled and waits for being read (recording) */
void CALLBACK
waveCallback(HWAVEOUT hWave, UINT uMsg, DWORD dummy, DWORD dwParam1, DWORD dwParam2)
{
  if(uMsg == WOM_DONE)
    { /* a buffer has been played */
      currentPlayBuffer = (currentPlayBuffer + 1) % NUM_BUFFERS;
      (playBuffers[currentPlayBuffer])->dwUser = (DWORD) ioMicroMSecs();
      if(currentPlayBuffer == lastPlayBuffer) {
	DPRINTF(("W32Sound: stopping from waveCallback\n"));
	win32_snd_StopPlaying();
	DPRINTF(("W32Sound: stopped from waveCallback\n"));
      }
    }
  if(uMsg == WOM_DONE || uMsg == WIM_DATA)
    { /* a buffer has been completed */
      synchronizedSignalSemaphoreWithIndex(outSemaIndex);
    }
}

/*******************************************************************/
/*  Sound output functions                                         */
/*******************************************************************/

int win32_snd_AvailableSpace(void)
{ int i;
  for(i=0;i<NUM_BUFFERS;i++)
    if(((playBuffers[i])->dwFlags & WHDR_DONE) != 0)
      return outBufferSize;
  return 0;
}

int win32_snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex)
{ WAVEHDR *header;
  int bytesWritten;
  char *src,*dst,*end;
  short *shortSrc;

  header = findEmptyHeader(playBuffers);
  if(!header) return 0; /* no buffer */

  DPRINTF(("%d ", frameCount));

  bytesWritten = waveOutFormat.nBlockAlign  * frameCount;
  if(bytesWritten > outBufferSize)
    bytesWritten = outBufferSize;

  src = (char *) (arrayIndex + startIndex);
  dst = (char *) header->lpData;
  end = (char *) dst + bytesWritten;
  shortSrc = (short*) src;

  if (waveOutFormat.wBitsPerSample == 8) 
    {  /* 8-bit samples */
      if (waveOutFormat.nChannels == 2) /* stereo */
        while (dst < end)
          { *dst++ = (*shortSrc++ + 0x8000) >> 8;
            *dst++ = (*shortSrc++ + 0x8000) >> 8;
          }
      else
        while (dst < end)
          *dst++ = ( ((*shortSrc++ + 0x8000) >> 8) + ((*shortSrc++ + 0x8000) >> 8) ) / 2;
          
    } 
  else 
    if (waveOutFormat.nChannels == 2) /* stereo */
      while (dst < end)
        *((long*)dst)++ = *((long*)src)++;
    else /* if mono, skip every other frame of the source */
      while (dst < end) 
        {
          *((short*)dst)++ = (*shortSrc++ + *shortSrc++) / 2;
        }

  header->dwBufferLength = bytesWritten;
  if(!providePlayBuffer(header)) return 0;
  return bytesWritten / waveOutFormat.nBlockAlign;
}

void MixInSamples(int count, char *srcBufPtr, int srcStartIndex, char *dstBufPtr, int dstStartIndex) 
{ unsigned char *src, *dst, *end;
  short *shortSrc, *shortDst;
  int sample;

  src = (unsigned char *) srcBufPtr + (srcStartIndex * 4);
  dst = (unsigned char *) dstBufPtr + (dstStartIndex * waveOutFormat.nBlockAlign);
  end = (unsigned char *) dstBufPtr + ((dstStartIndex + count) * 4);
  shortSrc = (short*) src;
  shortDst = (short*) dst;

  if (waveOutFormat.wBitsPerSample == 8) 
    {  /* 8-bit samples */
      if (waveOutFormat.nChannels == 2) /* stereo */
        while (dst < end)
          { 
            sample = *dst + ((*shortSrc++ + 0x8000) >> 8);
            /* @@: working on unsigned - no underflow */
            if(sample > 255) sample = 255;
            *dst++ = sample;
          }
      else /* Mono */
        while (dst < end)
          {
            sample = *dst + ( ((*shortSrc++ + 0x8000) >> 8) + ((*shortSrc++ + 0x8000) >> 8) ) / 2;
            /* @@: working on unsigned - no underflow */
            if(sample > 255) sample = 255;
            *dst++ = sample;
          }
          
    } 
  else /* 16-bit samples */
    if (waveOutFormat.nChannels == 2) /* stereo */
      while (shortDst < (short*)end)
        {
          sample = (*shortDst + *shortSrc++) / 2;
          if (sample > 32767) sample = 32767;
          else if (sample < -32767) sample = -32767;
          *shortDst++ = sample;
        }
    else /* if mono, skip every other frame of the source */
      while (shortDst < (short*)end) 
        {
          sample = (*dst + *shortSrc++ + *shortSrc++) / 4;
          if (sample > 32767) sample = 32767;
          else if (sample < -32767) sample = -32767;
          *shortDst++ = sample;
        }
}


int win32_snd_PlaySilence(void)
{ WAVEHDR *header;

  header = findEmptyHeader(playBuffers);
  if(!header) return 0; /* no buffer */
  ZeroMemory(header->lpData, header->dwBufferLength);
  if(!providePlayBuffer(header)) return 0;
  return header->dwBufferLength / waveOutFormat.nBlockAlign;
}

static int computePlayBufferSize(int frameCount, int bytesPerFrame) {
  int bufferBytes;

  bufferBytes = (bytesPerFrame * frameCount) / (NUM_BUFFERS / 2);
  bufferBytes = (bufferBytes / 16) * 16;
  /* Make sure our buffers are powers of two or multiple of 4k */
  if(bufferBytes <= 2048) {
    if(bufferBytes <= 1024) {
      if(bufferBytes <= 512) {
	return 512;
      } else {
	return 1024;
      }
    } else {
      return 2048;
    }
  }
  return (bufferBytes + 4095) & ~4095;
}

static int startDevicePlaying(int frameCount, int bytesPerFrame)
{
  int bufferBytes;

  static int initFlag = 0;

  /* Initialize output buffers */
  bufferBytes = computePlayBufferSize(frameCount, bytesPerFrame);
  if(bufferBytes != outBufferSize || !initFlag) {
#ifndef NDEBUG
    warnPrintf(TEXT("Initializing %d output buffers of size %d\n"), NUM_BUFFERS, bufferBytes);
#endif
    outBufferSize = bufferBytes;
    if(initFlag) freeWaveHeaders(playBuffers);
    initWaveHeaders(playBuffers, outBufferSize);
    initFlag = 1;
  }
  playingStarted = 0;
  currentPlayBuffer = 0;
  lastPlayBuffer = -1;
  return 1;
}

int win32_snd_Start(int frameCount, int samplesPerSec, int stereo, int semaphoreIndex)
{
  int bytesPerFrame;
  int bytesPerSample;
  int bufferSize;
  int maxDevs = 0,devId = 0;
  MMRESULT result;

  bytesPerFrame = stereo ? 2 * bytesPerSample : bytesPerSample;
  bufferSize = computePlayBufferSize(frameCount, bytesPerFrame);
  if((bufferSize != outBufferSize) || 
     (samplesPerSec != waveOutFormat.nSamplesPerSec) || 
     ((stereo == 0) != (waveOutFormat.nChannels == 1))) {
    /* format change */
    DPRINTF(("W32Sound: stopping from win32_snd_Start\n"));
    DPRINTF(("W32Sound format change (%d, %d, %s)\n", frameCount, samplesPerSec, (stereo ? "stereo" : "mono")));
    win32_snd_StopPlaying();
    DPRINTF(("W32Sound: stopped from win32_snd_Start\n"));
  }

  outSemaIndex = semaphoreIndex; /* might have changed */

  if (hWaveOut) {
    /* still open from last time; keep playing */
    lastPlayBuffer = -1;
    DPRINTF(("Continuing W32Sound\n"));
    return 1;
  }

  DPRINTF(("Starting W32Sound\n"));

  /* perform an initial attempt to open exactly the specified values */
  for(bytesPerSample = 2; bytesPerSample >= 1; bytesPerSample--) {
    bytesPerFrame = stereo ? 2 * bytesPerSample : bytesPerSample;
    waveOutFormat.wFormatTag = WAVE_FORMAT_PCM;
    waveOutFormat.nChannels = stereo ? 2 : 1;
    waveOutFormat.nSamplesPerSec = samplesPerSec;
    waveOutFormat.nAvgBytesPerSec = samplesPerSec * bytesPerFrame;
    waveOutFormat.nBlockAlign = bytesPerFrame;
    waveOutFormat.wBitsPerSample = 8 * bytesPerSample;
    result = waveOutOpen(&hWaveOut, WAVE_MAPPER, (LPWAVEFORMAT)&waveOutFormat, 
			 (DWORD)waveCallback, 0, CALLBACK_FUNCTION);
    if(result == 0) { /* success */
      /* get device caps */
      waveOutGetDevCaps(devId,&outCaps,sizeof(WAVEOUTCAPS));
      return startDevicePlaying(frameCount, bytesPerFrame);
    }
  }

  /* find a device supporting the requested output rate */
  maxDevs = waveOutGetNumDevs();
  /* try 16bit devices first */
  bytesPerSample = 2;
  for(devId=0;devId<maxDevs;devId++){
    WAVEOUTCAPS caps;
    int flag;
    waveOutGetDevCaps(devId,&caps,sizeof(WAVEOUTCAPS));
    switch (samplesPerSec) {
    case 11025: flag = stereo ? WAVE_FORMAT_1S16 : WAVE_FORMAT_1M16; break;
    case 22050: flag = stereo ? WAVE_FORMAT_2S16 : WAVE_FORMAT_2M16; break;
    case 44100: flag = stereo ? WAVE_FORMAT_4S16 : WAVE_FORMAT_4M16; break;
    default: return 0;
    }
    if(caps.dwFormats & flag) break;
  }
  
  if(devId >= maxDevs) {
    /* try 8bit devices */
    bytesPerSample = 1;
    for(devId=0;devId<maxDevs;devId++) {
      WAVEOUTCAPS caps;
      int flag;
      waveOutGetDevCaps(devId,&caps,sizeof(WAVEOUTCAPS));
      switch (samplesPerSec) {
      case 11025: flag = stereo ? WAVE_FORMAT_1S08 : WAVE_FORMAT_1M08; break;
      case 22050: flag = stereo ? WAVE_FORMAT_2S08 : WAVE_FORMAT_2M08; break;
      case 44100: flag = stereo ? WAVE_FORMAT_4S08 : WAVE_FORMAT_4M08; break;
      default: return 0;
      }
      if(caps.dwFormats & flag) break;
    }
  }
  if(devId >= maxDevs) return 0;

  bytesPerFrame = stereo ? 2 * bytesPerSample : bytesPerSample;
  waveOutFormat.wFormatTag = WAVE_FORMAT_PCM;
  waveOutFormat.nChannels = stereo ? 2 : 1;
  waveOutFormat.nSamplesPerSec = samplesPerSec;
  waveOutFormat.nAvgBytesPerSec = samplesPerSec * bytesPerFrame;
  waveOutFormat.nBlockAlign = bytesPerFrame;
  waveOutFormat.wBitsPerSample = 8 * bytesPerSample;


  result = waveOutOpen(&hWaveOut,devId, (LPWAVEFORMAT)&waveOutFormat, 
		       (DWORD)waveCallback, 0, CALLBACK_FUNCTION);

  if(result != 0) {
#ifndef NO_WARNINGS
    TCHAR errorText[256];
    waveOutGetErrorText(result,errorText,255);
    warnPrintf(TEXT("%s\n"),errorText);
#endif
    return 0;
  } else {
    /* get device caps */
    waveOutGetDevCaps(devId,&outCaps,sizeof(WAVEOUTCAPS));
  }
  return startDevicePlaying(frameCount, bytesPerFrame);
}

int win32_snd_Stop(void)
{
  WAVEHDR *header;
  int i, idx;
  if(!hWaveOut) return 0;
  if(playBuffers[currentPlayBuffer]->dwFlags & WHDR_DONE) {
    /* no buffers playing */
    DPRINTF(("W32Sound: stopping from win32_snd_Stop\n"));
    win32_snd_StopPlaying();
    DPRINTF(("W32Sound: stopped from win32_snd_Stop\n"));
  }
  for(i = 0; i < NUM_BUFFERS; i++) {
    idx = (currentPlayBuffer + i + 1) % NUM_BUFFERS;
    if(playBuffers[idx]->dwFlags & WHDR_DONE) {
      lastPlayBuffer = idx;
      DPRINTF(("W32Sound: last play buffer = %d\n", lastPlayBuffer));
      DPRINTF(("W32Sound: current play buffer = %d\n", currentPlayBuffer));
      return 1;
    }
  }
  /* all buffers are being played */
  lastPlayBuffer = currentPlayBuffer;
  DPRINTF(("W32Sound: last = current play buffer = %d\n", lastPlayBuffer));
  return 1;
}

int win32_snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime) 
{ WAVEHDR *header;
  int currentBuffer;
  int samplesInserted;
  int startSample;
  int i, count;
  DWORD nowTime;

  if(!hWaveOut) return -1;
  samplesInserted = 0;
  currentBuffer = currentPlayBuffer;
  /* mix as many samples as can fit into the remainder of the currently playing buffer */
  header = playBuffers[currentBuffer];
  nowTime = (DWORD) ioMicroMSecs();
  startSample = ((waveOutFormat.nSamplesPerSec * (nowTime - header->dwUser)) / 1000) + samplesOfLeadTime;
  if((DWORD) startSample * waveOutFormat.nBlockAlign < header->dwBufferLength)
    {
      count = (header->dwBufferLength / waveOutFormat.nBlockAlign) - startSample;
      if(count > frameCount) count = frameCount;
      MixInSamples(count, (char*) srcBufPtr, 0, header->lpData, startSample);
      samplesInserted = count;
    }
  /* mix remaining samples into the inactive buffers */
  for(i=1;i<NUM_BUFFERS;i++)
    {
      currentBuffer = (currentBuffer+1) % NUM_BUFFERS;
      header = playBuffers[currentBuffer];
      count = (header->dwBufferLength / waveOutFormat.nBlockAlign);
      if((samplesInserted + count) > frameCount) count = frameCount - samplesInserted;
      MixInSamples(count, (char*) srcBufPtr, samplesInserted, header->lpData, 0);
      samplesInserted += count;
    }
  return samplesInserted;
}

/*******************************************************************/
/*  Sound input functions                                          */
/*******************************************************************/

int win32_snd_SetRecordLevel(int level)
{
  /* Note: I don't see a simple way of accomplishing the change in recording level.
     One way (such as on my SB16) would be to modify the output level of the source
     signal. This works fine on on SoundBlaster cards but I don't know of other cards.
     Also we would have to know what we're recording (it's no good idea to change
     the output level of _all_ available drivers such as CD, MIDI, Wave, PC-Speaker,
     Line-In, or Microphone).
     Another way could be using the mixer functions, but my help files and books
     lack this topic completely. If somebody has an idea how to do it, let me know.
     AR
  */
  return 1;
}


static int startDeviceRecording(void)
{
  int i;
  /* The device was successfully opened. Provide the input buffers. */
  for(i=0; i<NUM_BUFFERS; i++)
    if(!provideRecordBuffer(recordBuffers[i])) return 0; /* something went wrong */
  /* first buffer has index 0 */
  currentRecordBuffer = 0;
  /* And away we go ... */
  if(waveInStart(hWaveIn) != 0) return 0;
  return 1;
}

int win32_snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaphoreIndex) 
{
  int bytesPerSample;
  int bytesPerFrame, samplesPerSec;
  int maxDevs = 0,devId = 0, i;
  MMRESULT result;

  static int initFlag = 0;

  if(!initFlag) {
    /* first time -- initialize wave headers */
    initWaveHeaders(recordBuffers, BUFFER_SIZE);
    initFlag = 1;
  }

  if (hWaveIn)  {
    /* still open from last time; clean up before continuing */
    snd_StopRecording();
  }

  /* perform an initial attempt to open exactly the specified values */
  for(i=0;i<2;i++) {
    for(bytesPerSample = 2; bytesPerSample >= 1; bytesPerSample--) {
      bytesPerFrame = stereo ? 2 * bytesPerSample : bytesPerSample;
      waveInFormat.wFormatTag = WAVE_FORMAT_PCM;
      waveInFormat.nChannels = stereo ? 2 : 1;
      waveInFormat.nSamplesPerSec = desiredSamplesPerSec;
      waveInFormat.nAvgBytesPerSec = desiredSamplesPerSec * bytesPerFrame;
      waveInFormat.nBlockAlign = bytesPerFrame;
      waveInFormat.wBitsPerSample = 8 * bytesPerSample;
      result = waveInOpen(&hWaveIn,WAVE_MAPPER, (LPWAVEFORMAT)&waveInFormat, 
			  (DWORD)waveCallback, semaphoreIndex, CALLBACK_FUNCTION);
      if(result == 0) {/* success */
	return startDeviceRecording();
      }
    }
    /* round desiredSamplesPerSec to valid values for the second round */
    if (desiredSamplesPerSec <= 16538)
      samplesPerSec = 11025;
    else if(desiredSamplesPerSec <= 33075)
      samplesPerSec = 22050;
    else
      samplesPerSec = 44100;
  }
  /* finally, try finding a device supporting the requested input rate */
  maxDevs = waveInGetNumDevs();
  /* try 16bit devices first */
  bytesPerSample = 2;
  for(devId=0;devId<maxDevs;devId++) {
    WAVEINCAPS caps;
    int flag;
    waveInGetDevCaps(devId,&caps,sizeof(WAVEINCAPS));
    switch (samplesPerSec) {
    case 11025: flag = stereo ? WAVE_FORMAT_1S16 : WAVE_FORMAT_1M16; break;
    case 22050: flag = stereo ? WAVE_FORMAT_2S16 : WAVE_FORMAT_2M16; break;
    case 44100: flag = stereo ? WAVE_FORMAT_4S16 : WAVE_FORMAT_4M16; break;
    default: return 0;
    }
    if(caps.dwFormats & flag) break;
  }
  
  if(devId >= maxDevs) {
    /* try 8bit devices */
    bytesPerSample = 1;
    for(devId=0;devId<maxDevs;devId++){
      WAVEINCAPS caps;
      int flag;
      waveInGetDevCaps(devId,&caps,sizeof(WAVEINCAPS));
      switch (samplesPerSec) {
      case 11025: flag = stereo ? WAVE_FORMAT_1S08 : WAVE_FORMAT_1M08; break;
      case 22050: flag = stereo ? WAVE_FORMAT_2S08 : WAVE_FORMAT_2M08; break;
      case 44100: flag = stereo ? WAVE_FORMAT_4S08 : WAVE_FORMAT_4M08; break;
      default: return 0;
      }
      if(caps.dwFormats & flag) break;
    }
  }
  if(devId >= maxDevs) return 0;

  bytesPerFrame = stereo ? 2 * bytesPerSample : bytesPerSample;
  waveInFormat.wFormatTag = WAVE_FORMAT_PCM;
  waveInFormat.nChannels = stereo ? 2 : 1;
  waveInFormat.nSamplesPerSec = samplesPerSec;
  waveInFormat.nAvgBytesPerSec = samplesPerSec * bytesPerFrame;
  waveInFormat.nBlockAlign = bytesPerFrame;
  waveInFormat.wBitsPerSample = 8 * bytesPerSample;

  result = waveInOpen(&hWaveIn,devId, (LPWAVEFORMAT)&waveInFormat, 
		      (DWORD)waveCallback, semaphoreIndex, CALLBACK_FUNCTION);
  if(result != 0) {
#ifndef NO_WARNINGS
    TCHAR errorText[256];
    waveInGetErrorText(result,errorText,255);
    warnPrintf(TEXT("%s\n"),errorText);
#endif
    return 0;
  }
  return startDeviceRecording();
}

int win32_snd_StopRecording(void)
{
  if(!hWaveIn) return 0;
  waveInReset(hWaveIn);
  waveInClose(hWaveIn);
  hWaveIn = 0;
  return 1;
}

double win32_snd_GetRecordingSampleRate(void)
{
  if(!hWaveIn) return 0.0;
  return (double) waveInFormat.nSamplesPerSec;
}

int win32_snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes)
{
  /* if data is available, copy as many sample slices as possible into the
     given buffer starting at the given slice index. do not write past the
     end of the buffer, which is buf + bufferSizeInBytes. return the number
     of slices (not bytes) copied. a slice is one 16-bit sample in mono
     or two 16-bit samples in stereo. */
  int bytesPerSlice = (waveInFormat.nChannels * 2);
  int recordBytesPerSlice = (waveInFormat.wBitsPerSample / 8);
  char *nextBuf = (char *) buf + (startSliceIndex * bytesPerSlice);
  char *bufEnd = (char *) buf + bufferSizeInBytes;
  char *srcStart, *src, *srcEnd;
  int bytesCopied;
  WAVEHDR *recBuf;

  if (!hWaveIn) {
    success(false);
    return 0;
  }

  /* Copy all recorded samples into the buffer provided.
     We use an endless loop here which is exited if
       a) there is no room left in the provided buffer
       b) there is no data available from the wave input device
     The WAVEHDR's dwUser member is used to mark the read position
     in case a previous call has been exited because of a)
  */
  bytesCopied = 0;
  while(true)
    {
      /* select the buffer */
      recBuf = recordBuffers[currentRecordBuffer];
      /* We do _NOT_ copy partial buffer contents, so wait 
         until the buffer is marked */
      if((recBuf->dwFlags & WHDR_DONE) == 0) break;
      /* copy samples into the client's buffer */
      srcStart = recBuf->lpData + recBuf->dwUser;
      src = srcStart;
      srcEnd = recBuf->lpData + recBuf->dwBytesRecorded;
      if (waveInFormat.wBitsPerSample == 8) 
        {
          while ((src < srcEnd) && (nextBuf < bufEnd)) 
            {
              /* convert 8-bit sample to 16-bit sample */
              *nextBuf++ = 0;  /* low-order byte is zero */
              *nextBuf++ = (*src++) - 127;  /* convert from [0-255] to [-128-127] */
            }
        }
      else 
        {
          while ((src < srcEnd) && (nextBuf < bufEnd)) 
            *nextBuf++ = *src++;
        }
      bytesCopied += src - srcStart;
      /* are we at the end of the provided buffer? */
      if(src < srcEnd)
        { /* Yes, update read index */
          recBuf->dwUser = src - recBuf->lpData;
          /* and exit */
          break;
        }
      /* we have completed a buffer, send it back to the device for further use */
      if(!provideRecordBuffer(recBuf)) break; /* something went wrong */
      /* step on to the next buffer */
      currentRecordBuffer = (currentRecordBuffer + 1) % NUM_BUFFERS;
    }
  /* return the number of slices copied */
  return bytesCopied / recordBytesPerSlice;
}

void win32_snd_Volume(double *left, double *right)
{
  DWORD volume = (DWORD)-1;

  waveOutGetVolume((HWAVEOUT)0, &volume);
  *left = (volume & 0xFFFF) / 65535.0;
  *right = (volume >> 16) / 65535.0;
}

void win32_snd_SetVolume(double left, double right)
{
  DWORD volume;

  if(left < 0.0) left = 0.0;
  if(left > 1.0) left = 1.0;
  volume = (int)(left * 0xFFFF);
  if(right < 0.0) right = 0.0;
  if(right > 1.0) right = 1.0;
  volume |= ((int)(right *0xFFFF)) << 16;

  waveOutSetVolume((HWAVEOUT) 0, volume);
}

int win32_soundInit(void)
{
  win32SyncMutex = CreateMutex(NULL, 0, NULL);
  return 1;
}

int win32_soundShutdown(void)
{
  win32_snd_StopPlaying();
  win32_snd_StopRecording();
  CloseHandle(win32SyncMutex);
  return 1;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* module initialization/shutdown */
int soundInit(void) {
#ifndef NO_DIRECT_SOUND
  dx_soundInit();
#endif
  win32_soundInit();
}

int soundShutdown(void) {
#ifndef NO_DIRECT_SOUND
  dx_soundShutdown();
#endif
  win32_soundShutdown();
}

/* sound output */
int snd_AvailableSpace(void) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_AvailableSpace();
#endif
  return win32_snd_AvailableSpace();
}

int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_InsertSamplesFromLeadTime(frameCount, srcBufPtr, samplesOfLeadTime);
#endif
  return win32_snd_InsertSamplesFromLeadTime(frameCount, srcBufPtr, samplesOfLeadTime);
}

int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_PlaySamplesFromAtLength(frameCount, arrayIndex, startIndex);
#endif
  return win32_snd_PlaySamplesFromAtLength(frameCount, arrayIndex, startIndex);
}

int snd_PlaySilence(void) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_PlaySilence();
#endif
  return win32_snd_PlaySilence();
}

int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound || fUseDirectSound)
    return dx_snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
#endif
  return win32_snd_Start(frameCount, samplesPerSec, stereo, semaIndex);
}

int snd_Stop(void) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_Stop();
#endif
  return win32_snd_Stop();
}

/* sound input */
int snd_SetRecordLevel(int level) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_SetRecordLevel(level);
#endif
  return win32_snd_SetRecordLevel(level);
}

int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound || fUseDirectSound)
    return dx_snd_StartRecording(desiredSamplesPerSec, stereo, semaIndex);
#endif
  return win32_snd_StartRecording(desiredSamplesPerSec, stereo, semaIndex);
}

int snd_StopRecording(void) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_StopRecording();
#endif
  return win32_snd_StopRecording();
}

double snd_GetRecordingSampleRate(void) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_GetRecordingSampleRate();
#endif
  return win32_snd_GetRecordingSampleRate();
}

int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound)
    return dx_snd_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes);
#endif
    return win32_snd_RecordSamplesIntoAtLength(buf, startSliceIndex, bufferSizeInBytes);
}
  
void snd_Volume(double *left, double *right) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound || fUseDirectSound)
    return dx_snd_Volume(left, right);
#endif
  return win32_snd_Volume(left, right);
}

void snd_SetVolume(double left, double right) {
#ifndef NO_DIRECT_SOUND
  if(fUsingDirectSound || fUseDirectSound)
    return dx_snd_SetVolume(left, right);
#endif
  return win32_snd_SetVolume(left, right);
}

#endif /* NO_SOUND */
