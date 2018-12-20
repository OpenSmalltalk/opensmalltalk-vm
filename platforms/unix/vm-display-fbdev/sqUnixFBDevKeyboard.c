/* sqUnixFBDevKeyboard.c -- abstraction over the keyboard
 * 
 * Author: Ian Piumarta <ian.piumarta@squeakland.org>
 * 
 * Last edited: 2005-03-17 21:35:14 by piumarta on squeak.hpl.hp.com
 */


/* The framebuffer display driver was donated to the Squeak community by:
 * 
 *	Weather Dimensions, Inc.
 *	13271 Skislope Way, Truckee, CA 96161
 *	http://www.weatherdimensions.com
 *
 * Copyright (C) 2003-2005 Ian Piumarta
 * All Rights Reserved.
 * 
 * This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */


#include <termios.h>
#include <sys/ioctl.h>

#include <linux/keyboard.h>
#include <linux/kd.h>
#include <linux/vt.h>


#define _self	struct kb *self


typedef void (*kb_callback_t)(int key, int up, int mod);

struct kb
{
  char			 *kbName;
  int			  fd;
  int			  kbMode;
  struct termios	  tcAttr;
  int			  vtActive;
  int			  vtLock;
  int			  vtSwitch;
  int			  state;
  kb_callback_t		  callback;
  unsigned short	**keyMaps;
};

#include "sqUnixFBDevKeymap.c"


static void updateModifiers(int kstate)
{
  modifierState= 0;
  if (kstate & (1 << KG_SHIFT))	modifierState |= ShiftKeyBit;
  if (kstate & (1 << KG_CTRL))	modifierState |= CtrlKeyBit;
  if (kstate & (1 << KG_ALT))	modifierState |= CommandKeyBit;
  if (kstate & (1 << KG_ALTGR))	modifierState |= OptionKeyBit;
  DPRINTF("state %02x mod %02x\n", kstate, modifierState);
}


static void kb_chvt(_self, int vt)
{
  if (ioctl(self->fd, VT_ACTIVATE, vt))
    perror("chvt: VT_ACTIVATE");
  else
    {
      while (ioctl(self->fd, VT_WAITACTIVE, vt))
	{
	  if (EINTR == errno)
	    continue;
	  perror("VT_WAITACTIVE");
	  break;
	}
      updateModifiers(self->state= 0);
    }
}


static void kb_post(_self, int code, int up)
{
  if (code == 127) code= 8;		//xxx OPTION!!!
  self->callback(code, up, modifierState);
}


static void kb_translate(_self, int code, int up)
{
  static int prev= 0;
  unsigned short *keyMap= self->keyMaps[self->state];
  int rep= (!up) && (prev == code);
  prev= up ? 0 : code;

  DPRINTF("+++ code %d up %d prev %d rep %d map %p\n", code, up, prev, rep, keyMap);

  if (keyMap)
    {
      int sym=  keyMap[code];
      int type= KTYP(sym);
      DPRINTF("+++ sym %x (%02x) type %d\n", sym, sym & 255, type);
      sym &= 255;
      if (type >= 0xf0)		// shiftable
	type -= 0xf0;
      if (KT_LETTER == type)	// lockable
	type= KT_LATIN;
      DPRINTF("+++ type %d\n", type);
      switch (type)
	{
	case KT_LATIN:
	case KT_META:
	  kb_post(self, sym, up);
	  break;

	case KT_SHIFT:
	  if      (rep) break;
	  else if (up)  self->state &= ~(1 << sym);
	  else          self->state |=  (1 << sym);
	  updateModifiers(self->state);
	  break;

	case KT_FN:
	case KT_SPEC:
	case KT_CUR:
	  switch (K(type,sym))
	    {
	      // FN
	    case K_FIND:	kb_post(self,  1, up);	break;	// home
	    case K_INSERT:	kb_post(self,  5, up);	break;
	    case K_SELECT:	kb_post(self,  4, up);	break;	// end
	    case K_PGUP:	kb_post(self, 11, up);	break;
	    case K_PGDN:	kb_post(self, 12, up);	break;
	      // SPEC
	    case K_ENTER:	kb_post(self, 13, up);	break;
	      // CUR
	    case K_DOWN:	kb_post(self, 31, up);	break;
	    case K_LEFT:	kb_post(self, 28, up);	break;
	    case K_RIGHT:	kb_post(self, 29, up);	break;
	    case K_UP:		kb_post(self, 30, up);	break;
	    }
	  break;

	case KT_CONS:
	  if (self->vtSwitch && !self->vtLock)
	    kb_chvt(self, sym + 1);
	  break;

	default:
	  if (type > KT_SLOCK)
	    DPRINTF("ignoring unknown scancode %d.%d\n", type, sym);
	  break;
	}
    }
}


static void kb_noCallback(int k, int u, int s) {}


static int kb_handleEvents(_self)
{
  DPRINTF("+++ kb_handleEvents\n");
  while (fdReadable(self->fd, 0))
    {
      unsigned char buf;
      if (1 == read(self->fd, &buf, 1))
	{
	  DPRINTF("+++ kb_translate %3d %02x + %d\n", buf & 127, buf & 127, (buf >> 7) & 1);
	  kb_translate(self, buf & 127, (buf >> 7) & 1);
	}
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


static void sigusr1(int sig)
{
  _self= kb;					// ugh
  struct vt_stat v;

  if (ioctl(self->fd, VT_GETSTATE, &v))		fatalError("VT_GETSTATE");
  if (self->vtActive && !self->vtLock)
    {
      ioctl(self->fd, VT_RELDISP, 1);
      self->vtActive= 0;
      updateModifiers(self->state= 0);
    }
  else
    {
      extern sqInt fullDisplayUpdate(void);
      self->vtActive= 1;
      updateModifiers(self->state= 0);
      fullDisplayUpdate();
    }
}


static void kb_initGraphics(_self)
{
  struct vt_mode vt;

  if (ioctl(self->fd, KDSETMODE, KD_GRAPHICS)) perror("KDSETMODE(KDGRAPHICS)");
    
  if (ioctl(self->fd, VT_GETMODE, &vt) < 0)
    perror("VT_GETMODE");
  else
    {
      struct sigaction sa;
      sa.sa_handler= sigusr1;
      sigemptyset(&sa.sa_mask);
      sa.sa_flags= 0;
#    if !defined(__ia64)
      sa.sa_restorer= 0;
#    endif
      sigaction(SIGUSR1, &sa, 0);
      vt.mode=   VT_PROCESS;
      vt.relsig= SIGUSR1;
      vt.acqsig= SIGUSR1;
      if (ioctl(self->fd, VT_SETMODE, &vt) < 0) 
	perror("VT_SETMODE");
    }
}

static void kb_freeGraphics(_self)
{
  if (ioctl(self->fd, KDSETMODE, KD_TEXT)) perror("KDSETMODE(KDTEXT)");
}


void kb_open(_self, int vtSwitch, int vtLock)
{
  struct termios nattr;

  assert(self->fd == -1);
  {
    char *cons[]= { "/dev/console", "/dev/tty0", 0 };
    int i;
    for (i= 0;  cons[i];  ++i)
      if ((self->fd= open(self->kbName= cons[i], O_RDWR | O_NDELAY)) >= 0)
	break;
      else
	perror(cons[i]);
  }
  if (self->fd < 0)
    if ((self->fd= open(self->kbName= ttyname(0), O_RDWR | O_NDELAY)) < 0)
      perror(self->kbName);
  if (self->fd < 0)
    failPermissions("console");
  {
    struct vt_stat v;
    static char vtname[32];
    if (ioctl(self->fd, VT_GETSTATE, &v))
      fatalError("VT_GETSTATE");
    close(self->fd);
    sprintf(vtname, "/dev/tty%d", v.v_active);
    if ((self->fd= open(self->kbName= vtname, O_RDWR | O_NDELAY)) < 0)
      fatalError(vtname);
    self->vtActive= 1;
    self->vtSwitch= vtSwitch;
    self->vtLock=   vtLock;
  }

  if (ioctl(self->fd, KDGKBMODE, &self->kbMode))	perror("KDGKBMODE");
  if (ioctl(self->fd, KDSKBMODE, K_MEDIUMRAW))		perror("KDSKBMODE(K_MEDIUMRAW)");
  tcgetattr(self->fd, &self->tcAttr);

  nattr= self->tcAttr;
  nattr.c_iflag= (IGNPAR | IGNBRK) & (~PARMRK) & (~ISTRIP);
  nattr.c_cflag= CREAD | CS8;
  nattr.c_lflag= 0;
  nattr.c_cc[VTIME]= 0;
  nattr.c_cc[VMIN]= 1;
  cfsetispeed(&nattr, 9600);
  cfsetospeed(&nattr, 9600);
  tcsetattr(self->fd, TCSANOW, &nattr);

  kb_initKeyMap(self, kmPath);
}


void kb_close(_self)
{
  if (self->fd >= 0)
    {
      ioctl(self->fd, KDSKBMODE, self->kbMode);
      tcsetattr(self->fd, TCSANOW, &self->tcAttr);
      close(self->fd);
      DPRINTF("%s (%d) closed\n", self->kbName, self->fd);
      self->fd= -1;
    }
}


struct kb *kb_new(void)
{
  _self= (struct kb *)calloc(1, sizeof(struct kb));
  self->fd= -1;
  self->callback= kb_noCallback;
  return self;
}


void kb_delete(_self)
{
  free(self);
}


#undef _self
