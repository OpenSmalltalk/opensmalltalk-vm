/* sqUnixFBDevMousePS2.c -- weirdness unique to PS/2 mice
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: 2003-08-20 01:14:32 by piumarta on felina.inria.fr
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


static void ms_ps2_handleEvents(_self)
{
  unsigned char buf[3*8];
  int		n;
  
  if ((n= ms_read(self, buf, sizeof(buf), 3, 100)) >= 3)
    {
      unsigned char *cmd= buf;
      while (n >= 3)
	{
	  int b= 0, dx, dy;
	  // The protocol requires the top 2 bits clear and bit 3 set.
	  // Some Micro$oft mice violate this, but any luser stupid
	  // enough to buy a M$ mouse deserves what they get.
	  if ((cmd[0] & 0xc0) || ((cmd[0] & 0x08) != 0x08))
	    {
	      fprintf(stderr, "%s: illegal command: %02x %02x %02x\n", self->msName,
		      cmd[0], cmd[1], cmd[2]);
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


static void ms_ps2_flush(_self)
{
  unsigned char buf[32];
  dprintf("%s: flush\n", self->msName);
  while (ms_read(self, buf, sizeof(buf), 1, 500000))
    ;
}


static int ms_ps2_send(_self, unsigned char *command, int len)
{
  unsigned char buf[1];
  int i;
  dprintf("%s: send\n", self->msName);
  for (i= 0;  i < len;  ++i)
    {
    resend:
      dprintf("%s: < %02x\n", self->msName, (int)command[i]);
      write(self->fd, command + i, 1);
      if (1 != ms_read(self, buf, 1, 1, 500*1000))
	{
	  dprintf("%s: send failed\n", self->msName);
	  return 0;
	}
      switch (buf[0])
	{
	case 0xfa:	// ack
	  break;
	case 0xfc:	// error
	  fprintf(stderr, "%s: error response in send\n", self->msName);
	  return 0;
	case 0xfe:	// resend
	  dprintf("%s: resend\n", self->msName);
	  goto resend;
	default:
	  fprintf(stderr, "%s: illegal response %02x in send\n", self->msName, buf[0]);
	  break;
	}
    }
  return 1;
}


static int ms_ps2_disable(_self)
{
  unsigned char command[]= { 0xf5 };
  dprintf("%s: disable\n", self->msName);
  write(self->fd, command, 1);
  ms_ps2_flush(self);
  return 1;
}


static int ms_ps2_enable(_self)
{
  unsigned char command[]= { 0xf4 };
  dprintf("%s: enable\n", self->msName);
  return ms_ps2_send(self, command, sizeof(command));
}


static int ms_ps2_reset(_self)
{
  unsigned char command[]= { 0xff }, buf[2];
  dprintf("%s: reset\n", self->msName);
  if (!ms_ps2_send(self, command, sizeof(command)))
    return -1;
  if (2 == ms_read(self, buf, 2, 2, 1500*1000))
    {
      dprintf("%s: response %02x %02x\n", self->msName, buf[0], buf[1]);
      if (0xaa == buf[0])
	return buf[1];
      if (0xfc == buf[0])
	fprintf(stderr, "%s: self-test failed\n", self->msName);
      else
	dprintf("%s: bad response\n", self->msName);
    }
  ms_ps2_flush(self);
  dprintf("%s: reset failed\n", self->msName);
  return -1;
}


static void ms_ps2_init(_self)
{
  int id;
  ms_ps2_disable(self);
  id= ms_ps2_reset(self);	//xxx ID => ImPS2, IePS2, ...
  dprintf("%s: mouse id %02x\n", self->msName, id);
  ms_ps2_enable(self);
}
