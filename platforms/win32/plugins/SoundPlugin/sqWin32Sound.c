/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Sound.c
*   CONTENT: Sound management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
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

#define _LPCWAVEFORMATEX_DEFINED
#undef WINNT
#define DIRECTSOUND_VERSION 0x0600	/* use DirectSound 6.0 */
#ifdef __MINGW32__
#define HMONITOR_DECLARED
#endif
#include <dsound.h>

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

sqInt snd_StopPlaying(void);
sqInt snd_StopRecording(void);

/* module initialization/shutdown */
sqInt soundInit(void) {
  hRecEvent = CreateEvent( NULL, FALSE, FALSE, NULL );
  hPlayEvent = CreateEvent( NULL, FALSE, FALSE, NULL );
  return 1;
}

sqInt soundShutdown(void) {
  DPRINTF(("soundShutDown\n"));
  snd_StopPlaying();
  snd_StopRecording();
  CloseHandle(hPlayEvent);
  CloseHandle(hRecEvent);
  return 1;
}

sqInt snd_StopPlaying(void) {
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
  return 1;
}

DWORD WINAPI playCallback( LPVOID ignored ) {
  while(1) {
    if(WaitForSingleObject(hPlayEvent, INFINITE) == WAIT_OBJECT_0) {
      if(playTerminate) {
	hPlayThread = NULL;
	DPRINTF(("playCallback shutdown\n"));
	snd_StopPlaying();
	return 0; /* done playing */
      }
      playBufferAvailable = 1;
      playBufferIndex = playBufferIndex ^ 1;
      synchronizedSignalSemaphoreWithIndex(playSemaphore);
    }
  }
}

DWORD WINAPI recCallback( LPVOID ignored ) {
  while(1) {
    if(WaitForSingleObject(hRecEvent, INFINITE) == WAIT_OBJECT_0) {
      if(recTerminate) return 0; /* done playing */
      recBufferAvailable = 1;
      recBufferIndex = recBufferIndex ^ 1;
      synchronizedSignalSemaphoreWithIndex(recSemaphore);
    }
  }
}

/* sound output */
sqInt snd_AvailableSpace(void) {
  if(playBufferAvailable) {
    return playBufferSize;
  }
  return 0;
}

sqInt snd_InsertSamplesFromLeadTime(sqInt frameCount, void* srcBufPtr, 
				    sqInt samplesOfLeadTime) {
  /* currently not supported */
  return 0;
}

sqInt snd_PlaySamplesFromAtLength(sqInt frameCount,  void* srcBufPtr, 
				  sqInt startIndex) {
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
    unsigned int i;
    short *shortSrc = (short*)(((char*)srcBufPtr)+startIndex);
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

sqInt snd_PlaySilence(void) {
  /* no longer supported */
  return -1;
}

sqInt snd_Start(sqInt frameCount, sqInt samplesPerSec, sqInt stereo, 
		sqInt semaIndex) {
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
    snd_StopPlaying();
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
      DPRINTF(("sndStart: CoCreateInstance() failed (errCode: %x)\n", hRes));
      return 0;
    }
    DPRINTF(("# Initializing lpdSound\n"));
    hRes = IDirectSound_Initialize(lpdSound, NULL);
    if(FAILED(hRes)) {
      DPRINTF(("sndStart: IDirectSound_Initialize() failed (errCode: %x)\n", hRes));
      IDirectSound_Release(lpdSound);
      lpdSound = NULL;
      return 0;
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
      snd_StopPlaying();
      return 0;
    }
  }

  playSemaphore = semaIndex;

  if(!hPlayThread) {
    /* create the playback notification thread */
    DPRINTF(("# Creating playback thread\n"));
    hPlayThread = CreateThread(NULL, 0, playCallback, NULL, 0, &threadID);
    if(hPlayThread == 0) {
      printLastError("sndStart: CreateThread failed");
      snd_StopPlaying();
      return 0;
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
    snd_StopPlaying();
    /* and try again */
    return 0;
  }

  /* setup notifications */
  hRes = IDirectSoundBuffer_QueryInterface(lpdPlayBuffer,
					   &IID_IDirectSoundNotify, 
					   (void**)&lpdNotify );
  if(FAILED(hRes)) {
    DPRINTF(("sndStart: QueryInterface(IDirectSoundNotify) failed (errCode: %x)\n"));
    snd_StopPlaying();
    return 0;
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
    snd_StopPlaying();
    return 0;
  }

  DPRINTF(("# Starting to play buffer\n"));
  hRes = IDirectSoundBuffer_Play(lpdPlayBuffer, 0, 0, DSBPLAY_LOOPING);
  if(FAILED(hRes)) {
    DPRINTF(("sndStart: IDirectSoundBuffer_Play() failed (errCode: %x)\n", hRes));
    snd_StopPlaying();
    return 0;
  }
  return 1;
}

sqInt snd_Stop(void) {
  snd_StopPlaying();
  return 1;
}

/* sound input */
void snd_SetRecordLevel(sqInt level) {
  /* not supported */
  return;
}

sqInt snd_StartRecording(sqInt samplesPerSec, sqInt stereo, sqInt semaIndex) {
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

sqInt snd_StopRecording(void) {
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
  return 0;
}

double snd_GetRecordingSampleRate(void) {
  if(!lpdRecBuffer) return 0.0;
  return (double) waveInFormat.nSamplesPerSec;
}

sqInt snd_RecordSamplesIntoAtLength(void* buf, sqInt startSliceIndex, 
				       sqInt bufferSizeInBytes) {
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

  dstPtr = (char*)(buf) + startSliceIndex * bytesPerSlice;
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
void snd_Volume(double *left, double *right) {
  DWORD volume = (DWORD)-1;

  waveOutGetVolume((HWAVEOUT)0, &volume);
  *left = (volume & 0xFFFF) / 65535.0;
  *right = (volume >> 16) / 65535.0;
}

void snd_SetVolume(double left, double right) {
  DWORD volume;

  if(left < 0.0) left = 0.0;
  if(left > 1.0) left = 1.0;
  volume = (int)(left * 0xFFFF);
  if(right < 0.0) right = 0.0;
  if(right > 1.0) right = 1.0;
  volume |= ((int)(right *0xFFFF)) << 16;

  waveOutSetVolume((HWAVEOUT) 0, volume);
}

#endif /* NO_SOUND */
