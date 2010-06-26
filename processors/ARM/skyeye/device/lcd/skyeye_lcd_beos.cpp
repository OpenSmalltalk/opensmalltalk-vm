/*
	skyeye_lcd_beos.cpp - LCD display emulation on BeOS' BWindow.
	Copyright (C) 2003 - 2007 Skyeye Develop Group
	for help please send mail to <skyeye-developer@lists.gro.clinux.org>

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/*
 * 01/31/2007   written by Anthony Lee
 */

#include <stdlib.h>
#include <kernel/OS.h>
#include <support/String.h>

#include "skyeye_lcd_beos.h"


extern "C" {

extern void beos_lcd_skPenEvent(unsigned int *buffer, int eventType, int stateType, int x, int y);

/* defined in skyeye_lcd.c, but we don't include the "skyeye_lcd.h" */
extern void skyeye_convert_color_from_lcd_dma(void *lcd_dev, int x, int y, int w, int h,
					      void (*func)(uint32_t color, void *user_data1, void *user_data2),
					      void *user_data, void *user_data2);

void* SkyEyeLCD_Be_new(int width, int virtual_width,
		       int height,
		       int depth,
		       const uint32_t *colormap,
		       const void *bufferFB,
		       unsigned int *bufferPen,
		       lcd_lookup_color_func func,
		       void *lcd_dev)
{
	SkyEyeLCD_Be *lcd = new SkyEyeLCD_Be(width, virtual_width,
					     height,
					     depth,
					     colormap,
					     bufferFB,
					     bufferPen,
					     func,
					     lcd_dev);

	if(lcd->InitCheck() == B_OK) return (void*)lcd;

	delete lcd;
	return NULL;
}


void SkyEyeLCD_Be_delete(void *_lcd)
{
	SkyEyeLCD_Be *lcd = (SkyEyeLCD_Be*)_lcd;
	if(lcd) delete lcd;
}


void SkyEyeLCD_Be_Update(void *_lcd)
{
	SkyEyeLCD_Be *lcd = (SkyEyeLCD_Be*)_lcd;
	if(lcd) lcd->Update();
}


void SkyEyeLCD_Be_DMAChanged(void *_lcd, int l, int t, int r, int b)
{
	SkyEyeLCD_Be *lcd = (SkyEyeLCD_Be*)_lcd;
	if(lcd) lcd->DMAChanged(l, t, r, b);
}

} // extern "C"


static void SkyEyeLCD_Be_At_Exit_Callback()
{
	while(be_app_messenger.SendMessage(B_QUIT_REQUESTED) == B_OK) snooze(500000);
}


static int32 SkyEyeLCD_Be_Thread_App(void *data)
{
	new BApplication("application/x-vnd.skyeye-lcd-app");

	atexit(SkyEyeLCD_Be_At_Exit_Callback);

	be_app->Run();

	delete be_app;

	return 0;
}


bool
SkyEyeLCD_Be::InitApplication()
{
	if(be_app_messenger.IsValid()) return true;

	thread_id tid = spawn_thread(SkyEyeLCD_Be_Thread_App, NULL, B_URGENT_DISPLAY_PRIORITY, NULL);
	if(tid < 0 || resume_thread(tid) != B_OK) return false;

	while(be_app_messenger.IsValid() == false) snooze(100000);

	return true;
}


bool
SkyEyeLCD_Be::IsDepthSupported(int depth) const
{
	switch(depth)
	{
		case 1:
		case 8:
		case 16:
		case 24:
		case 32:
			return true;

		case 2:
			return(fLookupColorFunc != NULL);

		case 4:
			return(fLookupColorFunc != NULL || fColormap != NULL);

		default:
			return false;
	}
}


status_t
SkyEyeLCD_Be::InitCheck() const
{
	if(fWidth <= 0 || fVirtualWidth < fWidth ||
	   fHeight <= 0 ||
	   !IsDepthSupported(fDepth) ||
	   fBufferFB == NULL ||
	   (fLookupColorFunc != NULL && fDevice == NULL)) return B_ERROR;

	if(!fMsgr.IsValid() || fBitmap == NULL) return B_NO_INIT;

	return B_OK;
}


SkyEyeLCD_Be::SkyEyeLCD_Be(int width, int virtual_width,
		           int height,
			   int depth,
			   const uint32_t *colormap,
			   const void *bufferFB,
			   unsigned int *bufferPen,
			   lcd_lookup_color_func func,
			   void *lcd_dev)
	: fWidth(width), fVirtualWidth(virtual_width),
	  fHeight(height), fDepth(depth), fColormap(colormap),
	  fUpdateAll(true),
	  fBufferFB(bufferFB), fBufferPen(bufferPen),
	  fLookupColorFunc(func), fDevice(lcd_dev),
	  fBitmap(NULL), fTimestamp(0)
{
	if(InitApplication() == false || InitCheck() == B_ERROR) return;

	fBufferPenTmp = (unsigned int*)malloc(sizeof(unsigned int) * 8);
	fBitmap = new BBitmap(BRect(0, 0, (fLookupColorFunc == NULL ? fVirtualWidth : fWidth) - 1, fHeight - 1),
			      (fDepth == 1 && fLookupColorFunc == NULL ? B_GRAY1 : B_RGB32), false);

	if(fBufferPenTmp == NULL || fBitmap->InitCheck() != B_OK)
	{
		if(fBufferPenTmp != NULL) free(fBufferPenTmp);
		if(fBitmap != NULL) delete fBitmap;
		fBufferPenTmp = NULL;
		fBitmap = NULL;
		return;
	}

	memcpy(fBufferPenTmp, fBufferPen, sizeof(unsigned int) * 8);

	BString title;
	title << width << "x" << height << "x" << depth << " SkyEye LCD & Touch Screen (BeOS)";

	BWindow *win = new BWindow(BRect(100, 100, 100 + fWidth - 1, 100 + fHeight - 1),
			           title.String(),
				   B_TITLED_WINDOW,
				   B_NOT_CLOSABLE | B_NOT_ZOOMABLE | B_NOT_RESIZABLE);
	BView *view = new SkyEyeLCD_Be_View(this);

	/* for B_GRAY1 */
	view->SetHighColor(255, 255, 255);
	view->SetLowColor(0, 0, 0);

	win->Lock();
	win->AddChild(view);
	win->Show();
	fMsgr = BMessenger(view, NULL);
	win->Unlock();
}


SkyEyeLCD_Be::~SkyEyeLCD_Be()
{
	if(fMsgr.IsValid())
	{
		while(fMsgr.LockTarget() == false) snooze(100000);

		BLooper *looper;
		BView *view = (BView*)fMsgr.Target(&looper);
		view->RemoveSelf();
		looper->PostMessage(B_QUIT_REQUESTED);
		looper->Unlock();

		delete view;
	}

	if(fBufferPenTmp != NULL) free(fBufferPenTmp);
	if(fBitmap != NULL) delete fBitmap;
}


void
SkyEyeLCD_Be::DMAChanged(int l, int t, int r, int b)
{
	while(fBitmap->LockBits() != B_OK);
	if (fUpdateRect.IsValid() == false)
		fUpdateRect = BRect(l, t, r, b);
	else
		fUpdateRect = (fUpdateRect | BRect(l, t, r, b));
	fUpdateAll = false;
	fBitmap->UnlockBits();
}


void
SkyEyeLCD_Be::DMAConvertCallback(uint32_t c, uint8 **buf_addr, void *noused)
{
	*(*buf_addr) = (c >> 16) & 0xff;
	*((*buf_addr) + 1)= (c >> 8) & 0xff;
	*((*buf_addr) + 2) = c & 0xff;

	*buf_addr = (*buf_addr) + 3;
}


void
SkyEyeLCD_Be::Update()
{
	while(fBitmap->LockBits() != B_OK);

	if(real_time_clock_usecs() - fTimestamp >= (bigtime_t)200000UL && (fUpdateAll || fUpdateRect.IsValid()))
	{
		void *data = NULL;
		int32 length, offset;
		color_space cs;
		BRect rect;

		if(fUpdateAll == false)
		{
			rect = fUpdateRect;
			rect.right += 1;
			rect.bottom += 1;
			fUpdateRect = BRect();
		}
		else
		{
			rect = BRect(0, 0, fWidth, fHeight);
		}

		if(fLookupColorFunc != NULL)
		{
				offset = fWidth * (int)rect.top * 4;
				length = fWidth * rect.IntegerHeight() * 3;
				cs = B_RGB32;
				if((data = malloc(length)) != NULL)
				{
					uint8 *tmp = (uint8*)data;
					skyeye_convert_color_from_lcd_dma(fDevice,
									  0, (int)rect.top, fWidth, rect.IntegerHeight(),
									  (void (*)(uint32_t, void*, void*))DMAConvertCallback,
									  &tmp, NULL);
				}
		}
		else switch(fDepth)
		{
			case 1:
				data = (void*)fBufferFB;
				offset = fVirtualWidth * (int)rect.top / 8;
				length = fVirtualWidth * rect.IntegerHeight() / 8;
				cs = B_GRAY1;
				break;

			case 24:
				data = (void*)fBufferFB;
				offset = fVirtualWidth * (int)rect.top * 4;
				length = fVirtualWidth * rect.IntegerHeight() * 3;
				cs = B_RGB32;
				break;

			case 4: /* index */
			case 8: /* 3-3-2 */
			case 16: /* 5-6-5 */
			case 32:
				offset = fVirtualWidth * (int)rect.top * 4;
				length = fVirtualWidth * rect.IntegerHeight() * 3;
				cs = B_RGB32;
				if((data = malloc(length)) != NULL)
				{
					uint8 *tmp = (uint8*)data;
					uint8 *buf = (uint8*)fBufferFB + fVirtualWidth * (int)rect.top * fDepth / 8;

					int32 count = fWidth * rect.IntegerHeight();
					int32 i = 0;

					while(count-- > 0)
					{
						if(fDepth == 4)
						{
							uint32 c = *(fColormap + (count % 2 == 0 ? (*buf & 0xf) : (*buf >> 4)));
							*tmp++ = (c >> 16) & 0xff; // red
							*tmp++ = (c >> 8) & 0xff; // green
							*tmp++ = c & 0xff; // blue
							if(count % 2 == 0) buf++;
						}
						if(fDepth == 8)
						{
							*tmp++ = (*buf & 0xe0) | 0x1f; // red
							*tmp++ = ((*buf & 0x1c) << 3) | 0x1f; // green
							*tmp++ = ((*buf++ & 0x03) << 6) | 0x3f; // blue
						}
						else if(fDepth == 16)
						{
							*tmp++ = ((*((uint16*)buf) & 0xf800) >> 8) | 0x0007; // red
							*tmp++ = ((*((uint16*)buf) & 0x07e0) >> 3) | 0x0003; // green
							*tmp++ = ((*((uint16*)buf) & 0x001f) << 3) | 0x0007; // blue
							buf += 2;
						}
						else
						{
							uint32 c = *((uint32*)buf);
							*tmp++ = (c >> 16) & 0xff; // red
							*tmp++ = (c >> 8) & 0xff; // green
							*tmp++ = c & 0xff; // blue
							buf += 4;
						}

						if(++i == fWidth)
						{
							tmp += (fVirtualWidth - fWidth) * 3;
							buf += (fVirtualWidth - fWidth) * fDepth / 8;
							i = 0;
						}
					}
				}
				break;

			default:
				break;
		}

		if(data != NULL)
		{
			BMessage aMsg('slcd');

			fBitmap->SetBits(data, length, offset, cs);
			if(data != fBufferFB) free(data);

			rect.right -= 1;
			rect.bottom -= 1;
			aMsg.AddRect("frame", rect);
			fMsgr.SendMessage(&aMsg);
		}

		fTimestamp = real_time_clock_usecs();
	}

	memcpy(fBufferPen, fBufferPenTmp, sizeof(unsigned int) * 8);

	fBitmap->UnlockBits();
}


SkyEyeLCD_Be_View::SkyEyeLCD_Be_View(SkyEyeLCD_Be *lcd)
	: BView(BRect(0, 0, lcd->fWidth - 1, lcd->fHeight - 1), NULL, B_FOLLOW_NONE, 0), fLCD(lcd)
{
}


SkyEyeLCD_Be_View::~SkyEyeLCD_Be_View()
{
}


void
SkyEyeLCD_Be_View::MessageReceived(BMessage *msg)
{
	BRect rect;

	switch(msg->what)
	{
		case 'slcd':
			if(msg->FindRect("frame", &rect) != B_OK) break;
			Draw(rect);
			break;

		default:
			BView::MessageReceived(msg);
	}
}


void
SkyEyeLCD_Be_View::Draw(BRect updateRect)
{
	while(fLCD->fBitmap->LockBits() != B_OK);
	DrawBitmap(fLCD->fBitmap, updateRect, updateRect);
	fLCD->fBitmap->UnlockBits();
}


void
SkyEyeLCD_Be_View::MouseDown(BPoint where)
{
	while(fLCD->fBitmap->LockBits() != B_OK);
	beos_lcd_skPenEvent(fLCD->fBufferPenTmp, 0, 1, (int)where.x, (int)where.y);
	fLCD->fBitmap->UnlockBits();
}


void
SkyEyeLCD_Be_View::MouseUp(BPoint where)
{
	while(fLCD->fBitmap->LockBits() != B_OK);
	beos_lcd_skPenEvent(fLCD->fBufferPenTmp, 1, 0, (int)where.x, (int)where.y);
	fLCD->fBitmap->UnlockBits();
}


void
SkyEyeLCD_Be_View::MouseMoved(BPoint where, uint32 code, const BMessage *a_message)
{
	while(fLCD->fBitmap->LockBits() != B_OK);
	if(*(fLCD->fBufferPenTmp + 5) == 1) beos_lcd_skPenEvent(fLCD->fBufferPenTmp, 2, 1, (int)where.x, (int)where.y);
	fLCD->fBitmap->UnlockBits();
}

