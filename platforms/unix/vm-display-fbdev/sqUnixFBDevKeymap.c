/* sqUnixFBDevKeymap.c -- load a console keymap file
 * 
 * Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 * Last edited: 2003-08-21 00:24:13 by piumarta on felina.inria.fr
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


#define	kmprintf(args...)


static void kb_freeKeys(_self)
{
  int column;
  for (column= 0;  column < 256;  ++column)
    if (self->keyMaps[column])
      free(self->keyMaps[column]);
  free(self->keyMaps);
  self->keyMaps= 0;
}


static int kb_loadKeys(_self, char *mapfile)
{
  char		   line[1024];
  char		  *err;
  int		   mapline= 0;
  FILE		  *fp;
  char		  *field;
  char		  *end;
  int		   column;

  if (!(fp= fopen(mapfile, "r")))
    {
      perror(mapfile);
      return 0;
    }

  if (!(self->keyMaps= (unsigned short **)calloc(256, sizeof(unsigned short *))))
    goto outOfMemory;

  if (!fgets(line, sizeof(line), fp)) goto noKeyMaps;
  ++mapline;
  kmprintf("<%s", line);
  if (strncmp(line, "keymaps ", 8)) goto noKeyMaps;
  kmprintf(">KEYMAPS");

  field= line + 8;
  for (;;)
    {
      int last;
      column= last= strtol(field, &end, 0);
      if (field == end) break;
      field= end;
      kmprintf(" [%d", column);
      if ('-' == *field)
	{
	  ++field;
	  last= strtol(field, &end, 0);
	  if (field == end) goto badKeyMaps;
	  field= end;
	}
      kmprintf("-%d]", last);
      while (column <= last)
	{
	  kmprintf(" %d", column);
	  self->keyMaps[column]= (unsigned short *)calloc(128, sizeof(unsigned short));
	  if (!self->keyMaps[column]) goto outOfMemory;
	  ++column;
	}
      if (',' == *field) ++field;
    }

  kmprintf("\n");

  while (!feof(fp))
    {
      int   code;
      int   offset;
      if (!fgets(line, sizeof(line), fp)) break;
      ++mapline;
      kmprintf("<%s", line);
      if (1 != sscanf(line, "keycode %d =%n", &code, &offset)) goto noKeyCode;
      kmprintf(">KEYCODE %d", code);
      field= line + offset;
      column= 0;
      for (;;)
	{
	  long sym= strtol(field, &end, 0);
	  if (field == end) break;
	  while ((!self->keyMaps[column]) && (column < 256))
	    {
	      kmprintf("  -  ");
	      ++column;
	    }
	  if (column > 255) goto tooManySyms;
	  self->keyMaps[column][code]= sym;
	  kmprintf(" %04lx", sym);
	  ++column;
	  field= end;
	}
      kmprintf("\n");
    }
  fclose(fp);

  return 1;

  for (;;)
    {
    noKeyMaps:	 err= "no 'keymaps' entry";			break;
    badKeyMaps:	 err= "bad 'keymaps' entry";			break;
    noKeyCode:	 err= "bad 'keycode' entry";			break;
    tooManySyms: err= "too many columns to fit declared table";	break;
    outOfMemory: err= "out of memory";				break;
    }
  fprintf(stderr, "%s:%d: %s\n", mapfile, mapline, err);

  fclose(fp);
  kb_freeKeys(self);

  return 0;
}


static void kb_initKeyMap(_self, char *mapfile)
{
  if (mapfile)
    {
      if ((kb_loadKeys(self, mapfile)))
	dprintf("using keymap '%s'\n", mapfile);
      else
	{
	  fprintf(stderr, "could not load keymap '%s'\n", mapfile);
	  exit(1);
	}
    }

  if (!self->keyMaps)
    {
      int c, m;
      if (!(self->keyMaps= (unsigned short **)calloc(256, sizeof(unsigned short *))))
	fatal("out of memory");
      for (c= 0;  c < 128;  ++c)
	for (m= 0;  m < 13;  ++m)
	  {
	    static unsigned short defaultKeyMap[128][13]= {
#	      include "defaultKeyboardMap.h"
	    };
	    int code= defaultKeyMap[c][m];
	    if (code)
	      {
		if (!self->keyMaps[m])
		  self->keyMaps[m]=
		    (unsigned short *)calloc(128, sizeof(unsigned short));
		self->keyMaps[m][c]= code;
	      }
	  }
    }
}


#undef kmprintf
