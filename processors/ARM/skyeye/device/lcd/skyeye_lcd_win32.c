/*
	skyeye_lcd_win32.c - LCD display emulation in a GDI32 window.
	Copyright (C) 2006 Anthony Lee

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
 * NOTE: only for little endian.
 */

#include "skyeye_lcd.h"

#undef WORD
#include <windows.h>

extern unsigned int Pen_buffer[8];

typedef struct SkyEyeLCD {
	int fWidth;
	int fHeight;
	int fDepth;

	RECT fUpdateRect;
	BOOL fUpdateAll;

	HINSTANCE fHinstance;
	ATOM fAppClass;
	HDC fScreenHDC;
	HDC fHDC;
	HBITMAP fBitmap;
	HWND fWindow;

	DWORD fTimestamp;
	DWORD fInterval;
	void *fADDR;
	void *fPrivateADDR;

	struct lcd_device *fDevice;
} SkyEyeLCD;

static SkyEyeLCD* SkyEyeLCD_new(struct lcd_device *lcd_dev, unsigned char *addr);
static void SkyEyeLCD_delete(SkyEyeLCD *lcd);
static void SkyEyeLCD_UpdateFromSkyEye(SkyEyeLCD *lcd);
static BOOL SkyEyeLCD_ProcessEvent(SkyEyeLCD *lcd, MSG *msg, LRESULT *reslut);
static void SkyEyeLCD_DoUpdate(SkyEyeLCD *lcd, RECT r);

#ifndef GET_X_LPARAM
#define GET_X_LPARAM(a)	((int)((short)LOWORD(a)))
#endif

#ifndef GET_Y_LPARAM
#define GET_Y_LPARAM(a)	((int)((short)HIWORD(a)))
#endif

#ifndef MIN
#define MIN(a, b)  ((a) > (b) ? (b) : (a))
#endif

#ifndef MAX
#define MAX(a, b)  ((a) > (b) ? (a) : (b))
#endif


static void skPenEvent(int *buffer, int eventType, int stateType, int x, int y)
{
	buffer[0] = x;
	buffer[1] = y;
	buffer[2] = 0;		// dx
	buffer[3] = 0;		// dy
	buffer[4] = eventType;	// event from pen (DOWN,UP,CLICK,MOVE)
	buffer[5] = stateType;	// state of pen (DOWN,UP,ERROR)
	buffer[6] = 1;		// no of the event
	buffer[7] = 0;		// time of the event (ms) since ts_open
}


BOOL SkyEyeLCD_ProcessEvent(SkyEyeLCD *lcd, MSG *msg, LRESULT *result)
{
	BOOL handled = TRUE;
	RECT r = {0, 0, -1, -1};

	if(lcd == NULL || msg == NULL || result == NULL)
	{
		handled = FALSE;
	}
	else switch(msg->message)
	{
		case WM_CLOSE:
			*result = 0;
			break;

		case WM_PAINT:
			GetUpdateRect(msg->hwnd, &r, FALSE);
			SkyEyeLCD_DoUpdate(lcd, r);
			ValidateRect(msg->hwnd, NULL);
			*result = 0;
			break;

		case WM_MOUSEMOVE:
			if(Pen_buffer[5] == 1) skPenEvent(Pen_buffer, 2, 1, GET_X_LPARAM(msg->lParam), GET_Y_LPARAM(msg->lParam));
			break;

		case WM_LBUTTONDOWN:
			skPenEvent(Pen_buffer, 0, 1, GET_X_LPARAM(msg->lParam), GET_Y_LPARAM(msg->lParam));
			break;

		case WM_LBUTTONUP:
			skPenEvent(Pen_buffer, 1, 0, GET_X_LPARAM(msg->lParam), GET_Y_LPARAM(msg->lParam));
			break;

		case WM_KEYDOWN: /* write to stdin */
			{
				BYTE keyState[256];
				DWORD keybuffer[3];
				DWORD nWrote;

				if(GetKeyboardState(keyState) == 0) break;
				UINT scanCode = (UINT)((msg->lParam >> 16) & 0xff);

				if(ToAscii(msg->wParam, scanCode, keyState, (LPWORD)keybuffer, 0) != 1) break;

				INPUT_RECORD input;
				input.EventType = KEY_EVENT;
				input.Event.KeyEvent.bKeyDown = TRUE;
				input.Event.KeyEvent.wRepeatCount = msg->lParam & 0xff;
				input.Event.KeyEvent.wVirtualKeyCode = msg->wParam;
				input.Event.KeyEvent.wVirtualScanCode = scanCode;
				input.Event.KeyEvent.uChar.AsciiChar = keybuffer[0];
				input.Event.KeyEvent.dwControlKeyState = 0;
				WriteConsoleInput(GetStdHandle(STD_INPUT_HANDLE), &input, 1, &nWrote);
			}
			break;

		default:
			handled = FALSE;
	}

	return handled;
}


static LRESULT CALLBACK _lcd_win32_WndProc_(HWND hWnd, UINT umsg, WPARAM wParam, LPARAM lParam)
{
	BOOL handled = FALSE;
	LRESULT result = 0;
	MSG winMsg;

	SkyEyeLCD *lcd = (SkyEyeLCD*)GetWindowLong(hWnd, 0);

	if(lcd != NULL)
	{
		winMsg.hwnd = hWnd;
		winMsg.message = umsg;
		winMsg.wParam = wParam;
		winMsg.lParam = lParam;
		handled = SkyEyeLCD_ProcessEvent(lcd, &winMsg, &result);
	}

	if(!handled) result = DefWindowProc(hWnd, umsg, wParam, lParam);

	return result;
}


static int SkyEyeLCD_Initalize(SkyEyeLCD *self)
{
	RECT r;
	char mode[100];
	WNDCLASSEX wcApp;

	if(self == NULL || (self->fHinstance = (HINSTANCE)GetModuleHandle(NULL)) == NULL) return -1;

	wcApp.lpszClassName = "skyeye_lcd_win32";
	wcApp.hInstance = self->fHinstance;
	wcApp.lpfnWndProc = _lcd_win32_WndProc_;
	wcApp.hCursor = LoadCursor(NULL, IDC_HAND);
	wcApp.hIcon = 0;
	wcApp.hIconSm = 0;
	wcApp.lpszMenuName = 0;
	wcApp.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
	wcApp.style = CS_CLASSDC;
	wcApp.cbClsExtra = 0;
	wcApp.cbWndExtra = 4;
	wcApp.cbSize = sizeof(wcApp);

	self->fAppClass = RegisterClassEx(&wcApp);
	self->fScreenHDC = CreateDC("DISPLAY", NULL, NULL, NULL);
	self->fHDC = CreateCompatibleDC(self->fScreenHDC);
	self->fBitmap = CreateCompatibleBitmap(self->fScreenHDC, self->fWidth, self->fHeight);
	SelectObject(self->fHDC, self->fBitmap);
	Rectangle(self->fHDC, 0, 0, self->fWidth, self->fHeight);
	snprintf(mode, 100, "If you always see this,");
	TextOut(self->fHDC, 10, 10, mode, strlen(mode));
	snprintf(mode, 100, "thus means that depth %d unsupported!!!", self->fDepth);
	TextOut(self->fHDC, 10, 30, mode, strlen(mode));

	r.left = 100;
	r.top = 100;
	r.right = r.left + self->fWidth;
	r.bottom = r.top + self->fHeight;
	AdjustWindowRectEx(&r, WS_CAPTION | WS_MINIMIZEBOX | WS_SYSMENU, FALSE, WS_EX_DLGMODALFRAME);

	self->fWindow = CreateWindowEx(WS_EX_DLGMODALFRAME, MAKEINTATOM(self->fAppClass), "", WS_CAPTION | WS_MINIMIZEBOX | WS_SYSMENU,
				       r.left, r.top, r.right - r.left + 1, r.bottom - r.top + 1,
				       NULL, NULL, self->fHinstance, NULL);

	SetWindowLong(self->fWindow, 0, (LONG)self);
	snprintf(mode, 100, "%dx%dx%d %s", self->fWidth, self->fHeight, self->fDepth, "SkyEye LCD & Touch Screen (Win32)");
	SetWindowText(self->fWindow, mode);
	ShowWindow(self->fWindow, SW_SHOWNORMAL);

	return 0;
}


static int SkyEyeLCD_Destroy(SkyEyeLCD *self)
{
	if(self == NULL || self->fHinstance == NULL) return -1;

	DestroyWindow(self->fWindow);
	DeleteObject(self->fBitmap);
	DeleteDC(self->fHDC);
	DeleteDC(self->fScreenHDC);
	UnregisterClass(MAKEINTATOM(self->fAppClass), self->fHinstance);

	return 0;
}


static void SkyEyeLCD_Cycle(SkyEyeLCD *self)
{
	MSG winMsg;

	while(PeekMessage(&winMsg, NULL, 0, 0, PM_REMOVE)) DispatchMessage(&winMsg);

	if(GetTickCount() - self->fTimestamp > self->fInterval)
	{
		SkyEyeLCD_UpdateFromSkyEye(self);
		self->fTimestamp = GetTickCount();
	}
}


static u32 colors1b[2] =
{
	0x000000,0xffffff
};


static u32 colors4b[16] =
{
	0x000000,0x000080,0x008000,0x008080,0x800000,0x800080,0x808000,0x808080,
	0xc0c0c0,0x0000ff,0x00ff00,0x00ffff,0xff0000,0xff00ff,0xffff00,0xffffff
};


SkyEyeLCD* SkyEyeLCD_new(struct lcd_device *lcd_dev, unsigned char *addr)
{
	SkyEyeLCD *lcd;
	size_t sizePrivateADDR = 0;
	int width = lcd_dev->width;
	int height = lcd_dev->height;
	int depth = lcd_dev->depth;

	if(width <= 0 || height <= 0 || addr == NULL) return NULL;
	if((lcd = (SkyEyeLCD*)malloc(sizeof(SkyEyeLCD))) == NULL) return NULL;

	lcd->fWidth = width;
	lcd->fHeight = height;
	lcd->fDepth = depth;
	lcd->fADDR = (void*)addr;
	lcd->fInterval = 200;
	lcd->fTimestamp = 0;
	lcd->fPrivateADDR = NULL;
	lcd->fUpdateRect.left = 0;
	lcd->fUpdateRect.top = 0;
	lcd->fUpdateRect.right = -1;
	lcd->fUpdateRect.bottom = -1;
	lcd->fUpdateAll = TRUE;
	lcd->fDevice = lcd_dev;

	if(SkyEyeLCD_Initalize(lcd) != 0)
	{
		free(lcd);
		return NULL;
	}

	if(lcd->fDevice->lcd_lookup_color != NULL || lcd->fDepth == 8) /* turn to RGB32 */
		sizePrivateADDR = (size_t)(lcd->fWidth * lcd->fHeight * 4);
	else if(lcd->fDepth == 1)
		sizePrivateADDR = sizeof(BITMAPINFO) + sizeof(RGBQUAD);
	else if(lcd->fDepth == 4)
		sizePrivateADDR = sizeof(BITMAPINFO) + 15 * sizeof(RGBQUAD);

	if(sizePrivateADDR > 0)
	{
		if((lcd->fPrivateADDR = malloc(sizePrivateADDR)) != NULL)
		{
			bzero(lcd->fPrivateADDR, sizePrivateADDR);
			if(lcd->fDevice->lcd_lookup_color == NULL && (lcd->fDepth == 4 || lcd->fDepth == 1))
			{
				BITMAPINFO *bitsInfo = (BITMAPINFO*)lcd->fPrivateADDR;
				int w = lcd->fWidth + (int)lcd->fDevice->lcd_line_offset;

				memcpy(&bitsInfo->bmiColors[0],
				       lcd->fDepth == 1 ? colors1b : colors4b,
				       lcd->fDepth == 1 ? 8 : 64);

				bitsInfo->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
				bitsInfo->bmiHeader.biWidth = (LONG)w;
				bitsInfo->bmiHeader.biHeight = -((LONG)lcd->fHeight);
				bitsInfo->bmiHeader.biPlanes = 1;
				bitsInfo->bmiHeader.biBitCount = lcd->fDepth;
				bitsInfo->bmiHeader.biSizeImage = (DWORD)((w * lcd->fHeight * lcd->fDepth + 7) & ~7) / 8;
			}
		}
	}

	return lcd;
}


void SkyEyeLCD_delete(SkyEyeLCD *lcd)
{
	if(lcd == NULL) return;

	SkyEyeLCD_Destroy(lcd);
	if(lcd->fPrivateADDR) free(lcd->fPrivateADDR);
	free(lcd);
}


void SkyEyeLCD_DoUpdate(SkyEyeLCD *lcd, RECT r)
{
	HDC hdc;

	if(lcd == NULL || lcd->fBitmap == NULL || lcd->fWindow == NULL || (hdc = GetDC(lcd->fWindow)) == NULL)
	{
		fprintf(stderr, "%s: lcd == NULL || lcd->fBitmap == NULL || lcd->fWindow == NULL || (hdc = GetDC(lcd->fWindow)) == NULL\n",
			__FUNCTION__);
		return;
	}

	if(r.right < r.left || r.bottom < r.top)
	{
		r.left = 0;
		r.top = 0;
		r.right = lcd->fWidth - 1;
		r.bottom = lcd->fHeight - 1;
	}

	BitBlt(hdc, r.left, r.top, r.right - r.left + 1, r.bottom - r.top + 1, lcd->fHDC, r.left, r.top, SRCCOPY);

	ReleaseDC(lcd->fWindow, hdc);
}


typedef struct _BITMAPINFO_LARGE {
	BITMAPINFO bitsInfo;
	DWORD reserved[3]; // enough to contain 16 bits RGB mask
} _BITMAPINFO_LARGE;


static void SkyEyeLCD_DMAConvertCallback(u32 c, u32 **buf_addr, void *noused)
{
	*(*buf_addr) = c;
	*buf_addr = ++(*buf_addr);
}


void SkyEyeLCD_UpdateFromSkyEye(SkyEyeLCD *lcd)
{
	RECT r;
	_BITMAPINFO_LARGE _bitsInfo;
	BITMAPINFO *bitsInfo = (BITMAPINFO*)&_bitsInfo;

	if(lcd == NULL || lcd->fBitmap == NULL || lcd->fWindow == NULL) return;
	if(lcd->fUpdateAll == FALSE)
	{
		if(lcd->fUpdateRect.left > lcd->fUpdateRect.right || lcd->fUpdateRect.top > lcd->fUpdateRect.bottom) return;

		r = lcd->fUpdateRect;
		lcd->fUpdateRect.left = 0;
		lcd->fUpdateRect.top = 0;
		lcd->fUpdateRect.right = -1;
		lcd->fUpdateRect.bottom = -1;
	}
	else
	{
		r.left = 0;
		r.top = 0;
		r.right = lcd->fWidth - 1;
		r.bottom = lcd->fHeight - 1;
	}

	bzero(bitsInfo, sizeof(BITMAPINFO));
	bitsInfo->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bitsInfo->bmiHeader.biWidth = (LONG)lcd->fWidth;
	bitsInfo->bmiHeader.biHeight = -((LONG)lcd->fHeight);
	bitsInfo->bmiHeader.biPlanes = 1;

	if(lcd->fDevice->lcd_lookup_color != NULL)
	{
		u32 *tmp = (u32*)(lcd->fPrivateADDR) + r.top * lcd->fWidth;

		if(lcd->fPrivateADDR == NULL) return;

		skyeye_convert_color_from_lcd_dma(lcd->fDevice,
						  0, r.top, lcd->fWidth, r.bottom - r.top + 1,
						  (void (*)(u32, void*, void*))SkyEyeLCD_DMAConvertCallback,
						  &tmp, NULL);

		bitsInfo->bmiHeader.biBitCount = 32;
		bitsInfo->bmiHeader.biCompression = BI_RGB;
		bitsInfo->bmiHeader.biSizeImage = 0;
	}
	else switch(lcd->fDepth)
	{
		case 1:
		case 4:
			if(lcd->fPrivateADDR == NULL) return;
			break;

		case 16:
			bitsInfo->bmiHeader.biBitCount = 16;
			bitsInfo->bmiHeader.biSizeImage = (DWORD)((lcd->fWidth + (int)lcd->fDevice->lcd_line_offset) * lcd->fHeight * 2);
			bitsInfo->bmiHeader.biCompression = BI_BITFIELDS;
			((DWORD*)(&bitsInfo->bmiColors[0]))[0] = 0xf800;
			((DWORD*)(&bitsInfo->bmiColors[0]))[1] = 0x07e0;
			((DWORD*)(&bitsInfo->bmiColors[0]))[2] = 0x001f;
			break;

		case 24:
			bitsInfo->bmiHeader.biBitCount = 24;
			bitsInfo->bmiHeader.biSizeImage = (DWORD)((lcd->fWidth + (int)lcd->fDevice->lcd_line_offset) * lcd->fHeight * 3);
			break;

		case 8: /* 3-3-2 */
			if(lcd->fPrivateADDR == NULL) return;
			else {
				int count = lcd->fWidth * (r.bottom - r.top + 1);
				const unsigned char *buf = (const unsigned char*)lcd->fADDR + r.top * lcd->fWidth;
				u32 *tmp = (u32*)(lcd->fPrivateADDR) + r.top * lcd->fWidth;
				int i;

				while(count-- > 0)
				{
					*tmp++ = (((*buf & 0xe0) | 0x1f) << 16) | // red
						 ((((*buf & 0x1c) << 3) | 0x1f) << 8) | // green
						 (((*buf++ & 0x03) << 6) | 0x3f); // blue
					if(++i == lcd->fWidth) {buf += lcd->fDevice->lcd_line_offset; i = 0;}
				}
			}
		case 32:
			if(lcd->fDepth == 32) bitsInfo->bmiHeader.biWidth += (LONG)lcd->fDevice->lcd_line_offset;
			bitsInfo->bmiHeader.biBitCount = 32;
			bitsInfo->bmiHeader.biCompression = BI_RGB;
			bitsInfo->bmiHeader.biSizeImage = 0;
			break;

		default:
			return;
	}

	StretchDIBits(lcd->fHDC,
		      r.left, r.top, r.right - r.left + 1, r.bottom - r.top + 1,
		      r.left, r.top, r.right - r.left + 1, r.bottom - r.top + 1,
		      (lcd->fDevice->lcd_lookup_color != NULL || lcd->fDepth == 8 ? lcd->fPrivateADDR : lcd->fADDR),
		      (lcd->fDevice->lcd_lookup_color == NULL && (lcd->fDepth == 1 || lcd->fDepth == 4) ?
		       		(BITMAPINFO*)lcd->fPrivateADDR : bitsInfo),
		      DIB_RGB_COLORS, SRCCOPY);

	SkyEyeLCD_DoUpdate(lcd, r);
}


static int win32_lcd_update(struct lcd_device *lcd_dev)
{
	if(lcd_dev == NULL || lcd_dev->priv == NULL) return -1;

	SkyEyeLCD_Cycle((SkyEyeLCD*)(lcd_dev->priv));

	return 0;
}


static int win32_lcd_open(struct lcd_device *lcd_dev)
{
	unsigned char *fbSkyeyeADDR;

	if(lcd_dev == NULL || lcd_dev->priv != NULL) return -1;

	if((fbSkyeyeADDR = skyeye_find_lcd_dma(lcd_dev)) == NULL)
	{
		fprintf(stderr, "[WIN32_LCD]: Can't find LCD DMA from address 0x%x\n", lcd_dev->lcd_addr_begin);
		return -1;
	}

	if((lcd_dev->priv = (void*)SkyEyeLCD_new(lcd_dev, fbSkyeyeADDR)) == NULL) return -1;
	return 0;
}


static int win32_lcd_close(struct lcd_device *lcd_dev)
{
	if(lcd_dev == NULL || lcd_dev->priv == NULL) return -1;
	SkyEyeLCD_delete((SkyEyeLCD*)(lcd_dev->priv));
	lcd_dev->priv = NULL;
	lcd_dev->lcd_addr_end = lcd_dev->lcd_addr_begin = 0;
	return 0;
}


static int win32_lcd_filter_write(struct lcd_device *lcd_dev, u32 addr, u32 data, size_t count)
{
	int offsetADDR1, offsetADDR2;
	int w, x1, y1, x2, y2;

	SkyEyeLCD *lcd = lcd_dev ? (SkyEyeLCD*)(lcd_dev->priv) : NULL;
	if (lcd == NULL || addr < lcd_dev->lcd_addr_begin || addr > lcd_dev->lcd_addr_end) return 0;

	offsetADDR1 = (int)(addr - lcd_dev->lcd_addr_begin) * 8 / lcd->fDepth;
	offsetADDR2 = offsetADDR1 + (int)count * 8 / lcd->fDepth;
	w = lcd->fWidth + (int)lcd->fDevice->lcd_line_offset;
	x1 = MIN(offsetADDR1 % w, w - 1);
	y1 = MIN(offsetADDR1 / w, lcd->fHeight - 1);
	x2 = MIN(offsetADDR2 % w, w - 1);
	y2 = MIN(offsetADDR2 / w, lcd->fHeight - 1);

	if(lcd->fUpdateRect.left > lcd->fUpdateRect.right || lcd->fUpdateRect.top > lcd->fUpdateRect.bottom)
	{
		lcd->fUpdateRect.left = MIN(x1, x2);
		lcd->fUpdateRect.right = MAX(x1, x2);
		lcd->fUpdateRect.top = MIN(y1, y2);
		lcd->fUpdateRect.bottom = MAX(y1, y2);
	}
	else
	{
		lcd->fUpdateRect.left = MIN(MIN(lcd->fUpdateRect.left, x1), x2);
		lcd->fUpdateRect.top = MIN(MIN(lcd->fUpdateRect.top, y1), y2);
		lcd->fUpdateRect.right = MAX(MAX(lcd->fUpdateRect.right, x1), x2);
		lcd->fUpdateRect.bottom = MAX(MAX(lcd->fUpdateRect.bottom, y1), y2);
	}

	lcd->fUpdateAll = FALSE;

	return 0;
}


int win32_lcd_init(struct lcd_device *lcd_dev)
{
	if (lcd_dev == NULL) return -1;

	lcd_dev->lcd_open = win32_lcd_open;
	lcd_dev->lcd_close = win32_lcd_close;
	lcd_dev->lcd_update = win32_lcd_update;
	lcd_dev->lcd_filter_read = NULL;
	lcd_dev->lcd_filter_write = win32_lcd_filter_write;

	return 0;
}

