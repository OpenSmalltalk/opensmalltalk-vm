/////////////////////////////////////////////////////////////////////////
// $Id: sdl.cc,v 1.74 2008/03/06 21:15:40 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2002  MandrakeSoft S.A.
//
//    MandrakeSoft S.A.
//    43, rue d'Aboukir
//    75002 Paris - France
//    http://www.linux-mandrake.com/
//    http://www.mandrakesoft.com/
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
/////////////////////////////////////////////////////////////////////////

#define _MULTI_THREAD

// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE
// is used to know when we are exporting symbols and when we are importing.
#define BX_PLUGGABLE

#include "bochs.h"
#include "iodev.h"
#if BX_WITH_SDL

#include <stdlib.h>
#include <SDL.h>
#include <SDL_endian.h>
#include <SDL_thread.h>

#include "icon_bochs.h"
#include "sdl.h"
#ifdef WIN32
#include "win32dialog.h"
#endif

class bx_sdl_gui_c : public bx_gui_c {
public:
  bx_sdl_gui_c(void);
  DECLARE_GUI_VIRTUAL_METHODS()
  DECLARE_GUI_NEW_VIRTUAL_METHODS()
  virtual void set_display_mode(disp_mode_t newmode);
  virtual void statusbar_setitem(int element, bx_bool active);
#if BX_SHOW_IPS
  virtual void show_ips(Bit32u ips_count);
#endif
};

// declare one instance of the gui object and call macro to insert the
// plugin code
static bx_sdl_gui_c *theGui = NULL;
IMPLEMENT_GUI_PLUGIN_CODE(sdl)

#define LOG_THIS theGui->

#if SDL_BYTEORDER == SDL_BIG_ENDIAN
const Uint32 status_led_green = 0x00ff0000;
const Uint32 status_gray_text = 0x80808000;
#else
const Uint32 status_led_green = 0x0000ff00;
const Uint32 status_gray_text = 0x00808080;
#endif

static unsigned prev_cursor_x=0;
static unsigned prev_cursor_y=0;
static Bit32u convertStringToSDLKey (const char *string);

#define MAX_SDL_BITMAPS 32
struct bitmaps {
  SDL_Surface *surface;
  SDL_Rect src,dst;
  void (*cb)(void);
};

static struct {
  unsigned bmp_id;
  unsigned alignment;
  void (*f)(void);
} hb_entry[BX_MAX_HEADERBAR_ENTRIES];

unsigned bx_headerbar_entries = 0;

SDL_Thread *sdl_thread;
SDL_Surface *sdl_screen, *sdl_fullscreen;
SDL_Event sdl_event;
int sdl_fullscreen_toggle;
int sdl_grab;
unsigned res_x, res_y;
unsigned half_res_x, half_res_y;
int headerbar_height;
static unsigned bx_bitmap_left_xorigin = 0;  // pixels from left
static unsigned bx_bitmap_right_xorigin = 0; // pixels from right
static unsigned int text_rows = 25, text_cols = 80;
Bit8u h_panning = 0, v_panning = 0;
Bit16u line_compare = 1023;
int fontwidth = 8, fontheight = 16;
static unsigned vga_bpp=8;
unsigned tilewidth, tileheight;
unsigned char menufont[256][8];
Uint32 palette[256];
Uint32 headerbar_fg, headerbar_bg;
Bit8u old_mousebuttons=0, new_mousebuttons=0;
int old_mousex=0, new_mousex=0;
int old_mousey=0, new_mousey=0;
bx_bool just_warped = false;
bitmaps *sdl_bitmaps[MAX_SDL_BITMAPS];
int n_sdl_bitmaps = 0;
int statusbar_height = 18;
static unsigned statusitem_pos[12] = {
  0, 170, 210, 250, 290, 330, 370, 410, 450, 490, 530, 570
};
static bx_bool statusitem_active[12];
#if BX_SHOW_IPS
static bx_bool sdl_ips_update = 0;
static char sdl_ips_text[20];
#endif

#if SDL_BYTEORDER == SDL_LIL_ENDIAN
#define SWAP16(X)    (X)
#define SWAP32(X)    (X)
#else
#define SWAP16(X)    SDL_Swap16(X)
#define SWAP32(X)    SDL_Swap32(X)
#endif

static void headerbar_click(int x);

#if BX_SHOW_IPS
#if  defined(__MINGW32__) || defined(_MSC_VER)
  Uint32 SDLCALL sdlTimer(Uint32 interval);
  void alarm(int);
  void bx_signal_handler(int);
#endif
#endif


void switch_to_windowed(void)
{
  SDL_Surface *tmp;
  SDL_Rect src, dst;
  src.x = 0; src.y = 0;
  src.w = res_x; src.h = res_y;
  dst.x = 0; dst.y = 0;

  tmp = SDL_CreateRGBSurface(
      SDL_SWSURFACE,
      res_x,
      res_y,
      32,
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
      0xff000000,
      0x00ff0000,
      0x0000ff00,
      0x000000ff
#else
      0x000000ff,
      0x0000ff00,
      0x00ff0000,
      0xff000000
#endif
      );

  SDL_BlitSurface(sdl_fullscreen,&src,tmp,&dst);
  SDL_UpdateRect(tmp,0,0,res_x,res_y);
  SDL_FreeSurface(sdl_fullscreen);
  sdl_fullscreen = NULL;

  sdl_screen = SDL_SetVideoMode(res_x,res_y+headerbar_height+statusbar_height,32, SDL_SWSURFACE);
  dst.y = headerbar_height;
  SDL_BlitSurface(tmp,&src,sdl_screen,&dst);
  SDL_UpdateRect(tmp,0,0,res_x,res_y+headerbar_height+statusbar_height);
  SDL_FreeSurface(tmp);

  SDL_ShowCursor(1);
  SDL_WM_GrabInput(SDL_GRAB_OFF);
  bx_gui->show_headerbar();
  sdl_grab = 0;
}

void switch_to_fullscreen(void)
{
  SDL_Surface *tmp;
  SDL_Rect src, dst;
  src.x = 0; src.y = headerbar_height;
  src.w = res_x; src.h = res_y;
  dst.x = 0; dst.y = 0;

  tmp = SDL_CreateRGBSurface(
      SDL_SWSURFACE,
      res_x,
      res_y,
      32,
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
      0xff000000,
      0x00ff0000,
      0x0000ff00,
      0x000000ff
#else
      0x000000ff,
      0x0000ff00,
      0x00ff0000,
      0xff000000
#endif
      );

  SDL_BlitSurface(sdl_screen,&src,tmp,&dst);
  SDL_UpdateRect(tmp,0,0,res_x,res_y);
  SDL_FreeSurface(sdl_screen);
  sdl_screen = NULL;

  sdl_fullscreen = SDL_SetVideoMode(res_x,res_y,32, SDL_HWSURFACE|SDL_FULLSCREEN);
  src.y = 0;
  SDL_BlitSurface(tmp,&src,sdl_fullscreen,&dst);
  SDL_UpdateRect(tmp,0,0,res_x,res_y);
  SDL_FreeSurface(tmp);

  SDL_ShowCursor(0);
  SDL_WM_GrabInput(SDL_GRAB_ON);
  sdl_grab = 1;
}

#if BX_SHOW_IPS
#if defined(__MINGW32__) || defined(_MSC_VER)
Uint32 SDLCALL sdlTimer(Uint32 interval)
{
  bx_signal_handler(SIGALRM);
  return interval;
}

void alarm(int time)
{
  SDL_SetTimer(time*1000, sdlTimer);
}
#endif
#endif

bx_sdl_gui_c::bx_sdl_gui_c ()
{
}

#ifdef __MORPHOS__
void bx_sdl_morphos_exit(void)
{
    SDL_Quit();
    if (PowerSDLBase) CloseLibrary(PowerSDLBase);
}
#endif

void bx_sdl_gui_c::specific_init(
    int argc,
    char **argv,
    unsigned x_tilesize,
    unsigned y_tilesize,
    unsigned header_bar_y)
{
  int i,j;
  Uint32 flags;

  put("SDL");

  UNUSED(bochs_icon_bits);

  tilewidth = x_tilesize;
  tileheight = y_tilesize;
  headerbar_height = header_bar_y;

  for(i=0;i<256;i++)
    for(j=0;j<16;j++)
      vga_charmap[i*32+j] = sdl_font8x16[i][j];

  for(i=0;i<256;i++)
    for(j=0;j<8;j++)
      menufont[i][j] = sdl_font8x8[i][j];

  #ifdef __MORPHOS__
  if (!(PowerSDLBase=OpenLibrary("powersdl.library",0)))
  {
    LOG_THIS setonoff(LOGLEVEL_PANIC, ACT_FATAL);
    BX_PANIC (("Unable to open SDL libraries"));
    return;
  }
  #endif

  flags = SDL_INIT_VIDEO;
#if BX_SHOW_IPS
#if  defined(__MINGW32__) || defined(_MSC_VER)
  flags |= SDL_INIT_TIMER;
#endif
#endif
  if (SDL_Init(flags) < 0) {
    LOG_THIS setonoff(LOGLEV_PANIC, ACT_FATAL);
    BX_PANIC (("Unable to initialize SDL libraries"));
    return;
  }
  #ifdef __MORPHOS__
  atexit(bx_sdl_morphos_exit);
  #else
  atexit(SDL_Quit);
  #endif

  sdl_screen = NULL;
  sdl_fullscreen_toggle = 0;
  dimension_update(640,480);

  SDL_EnableKeyRepeat(250,50);
  SDL_WM_SetCaption(BOCHS_WINDOW_NAME, "Bochs");
  SDL_WarpMouse(half_res_x, half_res_y);

  // load keymap for sdl
  if (SIM->get_param_bool(BXPN_KBD_USEMAPPING)->get()) {
    bx_keymap.loadKeymap(convertStringToSDLKey);
  }

  // parse sdl specific options
  if (argc > 1) {
    for (i = 1; i < argc; i++) {
      if (!strcmp(argv[i], "fullscreen")) {
        sdl_fullscreen_toggle = 1;
        switch_to_fullscreen();
      } else {
        BX_PANIC(("Unknown sdl option '%s'", argv[i]));
      }
    }
  }

  new_gfx_api = 1;
#ifdef WIN32
  win32_init_notify_callback();
  dialog_caps = BX_GUI_DLG_ALL;
#endif
}

void sdl_set_status_text(int element, const char *text, bx_bool active)
{
  Uint32 *buf, *buf_row;
  Uint32 disp, fgcolor, bgcolor;
  unsigned char *pfont_row, font_row;
  int rowsleft = statusbar_height - 2;
  int colsleft, textlen;
  int x, xleft, xsize;

  statusitem_active[element] = active;
  if(!sdl_screen) return;
  disp = sdl_screen->pitch/4;
  xleft = statusitem_pos[element] + 2;
  xsize = statusitem_pos[element+1] - xleft - 1;
  buf = (Uint32 *)sdl_screen->pixels + (res_y + headerbar_height + 1) * disp + xleft;
  rowsleft = statusbar_height - 2;
  fgcolor = active?headerbar_fg:status_gray_text;
  if (element > 0) {
    bgcolor = active?status_led_green:headerbar_bg;
  } else {
    bgcolor = headerbar_bg;
  }
  do {
    colsleft = xsize;
    buf_row = buf;
    do
    {
      *buf++ = bgcolor;
    } while(--colsleft);
    buf = buf_row + disp;
  } while(--rowsleft);
  if ((element > 0) && (strlen(text) > 4)) {
    textlen = 4;
  } else {
    textlen = strlen(text);
  }
  buf = (Uint32 *)sdl_screen->pixels + (res_y + headerbar_height + 5) * disp + xleft;
  x = 0;
  do
  {
    pfont_row = &menufont[(unsigned)text[x]][0];
    buf_row = buf;
    rowsleft = 8;
    do
    {
      font_row = *pfont_row++;
      colsleft = 8;
      do
      {
        if((font_row & 0x80) != 0x00)
          *buf++ = fgcolor;
        else
          buf++;
        font_row <<= 1;
      } while(--colsleft);
      buf += (disp - 8);
    } while(--rowsleft);
    buf = buf_row + 8;
    x++;
  } while (--textlen);
  SDL_UpdateRect( sdl_screen, xleft,res_y+headerbar_height+1,xsize,statusbar_height-2);
}

void bx_sdl_gui_c::statusbar_setitem(int element, bx_bool active)
{
  if (element < 0) {
    for (unsigned i = 0; i < statusitem_count; i++) {
      sdl_set_status_text(i+1, statusitem_text[i], active);
    }
  } else if ((unsigned)element < statusitem_count) {
    sdl_set_status_text(element+1, statusitem_text[element], active);
  }
}

void bx_sdl_gui_c::text_update(
    Bit8u *old_text,
    Bit8u *new_text,
    unsigned long cursor_x,
    unsigned long cursor_y,
    bx_vga_tminfo_t tm_info)
{
  Bit8u *pfont_row, *old_line, *new_line, *text_base;
  unsigned int cs_y, i, x, y;
  unsigned int curs, hchars, offset;
  Bit8u fontline, fontpixels, fontrows;
  int rows;
  Uint32 fgcolor, bgcolor;
  Uint32 *buf, *buf_row, *buf_char;
  Uint32 disp;
  Bit16u font_row, mask;
  Bit8u cfstart, cfwidth, cfheight, split_fontrows, split_textrow;
  bx_bool cursor_visible, gfxcharw9, invert, forceUpdate, split_screen;
  bx_bool blink_mode, blink_state;
  Uint32 text_palette[16];

  forceUpdate = 0;
  blink_mode = (tm_info.blink_flags & BX_TEXT_BLINK_MODE) > 0;
  blink_state = (tm_info.blink_flags & BX_TEXT_BLINK_STATE) > 0;
  if (blink_mode) {
    if (tm_info.blink_flags & BX_TEXT_BLINK_TOGGLE)
      forceUpdate = 1;
  }
  if (charmap_updated) {
    forceUpdate = 1;
    charmap_updated = 0;
  }
  for (i=0; i<16; i++) {
    text_palette[i] = palette[DEV_vga_get_actl_pal_idx(i)];
  }
  if ((tm_info.h_panning != h_panning) || (tm_info.v_panning != v_panning)) {
    forceUpdate = 1;
    h_panning = tm_info.h_panning;
    v_panning = tm_info.v_panning;
  }
  if (tm_info.line_compare != line_compare) {
    forceUpdate = 1;
    line_compare = tm_info.line_compare;
  }
  if (sdl_screen) {
    disp = sdl_screen->pitch/4;
    buf_row = (Uint32 *)sdl_screen->pixels + headerbar_height*disp;
  } else {
    disp = sdl_fullscreen->pitch/4;
    buf_row = (Uint32 *)sdl_fullscreen->pixels;
  }
  // first invalidate character at previous and new cursor location
  if ((prev_cursor_y < text_rows) && (prev_cursor_x < text_cols)) {
    curs = prev_cursor_y * tm_info.line_offset + prev_cursor_x * 2;
    old_text[curs] = ~new_text[curs];
  }
  cursor_visible = ((tm_info.cs_start <= tm_info.cs_end) && (tm_info.cs_start < fontheight));
  if((cursor_visible) && (cursor_y < text_rows) && (cursor_x < text_cols)) {
    curs = cursor_y * tm_info.line_offset + cursor_x * 2;
    old_text[curs] = ~new_text[curs];
  } else {
    curs = 0xffff;
  }

  rows = text_rows;
  if (v_panning) rows++;
  y = 0;
  cs_y = 0;
  text_base = new_text - tm_info.start_address;
  split_textrow = (line_compare + v_panning) / fontheight;
  split_fontrows = ((line_compare + v_panning) % fontheight) + 1;
  split_screen = 0;

  do
  {
    buf = buf_row;
    hchars = text_cols;
    if (h_panning) hchars++;
    cfheight = fontheight;
    cfstart = 0;
    if (split_screen)
    {
      if (rows == 1)
      {
        cfheight = (res_y - line_compare - 1) % fontheight;
        if (cfheight == 0) cfheight = fontheight;
      }
    }
    else if (v_panning)
    {
      if (y == 0)
      {
        cfheight -= v_panning;
        cfstart = v_panning;
      }
      else if (rows == 1)
      {
        cfheight = v_panning;
      }
    }
    if (!split_screen && (y == split_textrow))
    {
      if ((split_fontrows - cfstart) < cfheight)
      {
        cfheight = split_fontrows - cfstart;
      }
    }
    new_line = new_text;
    old_line = old_text;
    x = 0;
    offset = cs_y * tm_info.line_offset;
    do
    {
      cfwidth = fontwidth;
      if (h_panning)
      {
        if (hchars > text_cols)
        {
          cfwidth -= h_panning;
        }
        else if (hchars == 1)
        {
          cfwidth = h_panning;
        }
      }
      // check if char needs to be updated
      if(forceUpdate || (old_text[0] != new_text[0])
	  || (old_text[1] != new_text[1]))
      {

	// Get Foreground/Background pixel colors
	fgcolor = text_palette[new_text[1] & 0x0F];
        if (blink_mode) {
          bgcolor = text_palette[(new_text[1] >> 4) & 0x07];
          if (!blink_state && (new_text[1] & 0x80))
            fgcolor = bgcolor;
        } else {
          bgcolor = text_palette[(new_text[1] >> 4) & 0x0F];
        }
	invert = ((offset == curs) && (cursor_visible));
	gfxcharw9 = ((tm_info.line_graphics) && ((new_text[0] & 0xE0) == 0xC0));

	// Display this one char
	fontrows = cfheight;
	fontline = cfstart;
	if (y > 0)
	{
	  pfont_row = &vga_charmap[(new_text[0] << 5)];
	}
	else
	{
	  pfont_row = &vga_charmap[(new_text[0] << 5) + cfstart];
	}
	buf_char = buf;
	do
	{
	  font_row = *pfont_row++;
	  if (gfxcharw9)
	  {
	    font_row = (font_row << 1) | (font_row & 0x01);
	  }
	  else
	  {
	    font_row <<= 1;
	  }
	  if (hchars > text_cols)
	  {
	    font_row <<= h_panning;
	  }
	  fontpixels = cfwidth;
	  if ((invert) && (fontline >= tm_info.cs_start) && (fontline <= tm_info.cs_end))
	    mask = 0x100;
	  else
	    mask = 0x00;
	  do
	  {
	    if ((font_row & 0x100) == mask)
	      *buf = bgcolor;
	    else
	      *buf = fgcolor;
	    buf++;
	    font_row <<= 1;
	  } while(--fontpixels);
	  buf -= cfwidth;
	  buf += disp;
	  fontline++;
	} while(--fontrows);

	// restore output buffer ptr to start of this char
	buf = buf_char;
      }
      // move to next char location on screen
      buf += cfwidth;

      // select next char in old/new text
      new_text+=2;
      old_text+=2;
      offset+=2;
      x++;

    // process one entire horizontal row
    } while(--hchars);

    // go to next character row location
    buf_row += disp * cfheight;
    if (!split_screen && (y == split_textrow))
    {
      new_text = text_base;
      forceUpdate = 1;
      cs_y = 0;
      if (tm_info.split_hpanning) h_panning = 0;
      rows = ((res_y - line_compare + fontheight - 2) / fontheight) + 1;
      split_screen = 1;
    }
    else
    {
      new_text = new_line + tm_info.line_offset;
      old_text = old_line + tm_info.line_offset;
      cs_y++;
      y++;
    }
  } while(--rows);
  h_panning = tm_info.h_panning;
  prev_cursor_x = cursor_x;
  prev_cursor_y = cursor_y;
}

int bx_sdl_gui_c::get_clipboard_text(Bit8u **bytes, Bit32s *nbytes)
{
  return 0;
}

int bx_sdl_gui_c::set_clipboard_text(char *text_snapshot, Bit32u len)
{
  return 0;
}

void bx_sdl_gui_c::graphics_tile_update(Bit8u *snapshot,
    unsigned x, unsigned y)
{
  Uint32 *buf, disp;
  Uint32 *buf_row;
  int i,j;

  if(sdl_screen)
  {
    disp = sdl_screen->pitch/4;
    buf = (Uint32 *)sdl_screen->pixels + (headerbar_height+y)*disp + x;
  }
  else
  {
    disp = sdl_fullscreen->pitch/4;
    buf = (Uint32 *)sdl_fullscreen->pixels + y*disp + x;
  }

  i = tileheight;
  if(i + y > res_y) i = res_y - y;

  // FIXME
  if(i<=0) return;

  switch (vga_bpp)
  {
    case 8: /* 8 bpp */
      do
      {
        buf_row = buf;
        j = tilewidth;
        do
        {
          *buf++ = palette[*snapshot++];
        } while(--j);
        buf = buf_row + disp;
      } while(--i);
      break;
    default:
      BX_PANIC(("%u bpp modes handled by new graphics API", vga_bpp));
      return;
  }
}

bx_svga_tileinfo_t *bx_sdl_gui_c::graphics_tile_info(bx_svga_tileinfo_t *info)
{
  if (!info) {
    info = (bx_svga_tileinfo_t *)malloc(sizeof(bx_svga_tileinfo_t));
    if (!info) {
      return NULL;
    }
  }

  if (sdl_screen) {
    info->bpp = sdl_screen->format->BitsPerPixel;
    info->pitch = sdl_screen->pitch;
    info->red_shift = sdl_screen->format->Rshift + 8 - sdl_screen->format->Rloss;
    info->green_shift = sdl_screen->format->Gshift + 8 - sdl_screen->format->Gloss;
    info->blue_shift = sdl_screen->format->Bshift + 8 - sdl_screen->format->Bloss;
    info->red_mask = sdl_screen->format->Rmask;
    info->green_mask = sdl_screen->format->Gmask;
    info->blue_mask = sdl_screen->format->Bmask;
    info->is_indexed = (sdl_screen->format->palette != NULL);
  }
  else {
    info->bpp = sdl_fullscreen->format->BitsPerPixel;
    info->pitch = sdl_fullscreen->pitch;
    info->red_shift = sdl_fullscreen->format->Rshift + 8 - sdl_screen->format->Rloss;
    info->green_shift = sdl_fullscreen->format->Gshift + 8 - sdl_screen->format->Gloss;
    info->blue_shift = sdl_fullscreen->format->Bshift + 8 - sdl_screen->format->Bloss;
    info->red_mask = sdl_fullscreen->format->Rmask;
    info->green_mask = sdl_fullscreen->format->Gmask;
    info->blue_mask = sdl_fullscreen->format->Bmask;
    info->is_indexed = (sdl_screen->format->palette != NULL);
  }

#ifdef BX_LITTLE_ENDIAN
  info->is_little_endian = 1;
#else
  info->is_little_endian = 0;
#endif

  return info;
}

Bit8u *bx_sdl_gui_c::graphics_tile_get(unsigned x0, unsigned y0,
                            unsigned *w, unsigned *h)
{
  if (x0+tilewidth > res_x) {
    *w = res_x - x0;
  }
  else {
    *w = tilewidth;
  }

  if (y0+tileheight > res_y) {
    *h = res_y - y0;
  }
  else {
    *h = tileheight;
  }

  if (sdl_screen) {
    return (Bit8u *)sdl_screen->pixels +
           sdl_screen->pitch*(headerbar_height+y0) +
           sdl_screen->format->BytesPerPixel*x0;
  }
  else {
    return (Bit8u *)sdl_fullscreen->pixels +
           sdl_fullscreen->pitch*(headerbar_height+y0) +
           sdl_fullscreen->format->BytesPerPixel*x0;
  }
}

void bx_sdl_gui_c::graphics_tile_update_in_place(unsigned x0, unsigned y0,
                                        unsigned w, unsigned h)
{
}

static Bit32u sdl_sym_to_bx_key (SDLKey sym)
{
  switch (sym)
  {
//  case SDLK_UNKNOWN:              return BX_KEY_UNKNOWN;
//  case SDLK_FIRST:                return BX_KEY_FIRST;
    case SDLK_BACKSPACE:            return BX_KEY_BACKSPACE;
    case SDLK_TAB:                  return BX_KEY_TAB;
//  case SDLK_CLEAR:                return BX_KEY_CLEAR;
    case SDLK_RETURN:               return BX_KEY_ENTER;
    case SDLK_PAUSE:                return BX_KEY_PAUSE;
    case SDLK_ESCAPE:               return BX_KEY_ESC;
    case SDLK_SPACE:                return BX_KEY_SPACE;
//  case SDLK_EXCLAIM:              return BX_KEY_EXCLAIM;
//  case SDLK_QUOTEDBL:             return BX_KEY_QUOTEDBL;
//  case SDLK_HASH:                 return BX_KEY_HASH;
//  case SDLK_DOLLAR:               return BX_KEY_DOLLAR;
//  case SDLK_AMPERSAND:            return BX_KEY_AMPERSAND;
    case SDLK_QUOTE:                return BX_KEY_SINGLE_QUOTE;
//  case SDLK_LEFTPAREN:            return BX_KEY_LEFTPAREN;
//  case SDLK_RIGHTPAREN:           return BX_KEY_RIGHTPAREN;
//  case SDLK_ASTERISK:             return BX_KEY_ASTERISK;
//  case SDLK_PLUS:                 return BX_KEY_PLUS;
    case SDLK_COMMA:                return BX_KEY_COMMA;
    case SDLK_MINUS:                return BX_KEY_MINUS;
    case SDLK_PERIOD:               return BX_KEY_PERIOD;
    case SDLK_SLASH:                return BX_KEY_SLASH;
    case SDLK_0:                    return BX_KEY_0;
    case SDLK_1:                    return BX_KEY_1;
    case SDLK_2:                    return BX_KEY_2;
    case SDLK_3:                    return BX_KEY_3;
    case SDLK_4:                    return BX_KEY_4;
    case SDLK_5:                    return BX_KEY_5;
    case SDLK_6:                    return BX_KEY_6;
    case SDLK_7:                    return BX_KEY_7;
    case SDLK_8:                    return BX_KEY_8;
    case SDLK_9:                    return BX_KEY_9;
//  case SDLK_COLON:                return BX_KEY_COLON;
    case SDLK_SEMICOLON:            return BX_KEY_SEMICOLON;
//  case SDLK_LESS:                 return BX_KEY_LESS;
    case SDLK_EQUALS:               return BX_KEY_EQUALS;
//  case SDLK_GREATER:              return BX_KEY_GREATER;
//  case SDLK_QUESTION:             return BX_KEY_QUESTION;
//  case SDLK_AT:                   return BX_KEY_AT;
/*
 Skip uppercase letters
*/
    case SDLK_LEFTBRACKET:          return BX_KEY_LEFT_BRACKET;
    case SDLK_BACKSLASH:            return BX_KEY_BACKSLASH;
    case SDLK_RIGHTBRACKET:         return BX_KEY_RIGHT_BRACKET;
//  case SDLK_CARET:                return BX_KEY_CARET;
//  case SDLK_UNDERSCORE:           return BX_KEY_UNDERSCORE;
    case SDLK_BACKQUOTE:            return BX_KEY_GRAVE;
    case SDLK_a:                    return BX_KEY_A;
    case SDLK_b:                    return BX_KEY_B;
    case SDLK_c:                    return BX_KEY_C;
    case SDLK_d:                    return BX_KEY_D;
    case SDLK_e:                    return BX_KEY_E;
    case SDLK_f:                    return BX_KEY_F;
    case SDLK_g:                    return BX_KEY_G;
    case SDLK_h:                    return BX_KEY_H;
    case SDLK_i:                    return BX_KEY_I;
    case SDLK_j:                    return BX_KEY_J;
    case SDLK_k:                    return BX_KEY_K;
    case SDLK_l:                    return BX_KEY_L;
    case SDLK_m:                    return BX_KEY_M;
    case SDLK_n:                    return BX_KEY_N;
    case SDLK_o:                    return BX_KEY_O;
    case SDLK_p:                    return BX_KEY_P;
    case SDLK_q:                    return BX_KEY_Q;
    case SDLK_r:                    return BX_KEY_R;
    case SDLK_s:                    return BX_KEY_S;
    case SDLK_t:                    return BX_KEY_T;
    case SDLK_u:                    return BX_KEY_U;
    case SDLK_v:                    return BX_KEY_V;
    case SDLK_w:                    return BX_KEY_W;
    case SDLK_x:                    return BX_KEY_X;
    case SDLK_y:                    return BX_KEY_Y;
    case SDLK_z:                    return BX_KEY_Z;
    case SDLK_DELETE:               return BX_KEY_DELETE;
/* End of ASCII mapped keysyms */

/* Numeric keypad */
    case SDLK_KP0:                  return BX_KEY_KP_INSERT;
    case SDLK_KP1:                  return BX_KEY_KP_END;
    case SDLK_KP2:                  return BX_KEY_KP_DOWN;
    case SDLK_KP3:                  return BX_KEY_KP_PAGE_DOWN;
    case SDLK_KP4:                  return BX_KEY_KP_LEFT;
    case SDLK_KP5:                  return BX_KEY_KP_5;
    case SDLK_KP6:                  return BX_KEY_KP_RIGHT;
    case SDLK_KP7:                  return BX_KEY_KP_HOME;
    case SDLK_KP8:                  return BX_KEY_KP_UP;
    case SDLK_KP9:                  return BX_KEY_KP_PAGE_UP;
    case SDLK_KP_PERIOD:            return BX_KEY_KP_DELETE;
    case SDLK_KP_DIVIDE:            return BX_KEY_KP_DIVIDE;
    case SDLK_KP_MULTIPLY:          return BX_KEY_KP_MULTIPLY;
    case SDLK_KP_MINUS:             return BX_KEY_KP_SUBTRACT;
    case SDLK_KP_PLUS:              return BX_KEY_KP_ADD;
    case SDLK_KP_ENTER:             return BX_KEY_KP_ENTER;
//  case SDLK_KP_EQUALS:            return BX_KEY_KP_EQUALS;

/* Arrows + Home/End pad */
    case SDLK_UP:                   return BX_KEY_UP;
    case SDLK_DOWN:                 return BX_KEY_DOWN;
    case SDLK_RIGHT:                return BX_KEY_RIGHT;
    case SDLK_LEFT:                 return BX_KEY_LEFT;
    case SDLK_INSERT:               return BX_KEY_INSERT;
    case SDLK_HOME:                 return BX_KEY_HOME;
    case SDLK_END:                  return BX_KEY_END;
    case SDLK_PAGEUP:               return BX_KEY_PAGE_UP;
    case SDLK_PAGEDOWN:             return BX_KEY_PAGE_DOWN;

/* Function keys */
    case SDLK_F1:                   return BX_KEY_F1;
    case SDLK_F2:                   return BX_KEY_F2;
    case SDLK_F3:                   return BX_KEY_F3;
    case SDLK_F4:                   return BX_KEY_F4;
    case SDLK_F5:                   return BX_KEY_F5;
    case SDLK_F6:                   return BX_KEY_F6;
    case SDLK_F7:                   return BX_KEY_F7;
    case SDLK_F8:                   return BX_KEY_F8;
    case SDLK_F9:                   return BX_KEY_F9;
    case SDLK_F10:                  return BX_KEY_F10;
    case SDLK_F11:                  return BX_KEY_F11;
    case SDLK_F12:                  return BX_KEY_F12;
//  case SDLK_F13:                  return BX_KEY_F13;
//  case SDLK_F14:                  return BX_KEY_F14;
//  case SDLK_F15:                  return BX_KEY_F15;

/* Key state modifier keys */
    case SDLK_NUMLOCK:              return BX_KEY_NUM_LOCK;
    case SDLK_CAPSLOCK:             return BX_KEY_CAPS_LOCK;
    case SDLK_SCROLLOCK:            return BX_KEY_SCRL_LOCK;
    case SDLK_RSHIFT:               return BX_KEY_SHIFT_R;
    case SDLK_LSHIFT:               return BX_KEY_SHIFT_L;
    case SDLK_RCTRL:                return BX_KEY_CTRL_R;
    case SDLK_LCTRL:                return BX_KEY_CTRL_L;
    case SDLK_RALT:                 return BX_KEY_ALT_R;
    case SDLK_LALT:                 return BX_KEY_ALT_L;
    case SDLK_RMETA:                return BX_KEY_ALT_R;
    case SDLK_LMETA:                return BX_KEY_WIN_L;
    case SDLK_LSUPER:               return BX_KEY_WIN_L;
    case SDLK_RSUPER:               return BX_KEY_WIN_R;
//  case SDLK_MODE:                 return BX_KEY_MODE;
//  case SDLK_COMPOSE:              return BX_KEY_COMPOSE;

/* Miscellaneous function keys */
    case SDLK_PRINT:                return BX_KEY_PRINT;
    case SDLK_BREAK:                return BX_KEY_PAUSE;
    case SDLK_MENU:                 return BX_KEY_MENU;
#if 0
    case SDLK_HELP:                 return BX_KEY_HELP;
    case SDLK_SYSREQ:               return BX_KEY_SYSREQ;
    case SDLK_POWER:                return BX_KEY_POWER;
    case SDLK_EURO:                 return BX_KEY_EURO;
    case SDLK_UNDO:                 return BX_KEY_UNDO;
#endif
    default:
      BX_ERROR (("sdl keysym %d not mapped", (int)sym));
      return BX_KEY_UNHANDLED;
  }
}

void bx_sdl_gui_c::handle_events(void)
{
  Bit32u key_event;
  Bit8u mouse_state;
  int wheel_status;

  while(SDL_PollEvent(&sdl_event))
  {
    wheel_status = 0;
    switch(sdl_event.type)
    {
      case SDL_VIDEOEXPOSE:
	if(sdl_fullscreen_toggle == 0)
	  SDL_UpdateRect(sdl_screen, 0,0, res_x, res_y+headerbar_height+statusbar_height);
	else
	  SDL_UpdateRect(sdl_screen, 0,headerbar_height, res_x, res_y);
	break;

      case SDL_MOUSEMOTION:
	//fprintf (stderr, "mouse event to (%d,%d), relative (%d,%d)\n", (int)(sdl_event.motion.x), (int)(sdl_event.motion.y), (int)sdl_event.motion.xrel, (int)sdl_event.motion.yrel);
	if (!sdl_grab) {
	  //fprintf (stderr, "ignore mouse event because sdl_grab is off\n");
	  break;
	}
	if (just_warped
	    && sdl_event.motion.x == half_res_x
	    && sdl_event.motion.y == half_res_y) {
	  // This event was generated as a side effect of the WarpMouse,
	  // and it must be ignored.
	  //fprintf (stderr, "ignore mouse event because it is a side effect of SDL_WarpMouse\n");
	  just_warped = false;
	  break;
	}
	//fprintf (stderr, "processing relative mouse event\n");
        new_mousebuttons = ((sdl_event.motion.state & 0x01)|((sdl_event.motion.state>>1)&0x02)
                            |((sdl_event.motion.state<<1)&0x04));
        DEV_mouse_motion_ext(
            sdl_event.motion.xrel,
            -sdl_event.motion.yrel,
            wheel_status,
            new_mousebuttons);
	old_mousebuttons = new_mousebuttons;
	old_mousex = (int)(sdl_event.motion.x);
	old_mousey = (int)(sdl_event.motion.y);
	//fprintf (stderr, "warping mouse to center\n");
	SDL_WarpMouse(half_res_x, half_res_y);
	just_warped = 1;
	break;

      case SDL_MOUSEBUTTONDOWN:
        if((sdl_event.button.button == SDL_BUTTON_MIDDLE)
            && ((SDL_GetModState() & KMOD_CTRL) > 0)
            && (sdl_fullscreen_toggle == 0))
	{
	  if(sdl_grab == 0)
	  {
	    SDL_ShowCursor(0);
	    SDL_WM_GrabInput(SDL_GRAB_ON);
	  }
	  else
	  {
	    SDL_ShowCursor(1);
	    SDL_WM_GrabInput(SDL_GRAB_OFF);
	  }
	  sdl_grab = ~sdl_grab;
	  toggle_mouse_enable();
	  break;
	} else if (sdl_event.button.y < headerbar_height) {
	  headerbar_click(sdl_event.button.x);
	  break;
	}
#ifdef SDL_BUTTON_WHEELUP
        // get the wheel status
        if (sdl_event.button.button == SDL_BUTTON_WHEELUP) {
          wheel_status = 1;
        }
        if (sdl_event.button.button == SDL_BUTTON_WHEELDOWN) {
          wheel_status = -1;
        }
#endif
      case SDL_MOUSEBUTTONUP:
	// figure out mouse state
	new_mousex = (int)(sdl_event.button.x);
	new_mousey = (int)(sdl_event.button.y);
	// SDL_GetMouseState() returns the state of all buttons
	mouse_state = SDL_GetMouseState(NULL, NULL);
	new_mousebuttons =
	  (mouse_state & 0x01)    |
	  ((mouse_state>>1)&0x02) |
	  ((mouse_state<<1)&0x04) ;
	// filter out middle button if not fullscreen
	if(sdl_fullscreen_toggle == 0)
	  new_mousebuttons &= 0x07;
        // send motion information
        DEV_mouse_motion_ext(
            new_mousex - old_mousex,
            -(new_mousey - old_mousey),
            wheel_status,
            new_mousebuttons);
	// mark current state to diff with next packet
	old_mousebuttons = new_mousebuttons;
	old_mousex = new_mousex;
	old_mousey = new_mousey;
	break;

      case SDL_KEYDOWN:

	// Windows/Fullscreen toggle-check
	if(sdl_event.key.keysym.sym == SDLK_SCROLLOCK)
	{
//	  SDL_WM_ToggleFullScreen(sdl_screen);
	  sdl_fullscreen_toggle = ~sdl_fullscreen_toggle;
	  if(sdl_fullscreen_toggle == 0)
	    switch_to_windowed();
	  else
	    switch_to_fullscreen();
	  bx_gui->show_headerbar();
	  bx_gui->flush();
	  break;
	}

	// convert sym->bochs code
	if (sdl_event.key.keysym.sym > SDLK_LAST) break;
        if (!SIM->get_param_bool(BXPN_KBD_USEMAPPING)->get()) {
	  key_event = sdl_sym_to_bx_key (sdl_event.key.keysym.sym);
	  BX_DEBUG (("keypress scancode=%d, sym=%d, bx_key = %d", sdl_event.key.keysym.scancode, sdl_event.key.keysym.sym, key_event));
	} else {
	  /* use mapping */
	  BXKeyEntry *entry = bx_keymap.findHostKey (sdl_event.key.keysym.sym);
	  if (!entry) {
	    BX_ERROR(( "host key %d (0x%x) not mapped!",
		  (unsigned) sdl_event.key.keysym.sym,
		  (unsigned) sdl_event.key.keysym.sym));
	    break;
	  }
	  key_event = entry->baseKey;
	}
	if (key_event == BX_KEY_UNHANDLED) break;
	DEV_kbd_gen_scancode( key_event);
        if ((key_event == BX_KEY_NUM_LOCK) || (key_event == BX_KEY_CAPS_LOCK)) {
	  DEV_kbd_gen_scancode(key_event | BX_KEY_RELEASED);
        }
	break;

      case SDL_KEYUP:

	// filter out release of Windows/Fullscreen toggle and unsupported keys
	if ((sdl_event.key.keysym.sym != SDLK_SCROLLOCK)
	    && (sdl_event.key.keysym.sym < SDLK_LAST))
	{
	  // convert sym->bochs code
          if (!SIM->get_param_bool(BXPN_KBD_USEMAPPING)->get()) {
            key_event = sdl_sym_to_bx_key (sdl_event.key.keysym.sym);
          } else {
            /* use mapping */
            BXKeyEntry *entry = bx_keymap.findHostKey (sdl_event.key.keysym.sym);
            if (!entry) {
              BX_ERROR(( "host key %d (0x%x) not mapped!",
		    (unsigned) sdl_event.key.keysym.sym,
		    (unsigned) sdl_event.key.keysym.sym));
              break;
            }
            key_event = entry->baseKey;
          }
	  if (key_event == BX_KEY_UNHANDLED) break;
          if ((key_event == BX_KEY_NUM_LOCK) || (key_event == BX_KEY_CAPS_LOCK)) {
            DEV_kbd_gen_scancode(key_event);
          }
	  DEV_kbd_gen_scancode(key_event | BX_KEY_RELEASED);
	}
	break;

      case SDL_QUIT:
	LOG_THIS setonoff(LOGLEV_PANIC, ACT_FATAL);
	BX_PANIC (("User requested shutdown."));
    }
  }
#if BX_SHOW_IPS
  if (sdl_ips_update) {
    sdl_ips_update = 0;
    sdl_set_status_text(0, sdl_ips_text, 1);
  }
#endif
}

void bx_sdl_gui_c::flush(void)
{
  if(sdl_screen)
    SDL_UpdateRect(sdl_screen,0,0,res_x,res_y+headerbar_height);
  else
    SDL_UpdateRect(sdl_fullscreen,0,0,res_x,res_y);
}

void bx_sdl_gui_c::clear_screen(void)
{
  int i = res_y, j;
  Uint32 color;
  Uint32 *buf, *buf_row;
  Uint32 disp;

  if(sdl_screen)
  {
    color = SDL_MapRGB(sdl_screen->format, 0,0,0);
    disp = sdl_screen->pitch/4;
    buf = (Uint32 *)sdl_screen->pixels + headerbar_height*disp;
  }
  else if(sdl_fullscreen)
  {
    color = SDL_MapRGB(sdl_fullscreen->format, 0,0, 0);
    disp = sdl_fullscreen->pitch/4;
    buf = (Uint32 *)sdl_fullscreen->pixels;
  }
  else return;

  do
  {
    buf_row = buf;
    j = res_x;
    while(j--) *buf++ = color;
    buf = buf_row + disp;
  } while(--i);

  if(sdl_screen)
    SDL_UpdateRect(sdl_screen,0,0,res_x,res_y+headerbar_height);
  else
    SDL_UpdateRect(sdl_fullscreen,0,0,res_x,res_y);
}

bx_bool bx_sdl_gui_c::palette_change(
    unsigned index,
    unsigned red,
    unsigned green,
    unsigned blue)
{
  unsigned char palred = red & 0xFF;
  unsigned char palgreen = green & 0xFF;
  unsigned char palblue = blue & 0xFF;

  if(index > 255) return 0;

  if(sdl_screen)
    palette[index] = SDL_MapRGB(sdl_screen->format, palred, palgreen, palblue);
  else if(sdl_fullscreen)
    palette[index] = SDL_MapRGB(sdl_fullscreen->format, palred, palgreen, palblue);

  return 1;
}

void bx_sdl_gui_c::dimension_update(
    unsigned x,
    unsigned y,
    unsigned fheight,
    unsigned fwidth,
    unsigned bpp)
{
  if ((bpp == 8) || (bpp == 15) || (bpp == 16) || (bpp == 24) || (bpp == 32)) {
    vga_bpp = bpp;
  }
  else
  {
    BX_PANIC(("%d bpp graphics mode not supported", bpp));
  }
  if(fheight > 0)
  {
    fontheight = fheight;
    fontwidth = fwidth;
    text_cols = x / fontwidth;
    text_rows = y / fontheight;
  }

  if((x == res_x) && (y == res_y)) return;

  if(sdl_screen)
  {
    SDL_FreeSurface(sdl_screen);
    sdl_screen = NULL;
  }
  if(sdl_fullscreen)
  {
    SDL_FreeSurface(sdl_fullscreen);
    sdl_fullscreen = NULL;
  }

  if(sdl_fullscreen_toggle == 0)
  {
    sdl_screen = SDL_SetVideoMode(x, y+headerbar_height+statusbar_height, 32, SDL_SWSURFACE);
    if(!sdl_screen)
    {
      LOG_THIS setonoff(LOGLEV_PANIC, ACT_FATAL);
      BX_PANIC (("Unable to set requested videomode: %ix%i: %s",x,y,SDL_GetError()));
    }
    headerbar_fg = SDL_MapRGB(
	sdl_screen->format,
	BX_HEADERBAR_FG_RED,
	BX_HEADERBAR_FG_GREEN,
	BX_HEADERBAR_FG_BLUE);
    headerbar_bg = SDL_MapRGB(
	sdl_screen->format,
	BX_HEADERBAR_BG_RED,
	BX_HEADERBAR_BG_GREEN,
	BX_HEADERBAR_BG_BLUE);
  }
  else
  {
    sdl_fullscreen = SDL_SetVideoMode(x, y, 32, SDL_HWSURFACE|SDL_FULLSCREEN);
    if(!sdl_fullscreen)
    {
      LOG_THIS setonoff(LOGLEV_PANIC, ACT_FATAL);
      BX_PANIC (("Unable to set requested videomode: %ix%i: %s",x,y,SDL_GetError()));
    }
  }
  res_x = x;
  res_y = y;
  half_res_x = x/2;
  half_res_y = y/2;
  bx_gui->show_headerbar();
}

unsigned bx_sdl_gui_c::create_bitmap(const unsigned char *bmap,
    unsigned xdim, unsigned ydim)
{
  bitmaps *tmp = new bitmaps;
  Uint32 *buf, *buf_row;
  Uint32 disp;
  unsigned char pixels;

  if (n_sdl_bitmaps >= MAX_SDL_BITMAPS) {
    BX_PANIC (("too many SDL bitmaps. To fix, increase MAX_SDL_BITMAPS"));
    return 0;
  }

  tmp->surface = SDL_CreateRGBSurface(
      SDL_SWSURFACE,
      xdim,
      ydim,
      32,
#if SDL_BYTEORDER == SDL_BIG_ENDIAN
      0xff000000,
      0x00ff0000,
      0x0000ff00,
      0x00000000
#else
      0x000000ff,
      0x0000ff00,
      0x00ff0000,
      0x00000000
#endif
      );
  if(!tmp->surface)
  {
    delete tmp;
    bx_gui->exit();
    LOG_THIS setonoff(LOGLEV_PANIC, ACT_FATAL);
    BX_PANIC (("Unable to create requested bitmap"));
  }
  tmp->src.w = xdim;
  tmp->src.h = ydim;
  tmp->src.x = 0;
  tmp->src.y = 0;
  tmp->dst.x = -1;
  tmp->dst.y = 0;
  tmp->dst.w = xdim;
  tmp->dst.h = ydim;
  tmp->cb = NULL;
  buf = (Uint32 *)tmp->surface->pixels;
  disp = tmp->surface->pitch/4;
  do
  {
    buf_row = buf;
    xdim = tmp->src.w / 8;
    do
    {
      pixels = *bmap++;
      for(unsigned i=0;i<8;i++)
      {
	if((pixels & 0x01) == 0)
	  *buf++ = headerbar_bg;
	else
	  *buf++ = headerbar_fg;
	pixels = pixels >> 1;
      }
    } while(--xdim);
    buf = buf_row + disp;
  } while(--ydim);
  SDL_UpdateRect(
      tmp->surface,
      0, 0,
      tmp->src.w,
      tmp->src.h);
  sdl_bitmaps[n_sdl_bitmaps] = tmp;
  return n_sdl_bitmaps++;
}

unsigned bx_sdl_gui_c::headerbar_bitmap(
    unsigned bmap_id,
    unsigned alignment,
    void (*f)(void))
{
  unsigned hb_index;

  if(bmap_id >= (unsigned)n_sdl_bitmaps) return 0;

  if ((bx_headerbar_entries+1) > BX_MAX_HEADERBAR_ENTRIES)
    BX_PANIC(("too many headerbar entries, increase BX_MAX_HEADERBAR_ENTRIES"));

  bx_headerbar_entries++;
  hb_index = bx_headerbar_entries - 1;

  hb_entry[hb_index].bmp_id = bmap_id;
  hb_entry[hb_index].alignment = alignment;
  hb_entry[hb_index].f = f;
  if (alignment == BX_GRAVITY_LEFT) {
    sdl_bitmaps[bmap_id]->dst.x = bx_bitmap_left_xorigin;
    bx_bitmap_left_xorigin += sdl_bitmaps[bmap_id]->src.w;
  } else {
    bx_bitmap_right_xorigin += sdl_bitmaps[bmap_id]->src.w;
    sdl_bitmaps[bmap_id]->dst.x = bx_bitmap_right_xorigin;
  }
  return hb_index;
}

void bx_sdl_gui_c::replace_bitmap(
    unsigned hbar_id,
    unsigned bmap_id)
{
  SDL_Rect hb_dst;
  unsigned old_id;

  old_id = hb_entry[hbar_id].bmp_id;
  hb_dst = sdl_bitmaps[old_id]->dst;
  sdl_bitmaps[old_id]->dst.x = -1;
  hb_entry[hbar_id].bmp_id = bmap_id;
  sdl_bitmaps[bmap_id]->dst.x = hb_dst.x;
  if(sdl_bitmaps[bmap_id]->dst.x != -1)
  {
    if (hb_entry[hbar_id].alignment == BX_GRAVITY_RIGHT) {
      hb_dst.x = res_x - hb_dst.x;
    }
    SDL_BlitSurface(
        sdl_bitmaps[bmap_id]->surface,
        &sdl_bitmaps[bmap_id]->src,
        sdl_screen,
        &hb_dst);
    SDL_UpdateRect(
        sdl_screen,
        hb_dst.x,
        sdl_bitmaps[bmap_id]->dst.y,
        sdl_bitmaps[bmap_id]->src.w,
        sdl_bitmaps[bmap_id]->src.h);
  }
}

void bx_sdl_gui_c::show_headerbar(void)
{
  Uint32 *buf;
  Uint32 *buf_row;
  Uint32 disp;
  int rowsleft = headerbar_height;
  int colsleft, sb_item;
  int bitmapscount = bx_headerbar_entries;
  unsigned current_bmp, pos_x;
  SDL_Rect hb_dst;

  if(!sdl_screen) return;
  disp = sdl_screen->pitch/4;
  buf = (Uint32 *)sdl_screen->pixels;

  // draw headerbar background
  do
  {
    colsleft = res_x;
    buf_row = buf;
    do
    {
      *buf++ = headerbar_bg;
    } while(--colsleft);
    buf = buf_row + disp;
  } while(--rowsleft);
  SDL_UpdateRect( sdl_screen, 0,0,res_x,headerbar_height);

  // go thru the bitmaps and display the active ones
  while(bitmapscount--)
  {
    current_bmp = hb_entry[bitmapscount].bmp_id;
    if(sdl_bitmaps[current_bmp]->dst.x != -1)
    {
      hb_dst = sdl_bitmaps[current_bmp]->dst;
      if (hb_entry[bitmapscount].alignment == BX_GRAVITY_RIGHT) {
        hb_dst.x = res_x - hb_dst.x;
      }
      SDL_BlitSurface(
	  sdl_bitmaps[current_bmp]->surface,
	  &sdl_bitmaps[current_bmp]->src,
	  sdl_screen,
	  &hb_dst);
      SDL_UpdateRect(
	  sdl_screen,
	  hb_dst.x,
	  sdl_bitmaps[current_bmp]->dst.y,
	  sdl_bitmaps[current_bmp]->src.w,
	  sdl_bitmaps[current_bmp]->src.h);
    }
  }
  // draw statusbar background
  rowsleft = statusbar_height;
  buf = (Uint32 *)sdl_screen->pixels + (res_y + headerbar_height) * disp;
  do
  {
    colsleft = res_x;
    buf_row = buf;
    sb_item = 1;
    pos_x = 0;
    do
    {
      if (pos_x == statusitem_pos[sb_item])
      {
        *buf++ = headerbar_fg;
        if (sb_item < 11) sb_item++;
      }
      else
      {
        *buf++ = headerbar_bg;
      }
      pos_x++;
    } while(--colsleft);
    buf = buf_row + disp;
  } while(--rowsleft);
  SDL_UpdateRect( sdl_screen, 0,res_y+headerbar_height,res_x,statusbar_height);
  for (unsigned i=0; i<statusitem_count; i++) {
    sdl_set_status_text(i+1, statusitem_text[i], statusitem_active[i+1]);
  }
}

void bx_sdl_gui_c::mouse_enabled_changed_specific (bx_bool val)
{
  if(val == 1)
  {
    SDL_ShowCursor(0);
    SDL_WM_GrabInput(SDL_GRAB_ON);
  }
  else
  {
    SDL_ShowCursor(1);
    SDL_WM_GrabInput(SDL_GRAB_OFF);
  }
  sdl_grab = val;
}


void headerbar_click(int x)
{
  int xdim,xorigin;

  for (unsigned i=0; i<bx_headerbar_entries; i++) {
    xdim = sdl_bitmaps[hb_entry[i].bmp_id]->src.w;
    if (hb_entry[i].alignment == BX_GRAVITY_LEFT)
      xorigin = sdl_bitmaps[hb_entry[i].bmp_id]->dst.x;
    else
      xorigin = res_x - sdl_bitmaps[hb_entry[i].bmp_id]->dst.x;
    if ( (x>=xorigin) && (x<(xorigin+xdim))) {
      hb_entry[i].f();
      return;
    }
  }
}

void bx_sdl_gui_c::exit(void)
{
  if(sdl_screen)
    SDL_FreeSurface(sdl_screen);
  if(sdl_fullscreen)
    SDL_FreeSurface(sdl_fullscreen);
  while(n_sdl_bitmaps)
  {
    SDL_FreeSurface(sdl_bitmaps[n_sdl_bitmaps-1]->surface);
    n_sdl_bitmaps--;
  }
}

/// key mapping for SDL
typedef struct keyTableEntry {
  const char *name;
  Bit32u value;
};

#define DEF_SDL_KEY(key) \
  { #key, key },

keyTableEntry keytable[] = {
  // this include provides all the entries.
#include "sdlkeys.h"
  // one final entry to mark the end
  { NULL, 0 }
};

// function to convert key names into SDLKey values.
// This first try will be horribly inefficient, but it only has
// to be done while loading a keymap.  Once the simulation starts,
// this function won't be called.
static Bit32u convertStringToSDLKey (const char *string)
{
  keyTableEntry *ptr;
  for (ptr = &keytable[0]; ptr->name != NULL; ptr++) {
    //BX_DEBUG (("comparing string '%s' to SDL key '%s'", string, ptr->name));
    if (!strcmp (string, ptr->name))
      return ptr->value;
  }
  return BX_KEYMAP_UNKNOWN;
}

void bx_sdl_gui_c::set_display_mode(disp_mode_t newmode)
{
  // if no mode change, do nothing.
  if (disp_mode == newmode) return;
  // remember the display mode for next time
  disp_mode = newmode;
  // If fullscreen mode is on, we must switch back to windowed mode if
  // the user needs to see the text console.
  if (sdl_fullscreen_toggle) {
    switch (newmode) {
      case DISP_MODE_CONFIG:
	BX_DEBUG (("switch to configuration mode (windowed)"));
	switch_to_windowed ();
	break;
      case DISP_MODE_SIM:
	BX_DEBUG (("switch to simulation mode (fullscreen)"));
	switch_to_fullscreen ();
	break;
    }
  }
}

#if BX_SHOW_IPS
void bx_sdl_gui_c::show_ips(Bit32u ips_count)
{
  if (!sdl_ips_update) {
    sprintf(sdl_ips_text, "IPS: %9u", ips_count);
    sdl_ips_update = 1;
  }
}
#endif

#endif /* if BX_WITH_SDL */
