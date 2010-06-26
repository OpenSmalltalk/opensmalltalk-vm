/* sqUnixFBDevKeymap.c -- load a console keymap file
 * 
 * Author: Ian Piumarta <ian.piumarta@inria.fr>
 * 
 * Last edited: 2003-08-21 16:03:28 by piumarta on felina.inria.fr
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


#define	kmprintf(args...)


static void kb_freeKeys(_self)
{
  int column;
  for (column= 0;  column < MAX_NR_KEYMAPS;  ++column)
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

  if (!(self->keyMaps= (unsigned short **)calloc(MAX_NR_KEYMAPS, sizeof(unsigned short *))))
    outOfMemory();

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
	  self->keyMaps[column]= (unsigned short *)calloc(NR_KEYS, sizeof(unsigned short));
	  if (!self->keyMaps[column]) outOfMemory();
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
	  while ((!self->keyMaps[column]) && (column < MAX_NR_KEYMAPS))
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
    }
  fprintf(stderr, "%s:%d: %s\n", mapfile, mapline, err);

  fclose(fp);
  kb_freeKeys(self);

  return 0;
}


static void kb_loadKernelKeyMap(_self)
{
  int map;

  DPRINTF("loading kernel keymap\n");

  if (!(self->keyMaps= (unsigned short **)calloc(MAX_NR_KEYMAPS, sizeof(unsigned short *))))
    outOfMemory();

  for (map= 0;  map < MAX_NR_KEYMAPS;  ++map)
    {
      struct kbentry kb;
      int key;

      kb.kb_index= 0;
      kb.kb_table= map;

      if (ioctl(self->fd, KDGKBENT, (unsigned long)&kb))
	fatalError("KDGKBENT");
      if (K_NOSUCHMAP == kb.kb_value)
	continue;

      if (!(self->keyMaps[map]= (unsigned short *)calloc(NR_KEYS, sizeof(unsigned short))))
	outOfMemory();

      for (key= 0;  key < NR_KEYS;  ++key)
	{
	  kb.kb_index= key;
	  if (ioctl(self->fd, KDGKBENT, (unsigned long)&kb))
	    fatalError("KDGKBENT");
	  self->keyMaps[map][key]= kb.kb_value;
	}
    }

  DPRINTF("kernel keymap loaded\n");
}


static void kb_initKeyMap(_self, char *mapfile)
{
  if (!mapfile)
    kb_loadKernelKeyMap(self);
  else if ((kb_loadKeys(self, mapfile)))
    DPRINTF("using keymap '%s'\n", mapfile);
  else
    fatal("could not load keymap '%s'\n", mapfile);
}


#undef kmprintf
