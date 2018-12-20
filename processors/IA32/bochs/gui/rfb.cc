/////////////////////////////////////////////////////////////////////////
// $Id: rfb.cc,v 1.58 2008/04/07 20:20:04 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2000  Psyon.Org!
//
//    Donald Becker
//    http://www.psyon.org
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

// RFB still to do :
// - properly handle SetPixelFormat, including big/little-endian flag
// - depth > 8bpp support
// - full dimension update support (desktop size should be an option)
// - optional compression support


// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE
// is used to know when we are exporting symbols and when we are importing.
#define BX_PLUGGABLE

#include "bochs.h"
#include "iodev.h"
#if BX_WITH_RFB

#include "icon_bochs.h"
#include "font/vga.bitmap.h"
#if BX_WITH_SDL && !BX_PLUGINS
extern unsigned char sdl_font8x8[256][8];
#else
#include "sdl.h" // 8x8 font for status text
#endif

class bx_rfb_gui_c : public bx_gui_c {
public:
  bx_rfb_gui_c (void) {}
  DECLARE_GUI_VIRTUAL_METHODS()
  DECLARE_GUI_NEW_VIRTUAL_METHODS()
  void get_capabilities(Bit16u *xres, Bit16u *yres, Bit16u *bpp);
  void statusbar_setitem(int element, bx_bool active);
#if BX_SHOW_IPS
  void show_ips(Bit32u ips_count);
#endif
};

// declare one instance of the gui object and call macro to insert the
// plugin code
static bx_rfb_gui_c *theGui = NULL;
IMPLEMENT_GUI_PLUGIN_CODE(rfb)

#define LOG_THIS theGui->

#include "rfb.h"

#ifdef WIN32

#include <winsock.h>
#include <process.h>

#else

#include <sys/socket.h>
#include <netinet/tcp.h>
#include <netinet/in.h>
#include <unistd.h>
#ifndef __QNXNTO__
#include <sys/errno.h>
#else
#include <errno.h>
#endif
#include <pthread.h>

typedef int SOCKET;
#ifndef INVALID_SOCKET
#define INVALID_SOCKET -1
#endif

#endif

static bool keep_alive;
static bool client_connected;

#define BX_RFB_PORT_MIN 5900
#define BX_RFB_PORT_MAX 5949
static unsigned short rfbPort;

// Headerbar stuff
unsigned rfbBitmapCount = 0;
static struct {
    char     *bmap;
    unsigned xdim;
    unsigned ydim;
} rfbBitmaps[BX_MAX_PIXMAPS];

static unsigned rfbHeaderbarBitmapCount = 0;
struct _rfbHeaderbarBitmaps {
    unsigned int index;
    unsigned int xorigin;
    unsigned int yorigin;
    unsigned int alignment;
    void (*f)(void);
} rfbHeaderbarBitmaps[BX_MAX_HEADERBAR_ENTRIES];

//Keyboard stuff
#define KEYBOARD true
#define MOUSE    false
#define MAX_KEY_EVENTS 512
static struct {
    bool type;
    int  key;
    int  down;
    int  x;
    int  y;
} rfbKeyboardEvent[MAX_KEY_EVENTS];
static unsigned long rfbKeyboardEvents = 0;
static bool          bKeyboardInUse = false;

// Misc Stuff
static struct {
    unsigned int x;
    unsigned int y;
    unsigned int width;
    unsigned int height;
    bool updated;
} rfbUpdateRegion;

#define BX_RFB_MAX_XDIM 720
#define BX_RFB_MAX_YDIM 480

static char  *rfbScreen;
static char  rfbPalette[256];

static unsigned rfbWindowX, rfbWindowY;
static unsigned rfbDimensionX, rfbDimensionY;
static long  rfbHeaderbarY;
static long  rfbTileX = 0;
static long  rfbTileY = 0;
static unsigned long  rfbCursorX = 0;
static unsigned long  rfbCursorY = 0;
static unsigned long  rfbOriginLeft  = 0;
static unsigned long  rfbOriginRight = 0;
static unsigned  rfbStatusbarY = 18;
static unsigned rfbStatusitemPos[12] = {
  0, 170, 210, 250, 290, 330, 370, 410, 450, 490, 530, 570
};
static bx_bool rfbStatusitemActive[12];

static unsigned int text_rows=25, text_cols=80;
static unsigned int font_height=16, font_width=8;

//static unsigned long ServerThread   = 0;
//static unsigned long ServerThreadID = 0;

static SOCKET sGlobal;

static Bit32u clientEncodingsCount = 0;
static Bit32u *clientEncodings = NULL;

void CDECL ServerThreadInit(void *indata);
void HandleRfbClient(SOCKET sClient);
int  ReadExact(int sock, char *buf, int len);
int  WriteExact(int sock, char *buf, int len);
void DrawBitmap(int x, int y, int width, int height, char *bmap, char color, bool update_client);
void DrawChar(int x, int y, int width, int height, int fonty, char *bmap, char color, bx_bool gfxchar);
void UpdateScreen(unsigned char *newBits, int x, int y, int width, int height, bool update_client);
void SendUpdate(int x, int y, int width, int height);
void StartThread();
void rfbKeyPressed(Bit32u key, int press_release);
void rfbMouseMove(int x, int y, int bmask);
void DrawColorPalette();

static const rfbPixelFormat BGR233Format = {
    8, 8, 1, 1, 7, 7, 3, 0, 3, 6
};

// VNCViewer code to be replaced
#define PF_EQ(x,y) ((x.bitsPerPixel == y.bitsPerPixel) && (x.depth == y.depth) && (x.trueColourFlag == y.trueColourFlag) &&    ((x.bigEndianFlag == y.bigEndianFlag) || (x.bitsPerPixel == 8)) && (!x.trueColourFlag || ((x.redMax == y.redMax) &&    (x.greenMax == y.greenMax) && (x.blueMax == y.blueMax) && (x.redShift == y.redShift) && (x.greenShift == y.greenShift) && (x.blueShift == y.blueShift))))


// ::SPECIFIC_INIT()
//
// Called from gui.cc, once upon program startup, to allow for the
// specific GUI code (X11, BeOS, ...) to be initialized.
//
// argc, argv: not used right now, but the intention is to pass native GUI
//     specific options from the command line.  (X11 options, BeOS options,...)
//
// tilewidth, tileheight: for optimization, graphics_tile_update() passes
//     only updated regions of the screen to the gui code to be redrawn.
//     These define the dimensions of a region (tile).
// headerbar_y:  A headerbar (toolbar) is display on the top of the
//     VGA window, showing floppy status, and other information.  It
//     always assumes the width of the current VGA mode width, but
//     it's height is defined by this parameter.

void bx_rfb_gui_c::specific_init(int argc, char **argv, unsigned tilewidth, unsigned tileheight, unsigned headerbar_y)
{
  unsigned char fc, vc;
  int i, timeout = 30;

  put("RFB");
  UNUSED(bochs_icon_bits);

  // the ask menu doesn't work on the client side
  io->set_log_action(LOGLEV_PANIC, ACT_FATAL);

  rfbHeaderbarY = headerbar_y;
  rfbDimensionX = BX_RFB_MAX_XDIM;
  rfbDimensionY = BX_RFB_MAX_YDIM;
  rfbWindowX = rfbDimensionX;
  rfbWindowY = rfbDimensionY + rfbHeaderbarY + rfbStatusbarY;
  rfbTileX      = tilewidth;
  rfbTileY      = tileheight;

  for(i = 0; i < 256; i++) {
    for(int j = 0; j < 16; j++) {
      vc = bx_vgafont[i].data[j];
      fc = 0;
      for (int b = 0; b < 8; b++) {
        fc |= (vc & 0x01) << (7 - b);
        vc >>= 1;
      }
      vga_charmap[i*32+j] = fc;
    }
  }

  rfbScreen = (char *)malloc(rfbWindowX * rfbWindowY);
  memset(&rfbPalette, 0, sizeof(rfbPalette));
  rfbPalette[7] = (char)0xAD;
  rfbPalette[63] = (char)0xFF;

  rfbUpdateRegion.x = rfbWindowX;
  rfbUpdateRegion.y = rfbWindowY;
  rfbUpdateRegion.width  = 0;
  rfbUpdateRegion.height = 0;
  rfbUpdateRegion.updated = false;

  clientEncodingsCount=0;
  clientEncodings=NULL;

  keep_alive = true;
  client_connected = false;
  StartThread();

#ifdef WIN32
  Sleep(1000);
  SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_BELOW_NORMAL);
#endif
  if (SIM->get_param_bool(BXPN_PRIVATE_COLORMAP)->get()) {
    BX_ERROR(("private_colormap option ignored."));
  }

  // parse rfb specific options
  if (argc > 1) {
    for (i = 1; i < argc; i++) {
      if (!strncmp(argv[i], "timeout=", 8)) {
        timeout = atoi(&argv[i][8]);
      } else {
        BX_PANIC(("Unknown rfb option '%s'", argv[i]));
      }
    }
  }

  while ((!client_connected) && (timeout--)) {
#ifdef WIN32
    Sleep(1000);
#else
    sleep(1);
#endif
  }
  if (timeout < 0) BX_PANIC(("timeout! no client present"));

  new_gfx_api = 1;
  dialog_caps = 0;
}

void rfbSetStatusText(int element, const char *text, bx_bool active)
{
  char *newBits;
  unsigned xleft, xsize, color, i, len;

  rfbStatusitemActive[element] = active;
  xleft = rfbStatusitemPos[element] + 2;
  xsize = rfbStatusitemPos[element+1] - xleft - 1;
  newBits = (char *)malloc(((xsize / 8) + 1) * (rfbStatusbarY - 2));
  memset(newBits, 0, ((xsize / 8) + 1) * (rfbStatusbarY - 2));
  for (i=0; i<(rfbStatusbarY - 2); i++) {
    newBits[((xsize / 8) + 1) * i] = 0;
  }
  if (element > 0) {
    color = active?0xa0:0xf7;
  } else {
    color = 0xf0;
  }
  DrawBitmap(xleft, rfbWindowY - rfbStatusbarY + 1, xsize, rfbStatusbarY - 2, newBits, color, false);
  free(newBits);
  len = ((element > 0) && (strlen(text) > 4)) ? 4 : strlen(text);
  for (i = 0; i < len; i++) {
    DrawChar(xleft + i * 8 + 2, rfbWindowY - rfbStatusbarY + 5, 8, 8, 0,
      (char *)&sdl_font8x8[(unsigned)text[i]][0], color, 0);
  }
  if (xleft < rfbUpdateRegion.x) rfbUpdateRegion.x = xleft;
  if ((rfbWindowY - rfbStatusbarY + 1) < rfbUpdateRegion.y) rfbUpdateRegion.y = rfbWindowY - rfbStatusbarY + 1;
  if (((xleft + xsize) - rfbUpdateRegion.x) > rfbUpdateRegion.width) rfbUpdateRegion.width = ((xleft + xsize) - rfbUpdateRegion.x);
  if (((rfbWindowY - 2) - rfbUpdateRegion.y) > rfbUpdateRegion.height) rfbUpdateRegion.height = ((rfbWindowY - 2) - rfbUpdateRegion.y);
  rfbUpdateRegion.updated = true;
}

void bx_rfb_gui_c::statusbar_setitem(int element, bx_bool active)
{
  if (element < 0) {
    for (unsigned i = 0; i < statusitem_count; i++) {
      rfbSetStatusText(i+1, statusitem_text[i], active);
    }
  } else if ((unsigned)element < statusitem_count) {
    rfbSetStatusText(element+1, statusitem_text[element], active);
  }
}

#ifdef WIN32
bool InitWinsock()
{
    WSADATA wsaData;
    if(WSAStartup(MAKEWORD(1,1), &wsaData) != 0) return false;
    return true;
}
#endif

#ifdef WIN32
bool StopWinsock()
{
    WSACleanup();
    return true;
}
#endif

void CDECL ServerThreadInit(void *indata)
{
    SOCKET             sServer;
    SOCKET             sClient;
    struct sockaddr_in sai;
    unsigned int       sai_size;
    int port_ok = 0;
    int one=1;

#ifdef WIN32
    SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_IDLE);
    if(!InitWinsock()) {
        BX_PANIC(("could not initialize winsock."));
        goto end_of_thread;
    }
#endif

    sServer = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if(sServer == -1) {
        BX_PANIC(("could not create socket."));
        goto end_of_thread;
    }
    if (setsockopt(sServer, SOL_SOCKET, SO_REUSEADDR, (const char *)&one, sizeof(int)) == -1)  {
        BX_PANIC(("could not set socket option."));
        goto end_of_thread;
    }

    for (rfbPort = BX_RFB_PORT_MIN; rfbPort <= BX_RFB_PORT_MAX; rfbPort++) {
      sai.sin_addr.s_addr = INADDR_ANY;
      sai.sin_family      = AF_INET;
      sai.sin_port        = htons(rfbPort);
      BX_INFO (("Trying port %d", rfbPort));
      if(bind(sServer, (struct sockaddr *)&sai, sizeof(sai)) == -1) {
          BX_INFO(("Could not bind socket."));
          continue;
      }
      if(listen(sServer, SOMAXCONN) == -1) {
          BX_INFO(("Could not listen on socket."));
          continue;
      }
      // success
      port_ok = 1;
      break;
    }
    if (!port_ok) {
      BX_PANIC (("RFB could not bind any port between %d and %d",
        BX_RFB_PORT_MIN,
        BX_RFB_PORT_MAX));
      goto end_of_thread;
    }
    BX_INFO (("listening for connections on port %i", rfbPort));
    sai_size = sizeof(sai);
    while(keep_alive) {
        sClient = accept(sServer, (struct sockaddr *)&sai, (socklen_t*)&sai_size);
        if(sClient != INVALID_SOCKET) {
            HandleRfbClient(sClient);
            sGlobal = INVALID_SOCKET;
            close(sClient);
        } else {
            close(sClient);
        }
    }

end_of_thread:
#ifdef WIN32
    StopWinsock();
#endif
    return;
}

void HandleRfbClient(SOCKET sClient)
{
    char rfbName[] = "Bochs-RFB";
    rfbProtocolVersionMessage pv;
    int one = 1;
    U32 auth;
    rfbClientInitMessage cim;
    rfbServerInitMessage sim;

    client_connected = true;
    setsockopt(sClient, IPPROTO_TCP, TCP_NODELAY, (const char *)&one, sizeof(one));
    BX_INFO(("accepted client connection."));
    snprintf(pv , rfbProtocolVersionMessageSize,
              rfbProtocolVersionFormat,
              rfbServerProtocolMajorVersion,
              rfbServerProtocolMinorVersion);

    if(WriteExact(sClient, pv, rfbProtocolVersionMessageSize) < 0) {
        BX_ERROR(("could not send protocol version."));
        return;
    }
    if(ReadExact(sClient, pv, rfbProtocolVersionMessageSize) < 0) {
        BX_ERROR(("could not receive client protocol version."));
        return;
    }
    pv[rfbProtocolVersionMessageSize-1]=0; // Drop last character
    BX_INFO(("Client protocol version is '%s'", pv));
    // FIXME should check for version number

    auth = htonl(rfbSecurityNone);

    if(WriteExact(sClient, (char *)&auth, sizeof(auth)) < 0) {
        BX_ERROR(("could not send authorization method."));
        return;
    }

    if(ReadExact(sClient, (char *)&cim, rfbClientInitMessageSize) < 0) {
        BX_ERROR(("could not receive client initialization message."));
        return;
    }

    sim.framebufferWidth  = htons((short)rfbWindowX);
    sim.framebufferHeight = htons((short)rfbWindowY);
    sim.serverPixelFormat            = BGR233Format;
    sim.serverPixelFormat.redMax     = htons(sim.serverPixelFormat.redMax);
    sim.serverPixelFormat.greenMax   = htons(sim.serverPixelFormat.greenMax);
    sim.serverPixelFormat.blueMax    = htons(sim.serverPixelFormat.blueMax);
    sim.nameLength = strlen(rfbName);
    sim.nameLength = htonl(sim.nameLength);
    if(WriteExact(sClient, (char *)&sim, rfbServerInitMessageSize) < 0) {
        BX_ERROR(("could send server initialization message."));
        return;
    }
    if(WriteExact(sClient, rfbName, strlen(rfbName)) < 0) {
        BX_ERROR (("could not send server name."));
        return;
    }

    sGlobal = sClient;
    while(keep_alive) {
        U8 msgType;
        int n;

        if((n = recv(sClient, (char *)&msgType, 1, MSG_PEEK)) <= 0) {
            if(n == 0) {
                        BX_ERROR(("client closed connection."));
            } else {
                BX_ERROR(("error receiving data."));
            }
            return;
        }

        switch(msgType) {
        case rfbSetPixelFormat:
            {
                rfbSetPixelFormatMessage spf;
                ReadExact(sClient, (char *)&spf, sizeof(rfbSetPixelFormatMessage));

                spf.pixelFormat.bitsPerPixel = spf.pixelFormat.bitsPerPixel;
                spf.pixelFormat.depth = spf.pixelFormat.depth;
                spf.pixelFormat.trueColourFlag = (spf.pixelFormat.trueColourFlag ? 1 : 0);
                spf.pixelFormat.bigEndianFlag = (spf.pixelFormat.bigEndianFlag ? 1 : 0);
                spf.pixelFormat.redMax = ntohs(spf.pixelFormat.redMax);
                spf.pixelFormat.greenMax = ntohs(spf.pixelFormat.greenMax);
                spf.pixelFormat.blueMax = ntohs(spf.pixelFormat.blueMax);
                spf.pixelFormat.redShift = spf.pixelFormat.redShift;
                spf.pixelFormat.greenShift = spf.pixelFormat.greenShift;
                spf.pixelFormat.blueShift = spf.pixelFormat.blueShift;

                if (!PF_EQ(spf.pixelFormat, BGR233Format)) {
                    BX_ERROR(("client has wrong pixel format (%d %d %d %d %d %d %d %d %d)",
			      spf.pixelFormat.bitsPerPixel,spf.pixelFormat.depth,spf.pixelFormat.trueColourFlag,
			      spf.pixelFormat.bigEndianFlag,spf.pixelFormat.redMax,spf.pixelFormat.greenMax,
			      spf.pixelFormat.blueMax,spf.pixelFormat.redShift,spf.pixelFormat.blueShift));
                    //return;
                }
                break;
            }
        case rfbFixColourMapEntries:
            {
                rfbFixColourMapEntriesMessage fcme;
                ReadExact(sClient, (char *)&fcme, sizeof(rfbFixColourMapEntriesMessage));
                break;
            }
        case rfbSetEncodings:
            {
                rfbSetEncodingsMessage se;
                Bit32u                 i;
                U32                    enc;

                // free previously registered encodings
                if (clientEncodings != NULL) {
                    delete [] clientEncodings;
                    clientEncodingsCount = 0;
                }

                ReadExact(sClient, (char *)&se, sizeof(rfbSetEncodingsMessage));

                // Alloc new clientEncodings
                clientEncodingsCount = ntohs(se.numberOfEncodings);
                clientEncodings = new Bit32u[clientEncodingsCount];

                for(i = 0; i < clientEncodingsCount; i++) {
                    if((n = ReadExact(sClient, (char *)&enc, sizeof(U32))) <= 0) {
                        if(n == 0) {
                            BX_ERROR(("client closed connection."));
                        } else {
                            BX_ERROR(("error receiving data."));
                        }
                        return;
                    }
                    clientEncodings[i]=ntohl(enc);
                }

                // print supported encodings
                BX_INFO(("rfbSetEncodings : client supported encodings:"));
                for(i = 0; i < clientEncodingsCount; i++) {
                    Bit32u j;
                    bx_bool found = 0;
                    for (j=0; j < rfbEncodingsCount; j ++) {
                        if (clientEncodings[i] == rfbEncodings[j].id) {
                             BX_INFO(("%08x %s", rfbEncodings[j].id, rfbEncodings[j].name));
                             found=1;
                             break;
                             }
                        }
                    if (!found) BX_INFO(("%08x Unknown", clientEncodings[i]));
                    }
                break;
            }
        case rfbFramebufferUpdateRequest:
            {
                rfbFramebufferUpdateRequestMessage fur;

                ReadExact(sClient, (char *)&fur, sizeof(rfbFramebufferUpdateRequestMessage));
                if(!fur.incremental) {
                    rfbUpdateRegion.x = 0;
                    rfbUpdateRegion.y = 0;
                    rfbUpdateRegion.width  = rfbWindowX;
                    rfbUpdateRegion.height = rfbWindowY;
                    rfbUpdateRegion.updated = true;
                } //else {
                //    if(fur.x < rfbUpdateRegion.x) rfbUpdateRegion.x = fur.x;
                //    if(fur.y < rfbUpdateRegion.x) rfbUpdateRegion.y = fur.y;
                //    if(((fur.x + fur.w) - rfbUpdateRegion.x) > rfbUpdateRegion.width) rfbUpdateRegion.width = ((fur.x + fur.w) - rfbUpdateRegion.x);
                //    if(((fur.y + fur.h) - rfbUpdateRegion.y) > rfbUpdateRegion.height) rfbUpdateRegion.height = ((fur.y + fur.h) - rfbUpdateRegion.y);
                //}
                //rfbUpdateRegion.updated = true;
                break;
            }
        case rfbKeyEvent:
            {
                rfbKeyEventMessage ke;
                ReadExact(sClient, (char *)&ke, sizeof(rfbKeyEventMessage));
                ke.key = ntohl(ke.key);
                while(bKeyboardInUse);
                bKeyboardInUse = true;
                if (rfbKeyboardEvents >= MAX_KEY_EVENTS) break;
                rfbKeyboardEvent[rfbKeyboardEvents].type = KEYBOARD;
                rfbKeyboardEvent[rfbKeyboardEvents].key  = ke.key;
                rfbKeyboardEvent[rfbKeyboardEvents].down = ke.downFlag;
                rfbKeyboardEvents++;
                bKeyboardInUse = false;
                break;
            }
        case rfbPointerEvent:
            {
                rfbPointerEventMessage pe;
                ReadExact(sClient, (char *)&pe, sizeof(rfbPointerEventMessage));
                while(bKeyboardInUse);
                bKeyboardInUse = true;
                if (rfbKeyboardEvents >= MAX_KEY_EVENTS) break;
                rfbKeyboardEvent[rfbKeyboardEvents].type = MOUSE;
                rfbKeyboardEvent[rfbKeyboardEvents].x    = ntohs(pe.xPosition);
                rfbKeyboardEvent[rfbKeyboardEvents].y    = ntohs(pe.yPosition);
                rfbKeyboardEvent[rfbKeyboardEvents].down = (pe.buttonMask & 0x01)
                                                           | ((pe.buttonMask>>1) & 0x02)
                                                           | ((pe.buttonMask<<1) & 0x04);
                rfbKeyboardEvents++;
                bKeyboardInUse = false;
                break;
            }
        case rfbClientCutText:
            {
                rfbClientCutTextMessage cct;
                ReadExact(sClient, (char *)&cct, sizeof(rfbClientCutTextMessage));
                break;
            }
        }
    }
}
// ::HANDLE_EVENTS()
//
// Called periodically (vga_update_interval in .bochsrc) so the
// the gui code can poll for keyboard, mouse, and other
// relevant events.

void bx_rfb_gui_c::handle_events(void)
{
    unsigned int i = 0;
    while(bKeyboardInUse);
    bKeyboardInUse = true;
    if(rfbKeyboardEvents > 0) {
        for(i = 0; i < rfbKeyboardEvents; i++) {
            if(rfbKeyboardEvent[i].type == KEYBOARD) {
                rfbKeyPressed(rfbKeyboardEvent[i].key, rfbKeyboardEvent[i].down);
            } else { //type == MOUSE;
                rfbMouseMove(rfbKeyboardEvent[i].x, rfbKeyboardEvent[i].y, rfbKeyboardEvent[i].down);
            }
        }
        rfbKeyboardEvents = 0;
    }
    bKeyboardInUse = false;

    if(rfbUpdateRegion.updated) {
        SendUpdate(rfbUpdateRegion.x, rfbUpdateRegion.y, rfbUpdateRegion.width, rfbUpdateRegion.height);
        rfbUpdateRegion.x = rfbWindowX;
        rfbUpdateRegion.y = rfbWindowY;
        rfbUpdateRegion.width  = 0;
        rfbUpdateRegion.height = 0;
    }
    rfbUpdateRegion.updated = false;
}

// ::FLUSH()
//
// Called periodically, requesting that the gui code flush all pending
// screen update requests.

void bx_rfb_gui_c::flush(void)
{
}

// ::CLEAR_SCREEN()
//
// Called to request that the VGA region is cleared.  Don't
// clear the area that defines the headerbar.
void bx_rfb_gui_c::clear_screen(void)
{
    memset(&rfbScreen[rfbWindowX * rfbHeaderbarY], 0, rfbWindowX * rfbDimensionY);
}

// ::TEXT_UPDATE()
//
// Called in a VGA text mode, to update the screen with
// new content.
//
// old_text: array of character/attributes making up the contents
//           of the screen from the last call.  See below
// new_text: array of character/attributes making up the current
//           contents, which should now be displayed.  See below
//
// format of old_text & new_text: each is tm_info.line_offset*text_rows
//     bytes long. Each character consists of 2 bytes.  The first by is
//     the character value, the second is the attribute byte.
//
// cursor_x: new x location of cursor
// cursor_y: new y location of cursor
// tm_info:  this structure contains information for additional
//           features in text mode (cursor shape, line offset,...)

void bx_rfb_gui_c::text_update(Bit8u *old_text, Bit8u *new_text, unsigned long cursor_x, unsigned long cursor_y, bx_vga_tminfo_t tm_info)
{
  Bit8u *old_line, *new_line;
  Bit8u cAttr, cChar;
  unsigned int  curs, hchars, offset, rows, x, y, xc, yc;
  bx_bool force_update=0, gfxchar, blink_state, blink_mode;

  blink_mode = (tm_info.blink_flags & BX_TEXT_BLINK_MODE) > 0;
  blink_state = (tm_info.blink_flags & BX_TEXT_BLINK_STATE) > 0;
  if (blink_mode) {
    if (tm_info.blink_flags & BX_TEXT_BLINK_TOGGLE)
      force_update = 1;
  }
  if(charmap_updated) {
    force_update = 1;
    charmap_updated = 0;
  }

  // first invalidate character at previous and new cursor location
  if ((rfbCursorY < text_rows) && (rfbCursorX < text_cols)) {
    curs = rfbCursorY * tm_info.line_offset + rfbCursorX * 2;
    old_text[curs] = ~new_text[curs];
  }
  if((tm_info.cs_start <= tm_info.cs_end) && (tm_info.cs_start < font_height) &&
     (cursor_y < text_rows) && (cursor_x < text_cols)) {
    curs = cursor_y * tm_info.line_offset + cursor_x * 2;
    old_text[curs] = ~new_text[curs];
  } else {
    curs = 0xffff;
  }

  rows = text_rows;
  y = 0;
  do {
    hchars = text_cols;
    new_line = new_text;
    old_line = old_text;
    offset = y * tm_info.line_offset;
    yc = y * font_height + rfbHeaderbarY;
    x = 0;
    do {
      if (force_update || (old_text[0] != new_text[0])
          || (old_text[1] != new_text[1])) {
        cChar = new_text[0];
        if (blink_mode) {
          cAttr = new_text[1] & 0x7F;
          if (!blink_state && (new_text[1] & 0x80))
            cAttr = (cAttr & 0x70) | (cAttr >> 4);
        } else {
          cAttr = new_text[1];
        }
        gfxchar = tm_info.line_graphics && ((cChar & 0xE0) == 0xC0);
        xc = x * font_width;
        DrawChar(xc, yc, font_width, font_height, 0, (char *)&vga_charmap[cChar<<5], cAttr, gfxchar);
        if(yc < rfbUpdateRegion.y) rfbUpdateRegion.y = yc;
        if((yc + font_height - rfbUpdateRegion.y) > rfbUpdateRegion.height) rfbUpdateRegion.height = (yc + font_height - rfbUpdateRegion.y);
        if(xc < rfbUpdateRegion.x) rfbUpdateRegion.x = xc;
        if((xc + font_width - rfbUpdateRegion.x) > rfbUpdateRegion.width) rfbUpdateRegion.width = (xc + font_width - rfbUpdateRegion.x);
        rfbUpdateRegion.updated = true;
        if (offset == curs) {
          cAttr = ((cAttr >> 4) & 0xF) + ((cAttr & 0xF) << 4);
          DrawChar(xc, yc + tm_info.cs_start, font_width, tm_info.cs_end - tm_info.cs_start + 1,
                   tm_info.cs_start, (char *)&vga_charmap[cChar<<5], cAttr, gfxchar);
        }
      }
      x++;
      new_text+=2;
      old_text+=2;
      offset+=2;
    } while (--hchars);
    y++;
    new_text = new_line + tm_info.line_offset;
    old_text = old_line + tm_info.line_offset;
  } while (--rows);

  rfbCursorX = cursor_x;
  rfbCursorY = cursor_y;
}

int bx_rfb_gui_c::get_clipboard_text(Bit8u **bytes, Bit32s *nbytes)
{
  return 0;
}

int bx_rfb_gui_c::set_clipboard_text(char *text_snapshot, Bit32u len)
{
  return 0;
}

// ::PALETTE_CHANGE()
//
// Allocate a color in the native GUI, for this color, and put
// it in the colormap location 'index'.
// returns: 0=no screen update needed (color map change has direct effect)
//          1=screen updated needed (redraw using current colormap)

bx_bool bx_rfb_gui_c::palette_change(unsigned index, unsigned red, unsigned green, unsigned blue)
{
    rfbPalette[index] = (((red * 7 + 127) / 255) << 0) | (((green * 7 + 127) / 255) << 3) | (((blue * 3 + 127) / 255) << 6);
    return(1);
}

// ::GRAPHICS_TILE_UPDATE()
//
// Called to request that a tile of graphics be drawn to the
// screen, since info in this region has changed.
//
// tile: array of 8bit values representing a block of pixels with
//       dimension equal to the 'tilewidth' & 'tileheight' parameters to
//       ::specific_init().  Each value specifies an index into the
//       array of colors you allocated for ::palette_change()
// x0: x origin of tile
// y0: y origin of tile
//
// note: origin of tile and of window based on (0,0) being in the upper
//       left of the window.
void bx_rfb_gui_c::graphics_tile_update(Bit8u *tile, unsigned x0, unsigned y0)
{
    UpdateScreen(tile, x0, y0 + rfbHeaderbarY, rfbTileX, rfbTileY, false);
    if(x0 < rfbUpdateRegion.x) rfbUpdateRegion.x = x0;
    if((y0 + rfbHeaderbarY) < rfbUpdateRegion.y) rfbUpdateRegion.y = y0 + rfbHeaderbarY;
    if(((y0 + rfbHeaderbarY + rfbTileY) - rfbUpdateRegion.y) > rfbUpdateRegion.height) rfbUpdateRegion.height =  ((y0 + rfbHeaderbarY + rfbTileY) - rfbUpdateRegion.y);
    if(((x0 + rfbTileX) - rfbUpdateRegion.x) > rfbUpdateRegion.width) rfbUpdateRegion.width = ((x0 + rfbTileX) - rfbUpdateRegion.x);
    rfbUpdateRegion.updated = true;
}

bx_svga_tileinfo_t *bx_rfb_gui_c::graphics_tile_info(bx_svga_tileinfo_t *info)
{
  if (!info) {
    info = (bx_svga_tileinfo_t *)malloc(sizeof(bx_svga_tileinfo_t));
    if (!info) {
      return NULL;
    }
  }

  info->bpp = 8;
  info->pitch = rfbWindowX;
  info->red_shift = 3;
  info->green_shift = 6;
  info->blue_shift = 8;
  info->red_mask = 0x07;
  info->green_mask = 0x38;
  info->blue_mask = 0xc0;
  info->is_indexed = 0;
  info->is_little_endian = 1;

  return info;
}

Bit8u *bx_rfb_gui_c::graphics_tile_get(unsigned x0, unsigned y0,
                            unsigned *w, unsigned *h)
{
  if (x0+rfbTileX > rfbDimensionX) {
    *w = rfbDimensionX - x0;
  }
  else {
    *w = rfbTileX;
  }

  if (y0+rfbTileY > rfbDimensionY) {
    *h = rfbDimensionY - y0;
  }
  else {
    *h = rfbTileY;
  }

  return (Bit8u *)rfbScreen + (rfbHeaderbarY + y0) * rfbWindowX + x0;
}

void bx_rfb_gui_c::graphics_tile_update_in_place(unsigned x0, unsigned y0,
                                        unsigned w, unsigned h)
{
  if(x0 < rfbUpdateRegion.x) rfbUpdateRegion.x = x0;
  if((y0 + rfbHeaderbarY) < rfbUpdateRegion.y) rfbUpdateRegion.y = y0 + rfbHeaderbarY;
  if(((y0 + rfbHeaderbarY + h) - rfbUpdateRegion.y) > rfbUpdateRegion.height) rfbUpdateRegion.height =  ((y0 + rfbHeaderbarY + h) - rfbUpdateRegion.y);
  if(((x0 + w) - rfbUpdateRegion.x) > rfbUpdateRegion.width) rfbUpdateRegion.width = ((x0 + h) - rfbUpdateRegion.x);
  rfbUpdateRegion.updated = true;
}


// ::DIMENSION_UPDATE()
//
// Called when the VGA mode changes it's X,Y dimensions.
// Resize the window to this size, but you need to add on
// the height of the headerbar to the Y value.
//
// x: new VGA x size
// y: new VGA y size (add headerbar_y parameter from ::specific_init().
// fheight: new VGA character height in text mode
// fwidth : new VGA character width in text mode
// bpp : bits per pixel in graphics mode

void bx_rfb_gui_c::dimension_update(unsigned x, unsigned y, unsigned fheight, unsigned fwidth, unsigned bpp)
{
  if (bpp > 8) {
    BX_PANIC(("%d bpp graphics mode not supported yet", bpp));
  }
  if (fheight > 0) {
    font_height = fheight;
    font_width = fwidth;
    text_cols = x / fwidth;
    text_rows = y / fheight;
  }
  if ((x > BX_RFB_MAX_XDIM) || (y > BX_RFB_MAX_YDIM)) {
    BX_PANIC(("dimension_update(): RFB doesn't support graphics mode %dx%d", x, y));
  } else if ((x != rfbDimensionX) || (x != rfbDimensionY)) {
    clear_screen();
    SendUpdate(0, rfbHeaderbarY, rfbDimensionX, rfbDimensionY);
    rfbDimensionX = x;
    rfbDimensionY = y;
  }
}


// ::CREATE_BITMAP()
//
// Create a monochrome bitmap of size 'xdim' by 'ydim', which will
// be drawn in the headerbar.  Return an integer ID to the bitmap,
// with which the bitmap can be referenced later.
//
// bmap: packed 8 pixels-per-byte bitmap.  The pixel order is:
//       bit0 is the left most pixel, bit7 is the right most pixel.
// xdim: x dimension of bitmap
// ydim: y dimension of bitmap

unsigned bx_rfb_gui_c::create_bitmap(const unsigned char *bmap, unsigned xdim, unsigned ydim)
{
    if(rfbBitmapCount >= BX_MAX_PIXMAPS) {
        BX_ERROR(("too many pixmaps."));
        return 0;
    }
    rfbBitmaps[rfbBitmapCount].bmap = (char *)malloc((xdim * ydim) / 8);
    rfbBitmaps[rfbBitmapCount].xdim = xdim;
    rfbBitmaps[rfbBitmapCount].ydim = ydim;
    memcpy(rfbBitmaps[rfbBitmapCount].bmap, bmap, (xdim * ydim) / 8);

    rfbBitmapCount++;
    return(rfbBitmapCount - 1);
}


// ::HEADERBAR_BITMAP()
//
// Called to install a bitmap in the bochs headerbar (toolbar).
//
// bmap_id: will correspond to an ID returned from
//     ::create_bitmap().  'alignment' is either BX_GRAVITY_LEFT
//     or BX_GRAVITY_RIGHT, meaning install the bitmap in the next
//     available leftmost or rightmost space.
// alignment: is either BX_GRAVITY_LEFT or BX_GRAVITY_RIGHT,
//     meaning install the bitmap in the next
//     available leftmost or rightmost space.
// f: a 'C' function pointer to callback when the mouse is clicked in
//     the boundaries of this bitmap.

unsigned bx_rfb_gui_c::headerbar_bitmap(unsigned bmap_id, unsigned alignment, void (*f)(void))
{
    int hb_index;

    if((rfbHeaderbarBitmapCount + 1) > BX_MAX_HEADERBAR_ENTRIES) {
        return 0;
    }

    rfbHeaderbarBitmapCount++;
    hb_index = rfbHeaderbarBitmapCount - 1;
    rfbHeaderbarBitmaps[hb_index].index     = bmap_id;
    rfbHeaderbarBitmaps[hb_index].alignment = alignment;
    rfbHeaderbarBitmaps[hb_index].f = f;
    if (alignment == BX_GRAVITY_LEFT) {
        rfbHeaderbarBitmaps[hb_index].xorigin = rfbOriginLeft;
        rfbHeaderbarBitmaps[hb_index].yorigin = 0;
        rfbOriginLeft += rfbBitmaps[bmap_id].xdim;
    } else { // BX_GRAVITY_RIGHT
        rfbOriginRight += rfbBitmaps[bmap_id].xdim;
        rfbHeaderbarBitmaps[hb_index].xorigin = rfbOriginRight;
        rfbHeaderbarBitmaps[hb_index].yorigin = 0;
    }
    return hb_index;
}


// ::SHOW_HEADERBAR()
//
// Show (redraw) the current headerbar, which is composed of
// currently installed bitmaps.

void bx_rfb_gui_c::show_headerbar(void)
{
  char *newBits, value;
  unsigned int i, xorigin, addr;

  newBits = (char *)malloc(rfbWindowX * rfbHeaderbarY);
  memset(newBits, 0, (rfbWindowX * rfbHeaderbarY));
  DrawBitmap(0, 0, rfbWindowX, rfbHeaderbarY, newBits, (char)0xf0, false);
  for(i = 0; i < rfbHeaderbarBitmapCount; i++) {
    if(rfbHeaderbarBitmaps[i].alignment == BX_GRAVITY_LEFT) {
      xorigin = rfbHeaderbarBitmaps[i].xorigin;
    } else {
      xorigin = rfbWindowX - rfbHeaderbarBitmaps[i].xorigin;
    }
    DrawBitmap(xorigin, 0, rfbBitmaps[rfbHeaderbarBitmaps[i].index].xdim, rfbBitmaps[rfbHeaderbarBitmaps[i].index].ydim, rfbBitmaps[rfbHeaderbarBitmaps[i].index].bmap, (char)0xf0, false);
  }
  free(newBits);
  newBits = (char *)malloc(rfbWindowX * rfbStatusbarY / 8);
  memset(newBits, 0, (rfbWindowX * rfbStatusbarY / 8));
  for (i = 1; i < 12; i++) {
    addr = rfbStatusitemPos[i] / 8;
    value = 1 << (rfbStatusitemPos[i] % 8);
    for (unsigned j=1; j<rfbStatusbarY; j++) {
      newBits[(rfbWindowX * j / 8) + addr] = value;
    }
  }
  DrawBitmap(0, rfbWindowY - rfbStatusbarY, rfbWindowX, rfbStatusbarY, newBits, (char)0xf0, false);
  free(newBits);
  for (i = 1; i <= statusitem_count; i++) {
    rfbSetStatusText(i, statusitem_text[i-1], rfbStatusitemActive[i]);
  }
}


// ::REPLACE_BITMAP()
//
// Replace the bitmap installed in the headerbar ID slot 'hbar_id',
// with the one specified by 'bmap_id'.  'bmap_id' will have
// been generated by ::create_bitmap().  The old and new bitmap
// must be of the same size.  This allows the bitmap the user
// sees to change, when some action occurs.  For example when
// the user presses on the floppy icon, it then displays
// the ejected status.
//
// hbar_id: headerbar slot ID
// bmap_id: bitmap ID

void bx_rfb_gui_c::replace_bitmap(unsigned hbar_id, unsigned bmap_id)
{
    unsigned int xorigin;

    if (bmap_id == rfbHeaderbarBitmaps[hbar_id].index) return;
    rfbHeaderbarBitmaps[hbar_id].index = bmap_id;
    if (rfbHeaderbarBitmaps[hbar_id].alignment == BX_GRAVITY_LEFT) {
      xorigin = rfbHeaderbarBitmaps[hbar_id].xorigin;
    } else {
      xorigin = rfbWindowX - rfbHeaderbarBitmaps[hbar_id].xorigin;
    }
    DrawBitmap(xorigin, 0, rfbBitmaps[rfbHeaderbarBitmaps[hbar_id].index].xdim,
               rfbBitmaps[rfbHeaderbarBitmaps[hbar_id].index].ydim,
               rfbBitmaps[rfbHeaderbarBitmaps[hbar_id].index].bmap, (char)0xf0, true);
}


// ::EXIT()
//
// Called before bochs terminates, to allow for a graceful
// exit from the native GUI mechanism.
void bx_rfb_gui_c::exit(void)
{
    unsigned int i;
    keep_alive = false;
#ifdef WIN32
    StopWinsock();
#endif
    free(rfbScreen);
    for(i = 0; i < rfbBitmapCount; i++) {
        free(rfbBitmaps[i].bmap);
    }

    // Clear supported encodings
    if (clientEncodings != NULL) {
        delete [] clientEncodings;
        clientEncodingsCount = 0;
    }

    BX_DEBUG(("bx_rfb_gui_c::exit()"));
}

/*
* ReadExact reads an exact number of bytes on a TCP socket.  Returns 1 if
* those bytes have been read, 0 if the other end has closed, or -1 if an error
* occurred (errno is set to ETIMEDOUT if it timed out).
*/

int ReadExact(int sock, char *buf, int len)
{
    int n;

    while (len > 0) {
    n = recv(sock, buf, len, 0);
    if (n > 0) {
        buf += n;
        len -= n;
        } else {
            return n;
    }
    }
    return 1;
}

/*
* WriteExact writes an exact number of bytes on a TCP socket.  Returns 1 if
* those bytes have been written, or -1 if an error occurred (errno is set to
* ETIMEDOUT if it timed out).
*/

int WriteExact(int sock, char *buf, int len)
{
    int n;

    while (len > 0) {
    n = send(sock, buf, len,0);

    if (n > 0) {
        buf += n;
        len -= n;
    } else if (n == 0) {
            BX_ERROR(("WriteExact: write returned 0?"));
            return n;
        } else {
            return n;
        }
    }
    return 1;
}

void DrawBitmap(int x, int y, int width, int height, char *bmap, char color, bool update_client)
{
    int  i;
    unsigned char *newBits;
    char fgcolor, bgcolor;
    char vgaPalette[] = {(char)0x00, //Black
                         (char)0x01, //Dark Blue
                         (char)0x02, //Dark Green
                         (char)0x03, //Dark Cyan
                         (char)0x04, //Dark Red
                         (char)0x05, //Dark Magenta
                         (char)0x06, //Brown
                         (char)0x07, //Light Gray
                         (char)0x38, //Dark Gray
                         (char)0x09, //Light Blue
                         (char)0x12, //Green
                         (char)0x1B, //Cyan
                         (char)0x24, //Light Red
                         (char)0x2D, //Magenta
                         (char)0x36, //Yellow
                         (char)0x3F  //White
                        };

    bgcolor = vgaPalette[(color >> 4) & 0xF];
    fgcolor = vgaPalette[color & 0xF];
    newBits = (unsigned char *)malloc(width * height);
    memset(newBits, 0, (width * height));
    for(i = 0; i < (width * height) / 8; i++) {
        newBits[i * 8 + 0] = (bmap[i] & 0x01) ? fgcolor : bgcolor;
        newBits[i * 8 + 1] = (bmap[i] & 0x02) ? fgcolor : bgcolor;
        newBits[i * 8 + 2] = (bmap[i] & 0x04) ? fgcolor : bgcolor;
        newBits[i * 8 + 3] = (bmap[i] & 0x08) ? fgcolor : bgcolor;
        newBits[i * 8 + 4] = (bmap[i] & 0x10) ? fgcolor : bgcolor;
        newBits[i * 8 + 5] = (bmap[i] & 0x20) ? fgcolor : bgcolor;
        newBits[i * 8 + 6] = (bmap[i] & 0x40) ? fgcolor : bgcolor;
        newBits[i * 8 + 7] = (bmap[i] & 0x80) ? fgcolor : bgcolor;
    }
    UpdateScreen(newBits, x, y, width, height, update_client);
    //DrawColorPalette();
    free(newBits);
}

void DrawChar(int x, int y, int width, int height, int fonty, char *bmap, char color, bx_bool gfxchar)
{
  static unsigned char newBits[9 * 32];
  unsigned char mask;
  int bytes = width * height;
  char fgcolor, bgcolor;
  char vgaPalette[] = {(char)0x00, //Black
                       (char)0x01, //Dark Blue
                       (char)0x02, //Dark Green
                       (char)0x03, //Dark Cyan
                       (char)0x04, //Dark Red
                       (char)0x05, //Dark Magenta
                       (char)0x06, //Brown
                       (char)0x07, //Light Gray
                       (char)0x38, //Dark Gray
                       (char)0x09, //Light Blue
                       (char)0x12, //Green
                       (char)0x1B, //Cyan
                       (char)0x24, //Light Red
                       (char)0x2D, //Magenta
                       (char)0x36, //Yellow
                       (char)0x3F  //White
                     };

  bgcolor = vgaPalette[(color >> 4) & 0xF];
  fgcolor = vgaPalette[color & 0xF];

  for(int i = 0; i < bytes; i+=width) {
    mask = 0x80;
    for(int j = 0; j < width; j++) {
      if (mask > 0) {
        newBits[i + j] = (bmap[fonty] & mask) ? fgcolor : bgcolor;
      } else {
        if (gfxchar) {
          newBits[i + j] = (bmap[fonty] & 0x01) ? fgcolor : bgcolor;
        } else {
          newBits[i + j] = bgcolor;
        }
      }
      mask >>= 1;
    }
    fonty++;
  }
  UpdateScreen(newBits, x, y, width, height, false);
  //DrawColorPalette();
}

void DrawColorPalette()
{
    unsigned char bits[100];
    int x = 0, y = 0, c;
    for(c = 0; c < 256; c++) {
        memset(&bits, rfbPalette[c], 100);
        UpdateScreen(bits, x, y, 10, 10, false);
        x += 10;
        if(x > 70) {
            y += 10;
            x = 0;
        }
    }
}

void UpdateScreen(unsigned char *newBits, int x, int y, int width, int height, bool update_client)
{
    int i, c;
    for(i = 0; i < height; i++) {
        for(c = 0; c < width; c++) {
            newBits[(i * width) + c] = rfbPalette[newBits[(i * width) + c]];
        }
        memcpy(&rfbScreen[y * rfbWindowX + x], &newBits[i * width], width);
        y++;
    }
    if(update_client) {
        if(sGlobal == INVALID_SOCKET) return;
        rfbFramebufferUpdateMessage fum;
        rfbFramebufferUpdateRectHeader furh;
        fum.messageType = rfbFramebufferUpdate;
        fum.numberOfRectangles = htons(1);
        WriteExact(sGlobal, (char *)&fum, rfbFramebufferUpdateMessageSize);
        furh.r.xPosition = htons(x);
        furh.r.yPosition = htons((y - i));
        furh.r.width = htons((short)width);
        furh.r.height = htons((short)height);
        furh.r.encodingType = htonl(rfbEncodingRaw);
        WriteExact(sGlobal, (char *)&furh, rfbFramebufferUpdateRectHeaderSize);
        WriteExact(sGlobal, (char *)newBits, width * height);
    }
}

void SendUpdate(int x, int y, int width, int height)
{
    char *newBits;
    int  i;

    if(x < 0 || y < 0 || (x + width) > (int)rfbWindowX || (y + height) > (int)rfbWindowY) {
        BX_ERROR(("Dimensions out of bounds.  x=%i y=%i w=%i h=%i", x, y, width, height));
    }
    if(sGlobal != INVALID_SOCKET) {
        rfbFramebufferUpdateMessage fum;
        rfbFramebufferUpdateRectHeader furh;

        fum.messageType = rfbFramebufferUpdate;
        fum.numberOfRectangles = htons(1);

        furh.r.xPosition = htons(x);
        furh.r.yPosition = htons(y);
        furh.r.width = htons((short)width);
        furh.r.height = htons((short)height);
        furh.r.encodingType = htonl(rfbEncodingRaw);

        newBits = (char *)malloc(width * height);
        for(i = 0; i < height; i++) {
            memcpy(&newBits[i * width], &rfbScreen[y * rfbWindowX + x], width);
            y++;
        }

        WriteExact(sGlobal, (char *)&fum, rfbFramebufferUpdateMessageSize);
        WriteExact(sGlobal, (char *)&furh, rfbFramebufferUpdateRectHeaderSize);
        WriteExact(sGlobal, (char *)newBits, width * height);

        free(newBits);
    }
}

void StartThread()
{
#ifdef WIN32
    _beginthread(ServerThreadInit, 0, NULL);
#else
    pthread_t      thread;
    pthread_create(&thread, NULL, (void *(*)(void *))&ServerThreadInit, NULL);
#endif
}

/***********************/
/* Keyboard Definitons */
/*        And          */
/*     Functions       */
/***********************/

#define XK_space            0x020
#define XK_asciitilde       0x07e

#define XK_dead_grave       0xFE50
#define XK_dead_acute       0xFE51
#define XK_dead_circumflex  0xFE52
#define XK_dead_tilde       0xFE53

#define XK_BackSpace        0xFF08
#define XK_Tab              0xFF09
#define XK_Linefeed         0xFF0A
#define XK_Clear            0xFF0B
#define XK_Return           0xFF0D
#define XK_Pause            0xFF13
#define XK_Scroll_Lock      0xFF14
#define XK_Sys_Req          0xFF15
#define XK_Escape           0xFF1B

#define XK_Delete           0xFFFF

#define XK_Home             0xFF50
#define XK_Left             0xFF51
#define XK_Up               0xFF52
#define XK_Right            0xFF53
#define XK_Down             0xFF54
#define XK_Page_Up          0xFF55
#define XK_Page_Down        0xFF56
#define XK_End              0xFF57
#define XK_Begin            0xFF58

#define XK_Select           0xFF60
#define XK_Print            0xFF61
#define XK_Execute          0xFF62
#define XK_Insert           0xFF63

#define XK_Cancel           0xFF69
#define XK_Help             0xFF6A
#define XK_Break            0xFF6B
#define XK_Num_Lock         0xFF7F

#define XK_KP_Space         0xFF80
#define XK_KP_Tab           0xFF89
#define XK_KP_Enter         0xFF8D

#define XK_KP_Home          0xFF95
#define XK_KP_Left          0xFF96
#define XK_KP_Up            0xFF97
#define XK_KP_Right         0xFF98
#define XK_KP_Down          0xFF99
#define XK_KP_Prior         0xFF9A
#define XK_KP_Page_Up       0xFF9A
#define XK_KP_Next          0xFF9B
#define XK_KP_Page_Down     0xFF9B
#define XK_KP_End           0xFF9C
#define XK_KP_Begin         0xFF9D
#define XK_KP_Insert        0xFF9E
#define XK_KP_Delete        0xFF9F
#define XK_KP_Equal         0xFFBD
#define XK_KP_Multiply      0xFFAA
#define XK_KP_Add           0xFFAB
#define XK_KP_Separator     0xFFAC
#define XK_KP_Subtract      0xFFAD
#define XK_KP_Decimal       0xFFAE
#define XK_KP_Divide        0xFFAF

#define XK_KP_F1            0xFF91
#define XK_KP_F2            0xFF92
#define XK_KP_F3            0xFF93
#define XK_KP_F4            0xFF94

#define XK_KP_0             0xFFB0
#define XK_KP_1             0xFFB1
#define XK_KP_2             0xFFB2
#define XK_KP_3             0xFFB3
#define XK_KP_4             0xFFB4
#define XK_KP_5             0xFFB5
#define XK_KP_6             0xFFB6
#define XK_KP_7             0xFFB7
#define XK_KP_8             0xFFB8
#define XK_KP_9             0xFFB9

#define XK_F1               0xFFBE
#define XK_F2               0xFFBF
#define XK_F3               0xFFC0
#define XK_F4               0xFFC1
#define XK_F5               0xFFC2
#define XK_F6               0xFFC3
#define XK_F7               0xFFC4
#define XK_F8               0xFFC5
#define XK_F9               0xFFC6
#define XK_F10              0xFFC7
#define XK_F11              0xFFC8
#define XK_F12              0xFFC9
#define XK_F13              0xFFCA
#define XK_F14              0xFFCB
#define XK_F15              0xFFCC
#define XK_F16              0xFFCD
#define XK_F17              0xFFCE
#define XK_F18              0xFFCF
#define XK_F19              0xFFD0
#define XK_F20              0xFFD1
#define XK_F21              0xFFD2
#define XK_F22              0xFFD3
#define XK_F23              0xFFD4
#define XK_F24              0xFFD5


#define XK_Shift_L          0xFFE1
#define XK_Shift_R          0xFFE2
#define XK_Control_L        0xFFE3
#define XK_Control_R        0xFFE4
#define XK_Caps_Lock        0xFFE5
#define XK_Shift_Lock       0xFFE6
#define XK_Meta_L           0xFFE7
#define XK_Meta_R           0xFFE8
#define XK_Alt_L            0xFFE9
#define XK_Alt_R            0xFFEA

Bit32u rfb_ascii_to_key_event[0x5f] = {
  //  !"#$%&'
  BX_KEY_SPACE,
  BX_KEY_1,
  BX_KEY_SINGLE_QUOTE,
  BX_KEY_3,
  BX_KEY_4,
  BX_KEY_5,
  BX_KEY_7,
  BX_KEY_SINGLE_QUOTE,

  // ()*+,-./
  BX_KEY_9,
  BX_KEY_0,
  BX_KEY_8,
  BX_KEY_EQUALS,
  BX_KEY_COMMA,
  BX_KEY_MINUS,
  BX_KEY_PERIOD,
  BX_KEY_SLASH,

  // 01234567
  BX_KEY_0,
  BX_KEY_1,
  BX_KEY_2,
  BX_KEY_3,
  BX_KEY_4,
  BX_KEY_5,
  BX_KEY_6,
  BX_KEY_7,

  // 89:;<=>?
  BX_KEY_8,
  BX_KEY_9,
  BX_KEY_SEMICOLON,
  BX_KEY_SEMICOLON,
  BX_KEY_COMMA,
  BX_KEY_EQUALS,
  BX_KEY_PERIOD,
  BX_KEY_SLASH,

  // @ABCDEFG
  BX_KEY_2,
  BX_KEY_A,
  BX_KEY_B,
  BX_KEY_C,
  BX_KEY_D,
  BX_KEY_E,
  BX_KEY_F,
  BX_KEY_G,


  // HIJKLMNO
  BX_KEY_H,
  BX_KEY_I,
  BX_KEY_J,
  BX_KEY_K,
  BX_KEY_L,
  BX_KEY_M,
  BX_KEY_N,
  BX_KEY_O,


  // PQRSTUVW
  BX_KEY_P,
  BX_KEY_Q,
  BX_KEY_R,
  BX_KEY_S,
  BX_KEY_T,
  BX_KEY_U,
  BX_KEY_V,
  BX_KEY_W,

  // XYZ[\]^_
  BX_KEY_X,
  BX_KEY_Y,
  BX_KEY_Z,
  BX_KEY_LEFT_BRACKET,
  BX_KEY_BACKSLASH,
  BX_KEY_RIGHT_BRACKET,
  BX_KEY_6,
  BX_KEY_MINUS,

  // `abcdefg
  BX_KEY_GRAVE,
  BX_KEY_A,
  BX_KEY_B,
  BX_KEY_C,
  BX_KEY_D,
  BX_KEY_E,
  BX_KEY_F,
  BX_KEY_G,

  // hijklmno
  BX_KEY_H,
  BX_KEY_I,
  BX_KEY_J,
  BX_KEY_K,
  BX_KEY_L,
  BX_KEY_M,
  BX_KEY_N,
  BX_KEY_O,

  // pqrstuvw
  BX_KEY_P,
  BX_KEY_Q,
  BX_KEY_R,
  BX_KEY_S,
  BX_KEY_T,
  BX_KEY_U,
  BX_KEY_V,
  BX_KEY_W,

  // xyz{|}~
  BX_KEY_X,
  BX_KEY_Y,
  BX_KEY_Z,
  BX_KEY_LEFT_BRACKET,
  BX_KEY_BACKSLASH,
  BX_KEY_RIGHT_BRACKET,
  BX_KEY_GRAVE
  };

void rfbKeyPressed(Bit32u key, int press_release)
{
  Bit32u key_event;

  if((key >= XK_space) && (key <= XK_asciitilde)) {
    key_event = rfb_ascii_to_key_event[key - XK_space];
  } else {
    switch (key) {
      case XK_KP_1:
#ifdef XK_KP_End
      case XK_KP_End:
#endif
        key_event = BX_KEY_KP_END; break;

      case XK_KP_2:
#ifdef XK_KP_Down
      case XK_KP_Down:
#endif
        key_event = BX_KEY_KP_DOWN; break;

      case XK_KP_3:
#ifdef XK_KP_Page_Down
      case XK_KP_Page_Down:
#endif
        key_event = BX_KEY_KP_PAGE_DOWN; break;

      case XK_KP_4:
#ifdef XK_KP_Left
      case XK_KP_Left:
#endif
        key_event = BX_KEY_KP_LEFT; break;

      case XK_KP_5:
#ifdef XK_KP_Begin
      case XK_KP_Begin:
#endif
        key_event = BX_KEY_KP_5; break;

      case XK_KP_6:
#ifdef XK_KP_Right
      case XK_KP_Right:
#endif
        key_event = BX_KEY_KP_RIGHT; break;

      case XK_KP_7:
#ifdef XK_KP_Home
      case XK_KP_Home:
#endif
        key_event = BX_KEY_KP_HOME; break;

      case XK_KP_8:
#ifdef XK_KP_Up
      case XK_KP_Up:
#endif
        key_event = BX_KEY_KP_UP; break;

      case XK_KP_9:
#ifdef XK_KP_Page_Up
      case XK_KP_Page_Up:
#endif
        key_event = BX_KEY_KP_PAGE_UP; break;

      case XK_KP_0:
#ifdef XK_KP_Insert
      case XK_KP_Insert:
#endif
        key_event = BX_KEY_KP_INSERT; break;

      case XK_KP_Decimal:
#ifdef XK_KP_Delete
      case XK_KP_Delete:
#endif
        key_event = BX_KEY_KP_DELETE; break;

#ifdef XK_KP_Enter
      case XK_KP_Enter:    key_event = BX_KEY_KP_ENTER; break;
#endif

      case XK_KP_Subtract: key_event = BX_KEY_KP_SUBTRACT; break;
      case XK_KP_Add:      key_event = BX_KEY_KP_ADD; break;

      case XK_KP_Multiply: key_event = BX_KEY_KP_MULTIPLY; break;
      case XK_KP_Divide:   key_event = BX_KEY_KP_DIVIDE; break;


      case XK_Up:          key_event = BX_KEY_UP; break;
      case XK_Down:        key_event = BX_KEY_DOWN; break;
      case XK_Left:        key_event = BX_KEY_LEFT; break;
      case XK_Right:       key_event = BX_KEY_RIGHT; break;


      case XK_Delete:      key_event = BX_KEY_DELETE; break;
      case XK_BackSpace:   key_event = BX_KEY_BACKSPACE; break;
      case XK_Tab:         key_event = BX_KEY_TAB; break;
#ifdef XK_ISO_Left_Tab
      case XK_ISO_Left_Tab: key_event = BX_KEY_TAB; break;
#endif
      case XK_Return:      key_event = BX_KEY_ENTER; break;
      case XK_Escape:      key_event = BX_KEY_ESC; break;
      case XK_F1:          key_event = BX_KEY_F1; break;
      case XK_F2:          key_event = BX_KEY_F2; break;
      case XK_F3:          key_event = BX_KEY_F3; break;
      case XK_F4:          key_event = BX_KEY_F4; break;
      case XK_F5:          key_event = BX_KEY_F5; break;
      case XK_F6:          key_event = BX_KEY_F6; break;
      case XK_F7:          key_event = BX_KEY_F7; break;
      case XK_F8:          key_event = BX_KEY_F8; break;
      case XK_F9:          key_event = BX_KEY_F9; break;
      case XK_F10:         key_event = BX_KEY_F10; break;
      case XK_F11:         key_event = BX_KEY_F11; break;
      case XK_F12:         key_event = BX_KEY_F12; break;
      case XK_Control_L:   key_event = BX_KEY_CTRL_L; break;
#ifdef XK_Control_R
      case XK_Control_R:   key_event = BX_KEY_CTRL_R; break;
#endif
      case XK_Shift_L:     key_event = BX_KEY_SHIFT_L; break;
      case XK_Shift_R:     key_event = BX_KEY_SHIFT_R; break;
      case XK_Alt_L:       key_event = BX_KEY_ALT_L; break;
#ifdef XK_Alt_R
      case XK_Alt_R:       key_event = BX_KEY_ALT_R; break;
#endif
      case XK_Caps_Lock:   key_event = BX_KEY_CAPS_LOCK; break;
      case XK_Num_Lock:    key_event = BX_KEY_NUM_LOCK; break;
#ifdef XK_Scroll_Lock
      case XK_Scroll_Lock: key_event = BX_KEY_SCRL_LOCK; break;
#endif
#ifdef XK_Print
      case XK_Print:       key_event = BX_KEY_PRINT; break;
#endif
#ifdef XK_Pause
      case XK_Pause:       key_event = BX_KEY_PAUSE; break;
#endif

      case XK_Insert:      key_event = BX_KEY_INSERT; break;
      case XK_Home:        key_event = BX_KEY_HOME; break;
      case XK_End:         key_event = BX_KEY_END; break;
      case XK_Page_Up:     key_event = BX_KEY_PAGE_UP; break;
      case XK_Page_Down:   key_event = BX_KEY_PAGE_DOWN; break;

      default:
        BX_ERROR(("rfbKeyPress(): key %04x unhandled!", key));
        return;
        break;
    }
  }

  if (!press_release) key_event |= BX_KEY_RELEASED;
  DEV_kbd_gen_scancode(key_event);
}

void rfbMouseMove(int x, int y, int bmask)
{
  static int oldx = -1;
  static int oldy = -1;
  int xorigin;

  if ((oldx == 1) && (oldy == -1)) {
    oldx = x;
    oldy = y;
    return;
  }
  if(y > rfbHeaderbarY) {
    DEV_mouse_motion(x - oldx, oldy - y, bmask);
    oldx = x;
    oldy = y;
  } else {
    if (bmask == 1) {
      for (unsigned i=0; i<rfbHeaderbarBitmapCount; i++) {
        if (rfbHeaderbarBitmaps[i].alignment == BX_GRAVITY_LEFT)
          xorigin = rfbHeaderbarBitmaps[i].xorigin;
        else
          xorigin = rfbWindowX - rfbHeaderbarBitmaps[i].xorigin;
        if ((x>=xorigin) && (x<(xorigin+int(rfbBitmaps[rfbHeaderbarBitmaps[i].index].xdim)))) {
          rfbHeaderbarBitmaps[i].f();
          return;
        }
      }
    }
  }
}

void bx_rfb_gui_c::mouse_enabled_changed_specific (bx_bool val)
{
}

void bx_rfb_gui_c::get_capabilities(Bit16u *xres, Bit16u *yres, Bit16u *bpp)
{
  *xres = BX_RFB_MAX_XDIM;
  *yres = BX_RFB_MAX_YDIM;
  *bpp = 8;
}

#if BX_SHOW_IPS
void bx_rfb_gui_c::show_ips(Bit32u ips_count)
{
  char ips_text[40];
  sprintf(ips_text, "IPS: %9u", ips_count);
  rfbSetStatusText(0, ips_text, 1);
}
#endif

#endif /* if BX_WITH_RFB */
