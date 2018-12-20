/* sqUnixFBDevMousePS2.c -- weirdness unique to PS/2 mice
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 31 Jan 2012 12:57:17 CET Michael J. Zeder
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

#define PS2_DISABLE_DELAY   100*1000
#define PS2_RESET_DELAY	   1500*1000
#define PS2_FLUSH_DELAY	    100*1000
#define PS2_READ_DELAY	    100*1000
#define PS2_SEND_DELAY	    100*1000

#define	PS2_RESET		0xff
#define	PS2_RESEND		0xfe
#define	PS2_ERROR		0xfc
#define	PS2_OK			0xfa
#define	PS2_SET_DEFAULTS	0xf6
#define	PS2_DISABLE		0xf5
#define	PS2_ENABLE		0xf4
#define	PS2_SET_SAMPLE_RATE	0xf3
#define	PS2_GET_ID		0xf2
#define	PS2_SET_REMOTE_MODE	0xf0
#define	PS2_SET_WRAP_MODE	0xee
#define	PS2_RESET_WRAP_MODE	0xec
#define	PS2_READ_DATA		0xeb
#define	PS2_SET_STREAM_MODE	0xea
#define	PS2_STATUS_REQUEST	0xe9
#define	PS2_SELFTEST_OK		0xaa


static void ms_ps2_flush(_self)
{
  unsigned char buf[32];
  DPRINTF("%s: flush\n", self->msName);
  while (ms_read(self, buf, sizeof(buf), 1, PS2_FLUSH_DELAY))
    ;
}


static void ms_ps2_handleEvents(_self)
{
  unsigned char buf[3*8];
  int		n;
  
  if ((n= ms_read(self, buf, sizeof(buf), 3, PS2_READ_DELAY)) >= 3)
    {
      unsigned char *cmd= buf;
      while (n >= 3)
	{
	  int b= 0, dx, dy;
	  // The protocol requires the top 2 bits clear and bit 3 set.
	  // Some Micro$oft mice violate this, but any luser stupid
	  // enough to buy a M$ mouse deserves what they get.
	  if (0x08 != (cmd[0] & 0xc8))
	    {
	      fprintf(stderr, "%s: illegal command: %02x %02x %02x\n", self->msName,
		      cmd[0], cmd[1], cmd[2]);
	      ms_ps2_flush(self);	// resync the stream
	      return;
	    }
	  if (cmd[0] & 1) b |= RedButtonBit;
	  if (cmd[0] & 2) b |= BlueButtonBit;
	  if (cmd[0] & 4) b |= YellowButtonBit;
	  dx= cmd[1];  if (cmd[0] & 0x10) dx -= 256;
	  dy= cmd[2];  if (cmd[0] & 0x20) dy -= 256;
	  dy= -dy;
	  self->callback(b, dx, dy);
	  n -= 3;  cmd += 3;
	}
    }
}


static int ms_ps2_send(_self, unsigned char *command, int len)
{
  unsigned char buf[1];
  int i;
  DPRINTF("%s: send\n", self->msName);
  for (i= 0;  i < len;  ++i)
    {
    resend:
      if (1 != write(self->fd, command + i, 1))
	{
	  fprintf(stderr, "%s: could not write command to ps2\n", self->msName);
	  return 0;
	}
      DPRINTF(">%02x\n", command[i]);
      if (1 != ms_read(self, buf, 1, 1, PS2_SEND_DELAY))
	{
	  DPRINTF("%s: send failed\n", self->msName);
	  return 0;
	}
      switch (buf[0])
	{
	case PS2_OK:
	case PS2_SELFTEST_OK:	 /* /dev/input/mice emulation is broken */
	  break;
	case PS2_ERROR:
	  fprintf(stderr, "%s: error response in send\n", self->msName);
	  return 0;
	case PS2_RESEND:
	  DPRINTF("%s: resend\n", self->msName);
	  goto resend;
	default:
	  fprintf(stderr, "%s: illegal response %02x in send\n", self->msName, buf[0]);
	  break;
	}
    }
  return 1;
}


static void ms_ps2_disable(_self)
{ 
  unsigned char command[]= { PS2_DISABLE };
  DPRINTF("%s: disable\n", self->msName);
  if (1 != write(self->fd, command, 1))
    {
	fprintf(stderr, "%s: could not write command to ps2\n", self->msName);
	return;
    }
  DPRINTF(">%02x\n", command[0]);
  while (1 == ms_read(self, command, 1, 1, PS2_DISABLE_DELAY))
    if (PS2_OK == command[0])
      break;
}


static int ms_ps2_enable(_self)
{
  unsigned char command[]= { PS2_ENABLE };
  DPRINTF("%s: enable\n", self->msName);
  return ms_ps2_send(self, command, sizeof(command));
}


static int ms_ps2_reset(_self)
{
  unsigned char command[]= { PS2_RESET }, buf[2];
  DPRINTF("%s: reset\n", self->msName);
  if (!ms_ps2_send(self, command, sizeof(command)))
    return -1;
  if (2 == ms_read(self, buf, 2, 2, PS2_RESET_DELAY))
    {
      DPRINTF("%s: response %02x %02x\n", self->msName, buf[0], buf[1]);
      switch (buf[0])
	{
	case PS2_SELFTEST_OK:
	  return buf[1];	// mouse device id
	  break;
	case PS2_ERROR:
	  fprintf(stderr, "%s: self-test failed\n", self->msName);
	  break;
	default:
	  DPRINTF("%s: bad response\n", self->msName);
	  break;
	}
    }
  /* /dev/input/mice emulation returns PS2_SELFTEST_OK where send()
     expects PS2_OK, causing control to fall through to here.  we pick
     up the mouse id immediately in the flush(), so the only harm done
     is a misleading "reset failed" message while debugging.  */
  ms_ps2_flush(self);
  DPRINTF("%s: reset failed\n", self->msName);
  return -1;
}


static void ms_ps2_init(_self)
{
  int id;
  ms_ps2_disable(self);
  id= ms_ps2_reset(self);
  DPRINTF("%s: mouse id %02x\n", self->msName, id);
  ms_ps2_enable(self);
}

