/* sqUnixFBDevKeyboard.c -- abstraction over the keyboard
 * 
 * Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 * Last edited: 2003-08-20 01:14:53 by piumarta on felina.inria.fr
 */


/* The framebuffer display driver was donated to the Squeak community by:
 * 
 *	Weather Dimensions, Inc.
 *	13271 Skislope Way, Truckee, CA 96161
 *	http://www.weatherdimensions.com
 *
 * Copyright (C) 2003 Ian Piumarta
 * All Rights Reserved.
 * 
 * This file is part of Unix Squeak.
 * 
 *    You are NOT ALLOWED to distribute modified versions of this file
 *    under its original name.  If you want to modify it and then make
 *    your modifications available publicly, rename the file first.
 * 
 * This file is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.
 * 
 * You may use and/or distribute this file under the terms of the Squeak
 * License as described in `LICENSE' in the base of this distribution,
 * subject to the following additional restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software.  If you use this software
 *    in a product, an acknowledgment to the original author(s) (and any
 *    other contributors mentioned herein) in the product documentation
 *    would be appreciated but is not required.
 * 
 * 2. You must not distribute (or make publicly available by any
 *    means) a modified copy of this file unless you first rename it.
 * 
 * 3. This notice must not be removed or altered in any source distribution.
 */


#define _self	struct kb *self


#include <termios.h>
#include <linux/keyboard.h>


static unsigned short defaultKeyMap[128][13]= {
# include "defaultKeyboardMap.h"
};

static unsigned short *keyMaps[128];


typedef void (*kb_callback_t)(int key, int up, int mod);


struct kb
{
  int			fd;
  int			mode;
  struct termios	attr;
  int			state;
  kb_callback_t		callback;
};


static void initKeyMap(void)
{
  int c, m;
  memset(keyMaps, 0, sizeof(keyMaps));
  for (c= 0;  c < 128;  ++c)
    for (m= 0;  m < 13;  ++m)
    {
      int code= defaultKeyMap[c][m];
      if (code)
	{
	  if (!keyMaps[m])
	    keyMaps[m]= (unsigned short *)calloc(128, sizeof(unsigned short));
	  keyMaps[m][c]= code;
	}
    }
}


static void updateModifiers(int kstate)
{
  modifierState= 0;
  if (kstate & (1 << KG_SHIFT))	modifierState |= ShiftKeyBit;
  if (kstate & (1 << KG_CTRL))	modifierState |= CtrlKeyBit;
  if (kstate & (1 << KG_ALT))	modifierState |= CommandKeyBit;
  if (kstate & (1 << KG_ALTGR))	modifierState |= OptionKeyBit;
  dprintf("state %2d %02x mod %2d %02x\n", kstate, modifierState);
}


static void kb_post(_self, int code, int up)
{
  dprintf("KEY %3d %02x %c %s state %02x mod %02x\n",
	  code, code, ((code > 32) && (code < 127)) ? code : ' ',
	  up ? "UP" : "DOWN", self->state, modifierState);

  if (code == 127) code= 8;		//xxx OPTION!!!
  self->callback(code, up, modifierState);
}


static void kb_translate(_self, int code, int up)
{
  static int prev= 0;
  unsigned short *keyMap= keyMaps[self->state];
  int rep= (!up) && (prev == code);
  prev= up ? 0 : code;
  if (keyMap)
    {
      int sym=  keyMap[code];
      int type= KTYP(sym);
      sym &= 255;
      if (type >= 0xf0)		// shiftable
	type -= 0xf0;
      if (KT_LETTER == type)
	//xxx do additional shift for lock here
	type= KT_LATIN;
      switch (type)
	{
	case KT_LATIN:
	  kb_post(self, sym, up);
	  break;

	case KT_FN:
	  break;

	case KT_SPEC:		// also covers compose and several useless PC-specific special keys
	  if (1 == sym)
	    kb_post(self, '\r', up);
	  break;

	case KT_PAD:
	case KT_DEAD:
	case KT_CONS:
	case KT_CUR:
	  break;

	case KT_SHIFT:
	  if (rep)
	    return;
	  if (up)
	    self->state &= ~(1 << sym);
	  else
	    self->state |=  (1 << sym);
	  updateModifiers(self->state);
	  break;

	case KT_META:
	  kb_post(self, sym, up);
	  break;

	case KT_ASCII:
	case KT_LOCK:
	case KT_LETTER:
	case KT_SLOCK:
	case 13: // KT_DEAD2:
	case 14:
	case 15:
	  break;

	default:
	  dprintf("ignoring unknown scancode %d.%d\n", type, sym);
	  break;
	}
    }
}


static void kb_noCallback(int k, int u, int s) {}


static int kb_handleEvents(_self)
{
  while (fdReadable(self->fd, 0))
    {
      unsigned char buf;
      if (1 == read(self->fd, &buf, 1))
	kb_translate(self, buf & 127, (buf >> 7) & 1);
    }
  return 0;
}


static void kbHandler(int fd, void *self, int flags)
{
  kb_handleEvents((struct kb *)self);
  aioHandle(fd, kbHandler, AIO_RX);
}


static kb_callback_t kb_setCallback(_self, kb_callback_t callback)
{
  kb_callback_t old= self->callback;
  if (callback)
    {
      self->callback= callback;
      aioEnable(self->fd, self, AIO_EXT);
      aioHandle(self->fd, kbHandler, AIO_RX);
    }
  else
    {
      aioDisable(self->fd);
      self->callback= kb_noCallback;
    }
  return old;
}


static void kb_bell(_self)
{
  ioctl(self->fd, KDMKTONE, (100 << 16) | ((1193190 / 400) & 0xffff));
}


void kb_open(_self, struct fb *fb)
{
  struct termios nattr;

  self->fd= fb->tty;

  if (ioctl(self->fd, KDGKBMODE, &self->mode))			perror("KDGKBMODE");
  if (ioctl(self->fd, KDSKBMODE, K_MEDIUMRAW))			perror("KDSKBMODE(K_MEDIUMRAW)");
  tcgetattr(self->fd, &self->attr);

  nattr= self->attr;
  nattr.c_iflag= (IGNPAR | IGNBRK) & (~PARMRK) & (~ISTRIP);
  nattr.c_oflag= 0;
  nattr.c_cflag= CREAD | CS8;
  nattr.c_lflag= 0;
  nattr.c_cc[VTIME]= 0;
  nattr.c_cc[VMIN]= 1;
  cfsetispeed(&nattr, 9600);
  cfsetospeed(&nattr, 9600);
  tcsetattr(self->fd, TCSANOW, &nattr);
}


void kb_close(_self)
{
  ioctl(self->fd, KDSKBMODE, self->mode);
  tcsetattr(self->fd, TCSANOW, &self->attr);
}


struct kb *kb_new(void)
{
  _self= (struct kb *)calloc(1, sizeof(struct kb));
  initKeyMap();
  self->callback= kb_noCallback;
  return self;
}

void kb_delete(_self)
{
  free(self);
}


#undef _self
