/*
	skyeye_lcd_beos.h - LCD display emulation on BeOS' BWindow.
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

#ifndef __SKYEYE_LCD_BEOS_H__
#define __SKYEYE_LCD_BEOS_H__

#include <inttypes.h>

typedef uint32_t (*lcd_lookup_color_func)(void *lcd_dev, uint32_t color);

#ifdef __cplusplus /* Just for C++ */

#include <app/Application.h>
#include <app/Messenger.h>
#include <interface/Window.h>
#include <interface/View.h>
#include <interface/Bitmap.h>


class SkyEyeLCD_Be {
public:
	SkyEyeLCD_Be(int width, int virtual_width,
		     int height,
		     int depth,
		     const uint32_t *colormap,
		     const void *bufferFB,
		     unsigned int *bufferPen,
		     lcd_lookup_color_func func,
		     void *lcd_dev);
	~SkyEyeLCD_Be();

	status_t	InitCheck() const;
	void		Update();
	void		DMAChanged(int l, int t, int r, int b);

private:
	friend class SkyEyeLCD_Be_View;

	int fWidth;
	int fVirtualWidth;
	int fHeight;
	int fDepth;
	const uint32_t *fColormap;

	BRect fUpdateRect;
	bool fUpdateAll;

	const void *fBufferFB;
	unsigned int *fBufferPen;
	unsigned int *fBufferPenTmp;

	void *fDevice;
	lcd_lookup_color_func fLookupColorFunc;

	BMessenger fMsgr;
	BBitmap *fBitmap;
	bigtime_t fTimestamp;

	bool		IsDepthSupported(int depth) const;
	bool		InitApplication();
	static void	DMAConvertCallback(uint32_t c, uint8 **buf_addr, void *noused);
};


class SkyEyeLCD_Be_View : public BView {
public:
	SkyEyeLCD_Be_View(SkyEyeLCD_Be *lcd);
	virtual ~SkyEyeLCD_Be_View();

	virtual void	MessageReceived(BMessage *msg);
	virtual void	Draw(BRect updateRect);

	virtual	void	MouseDown(BPoint where);
	virtual	void	MouseUp(BPoint where);
	virtual	void	MouseMoved(BPoint where, uint32 code, const BMessage *a_message);

private:
	SkyEyeLCD_Be *fLCD;
};


extern "C" {

#endif /* __cplusplus */


/* C functions called from C */
void*	SkyEyeLCD_Be_new(int width, int virtual_width,
			 int height,
			 int depth,
			 const uint32_t *colormap,
			 const void *bufferFB,
			 unsigned int *bufferPen,
			 lcd_lookup_color_func func,
			 void *lcd_dev);
void	SkyEyeLCD_Be_delete(void *lcd);
void	SkyEyeLCD_Be_Update(void *lcd);
void	SkyEyeLCD_Be_DMAChanged(void *lcd, int l, int t, int r, int b);


#ifdef __cplusplus /* Just for C++ */

} // extern "C"

#endif /* __cplusplus */

#endif /* __SKYEYE_LCD_BEOS_H__ */

