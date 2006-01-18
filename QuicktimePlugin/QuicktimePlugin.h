/*
 *  QuicktimePlugin.h
 *  SqueakQuicktime
 *
 *  Created by John M McIntosh on 17/01/06.
 *  Copyright 2006 Corporate Smalltalk Consulting ltd.  All rights reserved, published under the Squeak-L licence
 *
 */


void SetupSurface();
int sqQuicktimeInitialize();
int sqQuicktimeShutdown();
long stQuicktimeSetSurfacewidthheightrowBytesdepthmovie(char * buffer, int width, int height, int rowBytes, int depth, void *movie);
int stQuicktimeDestroy(int sqHandle);
int stQuicktimeSetSemaphorefor(int index, int sqHandle);
int stQuicktimeClearSemaphore(int sqHandle);
