/* sqUnixEvdevKeycodeMap.c 
 *
 * Map (lib)evdev key codes into Squeak key codes
 * Author: Ken.Dickey@whidbey.com
 *
 * Copyright (C) 2019,2020 by Kenneth Alan Dickey
 * All Rights Reserved.
 * 
 * [Donated to the Squeak/Cuis/Pharo Community]
 *
 * This file is part of the OpenSmalltalk / Unix Squeak VM.
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

/* input.h defines libevdev key codes which get 
 *  mapped to keysum (X11) codes or ASCII.
 * @@ Elided X11 keycodes based on vm-dev-X11/sqUnixX11.c @@
 *
 * Based on emperical testing w logitech USB keyboard & mouse 
 * on Raspberry Pi 3B running Alpine Linux.
 */

#include <linux/input.h>   /* /usr/include/linux/input.h */
/* #include <X11/keysym.h>  * /usr/include/X11/keysym.h */

static int keyMapInitialized = 0;
#define KMAPSIZE 256
static int baseKey[KMAPSIZE], shiftKey[KMAPSIZE];

/* arrow, prior, next, home, end, BS, delete, insert, Escape, Tab */

void initKeyMaps() {
int i;
	
  if (keyMapInitialized) return; /* do this once */
 
  for (i = 0; i < KMAPSIZE; i++) {
	baseKey[i]  = KEY_RESERVED;  /* NB: default is ignored */
	shiftKey[i] = KEY_RESERVED;
  }
   /* Note: add 0x40 to keys less than 0x30 to get ctrl letter
    * e.g. FF = 0x0C; so 0x4C = L => '^L' (Ctrl-L) for Form Feed
    *
    * Note: ASCII for Control Chars; add 0xFF00 for keysym defs
    * e.g. 0x08 [BS] + 0xFF00 -> 0xFF08 = XK_BackSpace
    */ 
    baseKey[KEY_RESERVED]  = 0x00; /* NUL = ^@ */
    shiftKey[KEY_RESERVED] = 0x00;
    baseKey[KEY_ESC]    = 0x1B; /* ESC: ESCape */
    shiftKey[KEY_ESC]   = 0x1B;
    baseKey[KEY_1]      = 0x31; /* '1' */
    shiftKey[KEY_1]     = 0x21; /* '!' */
    baseKey[KEY_2]      = 0x32; /* '2' */
    shiftKey[KEY_2]     = 0x40; /* '@' */
    baseKey[KEY_3]      = 0x33; /* '3' */
    shiftKey[KEY_3]     = 0x23; /* '#' */
    baseKey[KEY_4]      = 0x34; /* '4' */
    shiftKey[KEY_4]     = 0x24; /* '$' */
    baseKey[KEY_5]      = 0x35; /* '5' */
    shiftKey[KEY_5]     = 0x25; /* '%' */
    baseKey[KEY_6]      = 0x36; /* '6' */
    shiftKey[KEY_6]     = 0x5E; /* '^' */
    baseKey[KEY_7]      = 0x37; /* '7' */
    shiftKey[KEY_7]     = 0x26; /* '&' */
    baseKey[KEY_8]      = 0x38; /* '8' */
    shiftKey[KEY_8]     = 0x2A; /* '*' */
    baseKey[KEY_9]      = 0x39; /* '9' */
    shiftKey[KEY_9]     = 0x28; /* '(' */
    baseKey[KEY_0]      = 0x30; /* '0' */
    shiftKey[KEY_0]     = 0x29; /* ')' */
    baseKey[KEY_MINUS]  = 0x2D; /* '-' */
    shiftKey[KEY_MINUS] = 0x5F; /* '_' */
    baseKey[KEY_EQUAL]  = 0x3D; /* '=' */
    shiftKey[KEY_EQUAL] = 0x2B; /* '+' */
    baseKey[KEY_BACKSPACE]  = 0x08; /* BS: BackSpace */
    shiftKey[KEY_BACKSPACE] = 0x08;
    baseKey[KEY_TAB]    = 0x09; /* HT: Horizontal Tab */
    shiftKey[KEY_TAB]   = 0x09; /* @@?XK_ISO_Left_Tab?@@ */
    baseKey[KEY_Q]      = 0x71; /* 'q' */
    shiftKey[KEY_Q]     = 0x51; /* 'Q' */
    baseKey[KEY_W]      = 0x77; /* 'w' */
    shiftKey[KEY_W]     = 0x57; /* 'W' */
    baseKey[KEY_E]      = 0x65; /* 'e' */
    shiftKey[KEY_E]     = 0x45; /* 'E' */
    baseKey[KEY_R]      = 0x72; /* 'r' */
    shiftKey[KEY_R]     = 0x52; /* 'R' */
    baseKey[KEY_T]      = 0x74; /* 't' */
    shiftKey[KEY_T]     = 0x54; /* 'T' */
    baseKey[KEY_Y]      = 0x79; /* 'y' */
    shiftKey[KEY_Y]     = 0x59; /* 'Y' */
    baseKey[KEY_U]      = 0x75; /* 'u' */
    shiftKey[KEY_U]     = 0x55; /* 'U' */
    baseKey[KEY_I]      = 0x69; /* 'i' */
    shiftKey[KEY_I]     = 0x49; /* 'I' */
    baseKey[KEY_O]      = 0x6F; /* 'o' */
    shiftKey[KEY_O]     = 0x4F; /* 'O' */
    baseKey[KEY_P]      = 0x70; /* 'p' */
    shiftKey[KEY_P]     = 0x50; /* 'P' */
    baseKey[KEY_LEFTBRACE]   = 0x5B; /* '[' */
    shiftKey[KEY_LEFTBRACE]  = 0x7B; /* '{' */
    baseKey[KEY_RIGHTBRACE]  = 0x5D; /* ']' */
    shiftKey[KEY_RIGHTBRACE] = 0x7D; /* '}' */
    baseKey[KEY_ENTER]       = 0x0D; /* CR: Carriage Return */
    shiftKey[KEY_ENTER]      = 0x0D;
    baseKey[KEY_LEFTCTRL]    = KEY_LEFTCTRL; /* XK_Control_L;*/
    shiftKey[KEY_LEFTCTRL]   = KEY_LEFTCTRL; /* XK_Control_L;*/
    baseKey[KEY_A]      = 0x61; /* 'a' */
    shiftKey[KEY_A]     = 0x41; /* 'A' */
    baseKey[KEY_S]      = 0x73; /* 's' */
    shiftKey[KEY_S]     = 0x53; /* 'S' */
    baseKey[KEY_D]      = 0x64; /* 'd' */
    shiftKey[KEY_D]     = 0x44; /* 'D' */
    baseKey[KEY_F]      = 0x66; /* 'f' */
    shiftKey[KEY_F]     = 0x46; /* 'F' */
    baseKey[KEY_G]      = 0x67; /* 'g' */
    shiftKey[KEY_G]     = 0x47; /* 'G' */
    baseKey[KEY_H]      = 0x68; /* 'h' */
    shiftKey[KEY_H]     = 0x48; /* 'H' */
    baseKey[KEY_J]      = 0x6A; /* 'j' */
    shiftKey[KEY_J]     = 0x4A; /* 'J' */
    baseKey[KEY_K]      = 0x6B; /* 'k' */
    shiftKey[KEY_K]     = 0x4B; /* 'K' */
    baseKey[KEY_L]      = 0x6C; /* 'l' */
    shiftKey[KEY_L]     = 0x4C; /* 'L' */
    baseKey[KEY_SEMICOLON]   = 0x3B; /* ';' */
    shiftKey[KEY_SEMICOLON]  = 0x3A; /* ':' */
    baseKey[KEY_APOSTROPHE]  = 0x27; /* ''' */
    shiftKey[KEY_APOSTROPHE] = 0x22; /* '"' */
    baseKey[KEY_GRAVE]       = 0x60; /* '`' */
    shiftKey[KEY_GRAVE]      = 0x7E; /* '~' */
    baseKey[KEY_LEFTSHIFT]   = KEY_LEFTSHIFT; /*XK_Shift_L;*/
    shiftKey[KEY_LEFTSHIFT]  = KEY_LEFTSHIFT; /*XK_Shift_L; */
    baseKey[KEY_BACKSLASH]   = 0x5C; /* '\' */
    shiftKey[KEY_BACKSLASH]  = 0x7C; /* '|' */
    baseKey[KEY_Z]      = 0x7A; /* 'z' */
    shiftKey[KEY_Z]     = 0x5A; /* 'Z' */
    baseKey[KEY_X]      = 0x78; /* 'x' */
    shiftKey[KEY_X]     = 0x58; /* 'X' */
    baseKey[KEY_C]      = 0x63; /* 'c' */
    shiftKey[KEY_C]     = 0x43; /* 'C' */
    baseKey[KEY_V]      = 0x76; /* 'v' */
    shiftKey[KEY_V]     = 0x56; /* 'V' */
    baseKey[KEY_B]      = 0x62; /* 'b' */
    shiftKey[KEY_B]     = 0x42; /* 'B' */
    baseKey[KEY_N]      = 0x6E; /* 'n' */
    shiftKey[KEY_N]     = 0x4E; /* 'N' */
    baseKey[KEY_M]      = 0x6D; /* 'm' */
    shiftKey[KEY_M]     = 0x4D; /* 'M' */
    baseKey[KEY_COMMA]  = 0x2C; /* ',' */
    shiftKey[KEY_COMMA] = 0x3C; /* '<' */
    baseKey[KEY_DOT]    = 0x2E; /* '.' */
    shiftKey[KEY_DOT]   = 0x3E; /* '>' */
    baseKey[KEY_SLASH]  = 0x2F; /* '/' */
    shiftKey[KEY_SLASH] = 0x3F; /* '?' */
    baseKey[KEY_RIGHTSHIFT]  = KEY_RIGHTSHIFT; /* XK_Shift_R;*/
    shiftKey[KEY_RIGHTSHIFT] = KEY_RIGHTSHIFT; /* XK_Shift_R;*/
    baseKey[KEY_KPASTERISK]  = 0x2A; /* '*' */
    shiftKey[KEY_KPASTERISK] = 0x2A; /* '*' */
    baseKey[KEY_LEFTALT]    = KEY_LEFTALT; /* XK_Alt_L;*/
    shiftKey[KEY_LEFTALT]   = KEY_LEFTALT; /* XK_Alt_L;*/
    baseKey[KEY_SPACE]      = 0x20; /* ' ' */
    shiftKey[KEY_SPACE]     = 0x20;
    /*
    baseKey[KEY_CAPSLOCK]   = XK_Caps_Lock;
    shiftKey[KEY_CAPSLOCK]  = XK_Caps_Lock;
    baseKey[KEY_F1]      = XK_F1;
    shiftKey[KEY_F1]     = XK_F1;
    baseKey[KEY_F2]      = XK_F2;
    shiftKey[KEY_F2]     = XK_F2;
    baseKey[KEY_F3]      = XK_F3;
    shiftKey[KEY_F3]     = XK_F3;
    baseKey[KEY_F4]      = XK_F4;
    shiftKey[KEY_F4]     = XK_F4;
    baseKey[KEY_F5]      = XK_F5;
    shiftKey[KEY_F5]     = XK_F5;
    baseKey[KEY_F6]      = XK_F6;
    shiftKey[KEY_F6]     = XK_F6;
    baseKey[KEY_F7]      = XK_F7;
    shiftKey[KEY_F7]     = XK_F7;
    baseKey[KEY_F8]      = XK_F8;
    shiftKey[KEY_F8]     = XK_F8;
    baseKey[KEY_F9]      = XK_F9;
    shiftKey[KEY_F9]     = XK_F9;
    baseKey[KEY_F10]     = XK_F10;
    shiftKey[KEY_F10]    = XK_F10;
    */
  /* NB: NumLock swaps to/from 4/left, 1/end, etc.
   *  NumLock OFF => Left, End, ..  [UNshifted]
   *  NumLock ON  =>    4,   1, ..  [  SHIFTED]
   *
   * Note: VM seems to not know, e.g., XK_KP_Page_Up
   *       so need to use XK_Page_Up here.
   */
/* @@FIXME: track NumLock @@ *
    baseKey[KEY_NUMLOCK]     = KEY_NUMLOCK; * XK_Num_Lock;*
    shiftKey[KEY_NUMLOCK]    = KEY_NUMLOCK; * XK_Num_Lock;*
    baseKey[KEY_SCROLLLOCK]  = KEY_SCROLLLOCK; * XK_Scroll_Lock;*
    shiftKey[KEY_SCROLLLOCK] = KEY_SCROLLLOCK; * XK_Scroll_Lock; *
*/
    baseKey[KEY_KP7]      = 0x37; /* '7' */
    shiftKey[KEY_KP7]     =  1; /*XK_Home;*/
    baseKey[KEY_KP8]      = 0x38; /* '8' */
    shiftKey[KEY_KP8]     = 30; /*XK_Up;*/
    baseKey[KEY_KP9] 	  = 0x39; /* '9' */
    shiftKey[KEY_KP9]     = 11; /*XK_Page_Up;*/
    baseKey[KEY_KPMINUS]  = 0x2D; /*XK_minus;*/
    shiftKey[KEY_KPMINUS] = 0x2D; /*XK_minus;*/
    baseKey[KEY_KP4]      = 0x34; /* '4' */
    shiftKey[KEY_KP4]     = 28; /*XK_Left;*/
    baseKey[KEY_KP5]      = 0x35; /* '5' */
    shiftKey[KEY_KP5]     =  1; /* XK_Begin*/
    baseKey[KEY_KP6]      = 0x36; /* '6' */
    shiftKey[KEY_KP6]     = 29; /*XK_Right;*/
    baseKey[KEY_KPPLUS]   = 0x2B; /*XK_plus;*/
    shiftKey[KEY_KPPLUS]  = 0x2B; /*XK_plus;*/
    baseKey[KEY_KP1]      = 0x31; /* '1' */
    shiftKey[KEY_KP1]     =  4; /*XK_End;*/
    baseKey[KEY_KP2]      = 0x32; /* '2' */
    shiftKey[KEY_KP2]     = 31; /*XK_Down;*/
    baseKey[KEY_KP3]      = 0x33; /* '3' */
    shiftKey[KEY_KP3]     = 11; /*XK_Page_Down;*/
    baseKey[KEY_KP0]      = 0x30; /* '0' */
    shiftKey[KEY_KP0]     =  5; /*XK_Insert;*/
    baseKey[KEY_KPDOT]    = 0x2E; /*XK_period; */
    shiftKey[KEY_KPDOT]   = 0x2E; /*XK_period; ??delete?? */

/*******************
    baseKey[KEY_ZENKAKUHANKAKU]  = 0x;
    shiftKey[KEY_ZENKAKUHANKAKU] = 0x;
    baseKey[KEY_102ND]      = 0x;
    shiftKey[KEY_102ND]     = 0x;
*******************/
/*
    baseKey[KEY_F11]      = XK_F11;
    shiftKey[KEY_F11]     = XK_F11;
    baseKey[KEY_F12]      = XK_F12;
    shiftKey[KEY_F12]     = XK_F12;
*/
/*******************
    baseKey[KEY_RO]      = 0x;
    shiftKey[KEY_RO]     = 0x;
    baseKey[KEY_KATAKANA]  = 0x;
    shiftKey[KEY_KATAKANA] = 0x;
    baseKey[KEY_HIRAGANA]  = 0x;
    shiftKey[KEY_HIRAGANA] = 0x;
    baseKey[KEY_HENKAN]  = 0x;
    shiftKey[KEY_HENKAN] = 0x;
    baseKey[KEY_KATAKANAHIRAGANA]  = 0x;
    shiftKey[KEY_KATAKANAHIRAGANA] = 0x;
    baseKey[KEY_MUHENKAN]  = 0x;
    shiftKey[KEY_MUHENKAN] = 0x;
    baseKey[KEY_KPJPCOMMA]  = 0x;
    shiftKey[KEY_KPJPCOMMA] = 0x;
*******************/

/*
 * Note: ASCII for KeyPad Chars; add 0xFF80 for keysym defs 
 *  CR (Enter) = 0x08 --> 0xFF88 = XK_KP_Enter
 */
    baseKey[KEY_KPENTER]    = 0x0D; /* ?XK_Return?  ?XK_KP_Enter? */
    shiftKey[KEY_KPENTER]   = 0x0D; /* CR */
    baseKey[KEY_RIGHTCTRL]  = KEY_RIGHTCTRL; /* XK_Control_R; */
    shiftKey[KEY_RIGHTCTRL] = KEY_RIGHTCTRL; /* XK_Control_R;*/
    baseKey[KEY_KPSLASH]    = 0x2f ; /*XK_slash;  * XK_KP_Divide */
    shiftKey[KEY_KPSLASH]   = 0x2f ; /*XK_slash; *
*
    baseKey[KEY_SYSRQ]     = KEY_SYSRQ; * XK_Sys_Req; * Print Screen **
    shiftKey[KEY_SYSRQ]    = KEY_SYSRQ; * XK_Sys_Req; *
*/
    baseKey[KEY_RIGHTALT]  = KEY_RIGHTALT; /* XK_Alt_R;*/
    shiftKey[KEY_RIGHTALT] = KEY_RIGHTALT; /* XK_Alt_R;*/
    baseKey[KEY_LINEFEED]  = 0x0A; /* LF: LineFeed; ^J; NB: XK_Linefeed = 0xFF0A */ 
    shiftKey[KEY_LINEFEED] = 0x0A;
    baseKey[KEY_HOME]    =  1; /*XK_Home;*/
    shiftKey[KEY_HOME]   =  1; /*XK_Home;*/
    baseKey[KEY_UP]      = 30; /*XK_Up;*/
    shiftKey[KEY_UP]     = 30; /*XK_Up;*/
    baseKey[KEY_PAGEUP]  = 11 ; /*XK_Page_Up;*/
    shiftKey[KEY_PAGEUP] = 11 ; /*XK_Page_Up;*/
    baseKey[KEY_LEFT]    = 28 ; /*XK_Left;*/
    shiftKey[KEY_LEFT]   = 28 ; /*XK_Left;*/
    baseKey[KEY_RIGHT]   = 29 ; /*XK_Right;*/
    shiftKey[KEY_RIGHT]  = 29; /*XK_Right;*/
    baseKey[KEY_END]     =  4; /*XK_End;*/
    shiftKey[KEY_END]    =  4; /* XK_End;*/
    baseKey[KEY_DOWN]    = 31; /*XK_Down;*/
    shiftKey[KEY_DOWN]   = 31;
    baseKey[KEY_PAGEDOWN]  = 12; /*XK_Page_Down;*/
    shiftKey[KEY_PAGEDOWN] = 12; /*XK_Page_Down;*/
    baseKey[KEY_INSERT]  =  5; /*XK_Insert;*/
    shiftKey[KEY_INSERT] =  5;
    /*    baseKey[KEY_DELETE]  = XK_Delete;
    shiftKey[KEY_DELETE] = XK_Delete;
    */
/*******************
    baseKey[KEY_MACRO]  = 0x;
    shiftKey[KEY_MACRO] = 0x;
    baseKey[KEY_MUTE]  = 0x;
    shiftKey[KEY_MUTE] = 0x;
    baseKey[KEY_VOLUMEDOWN]  = 0x;
    shiftKey[KEY_VOLUMEDOWN] = 0x;
    baseKey[KEY_VOLUMEUP]  = 0x;
    shiftKey[KEY_VOLUMEUP] = 0x;
    baseKey[KEY_POWER]  = 0x;
    shiftKey[KEY_POWER] = 0x;
*******************/
    baseKey[KEY_KPEQUAL]  = 0x3D;  /* '=' */
    shiftKey[KEY_KPEQUAL] = 0x3D;
/*******************
    baseKey[KEY_KPPLUSMINUS]  = 0x;
    shiftKey[KEY_KPPLUSMINUS] = 0x;
    baseKey[KEY_PAUSE]  = 0x;
    shiftKey[KEY_PAUSE] = 0x;
    baseKey[KEY_SCALE]  = 0x;
    shiftKey[KEY_SCALE] = 0x;
    baseKey[KEY_KPCOMMA]  = 0x;
    shiftKey[KEY_KPCOMMA] = 0x;
    baseKey[KEY_HANGEUL]  = 0x;
    shiftKey[KEY_HANGEUL] = 0x;
    baseKey[KEY_HANGUEL]  = 0x;
    shiftKey[KEY_HANGUEL] = 0x;
    baseKey[KEY_HANJA]  = 0x;
    shiftKey[KEY_HANJA] = 0x;
    baseKey[KEY_YEN]  = 0x;
    shiftKey[KEY_YEN] = 0x;
*******************/
/*
    baseKey[KEY_LEFTMETA]  = XK_Super_L; * NB: NOT XK_Meta_L ! *
    shiftKey[KEY_LEFTMETA] = XK_Super_L;
    baseKey[KEY_COMPOSE]   = XK_Menu;
    shiftKey[KEY_COMPOSE]  = XK_Menu;
*/
/*******************
    baseKey[KEY_STOP]  = 0x;
    shiftKey[KEY_STOP] = 0x;
    baseKey[KEY_AGAIN]  = 0x;
    shiftKey[KEY_AGAIN] = 0x;
    baseKey[KEY_PROPS]  = 0x;
    shiftKey[KEY_PROPS] = 0x;
    baseKey[KEY_UNDO]  = 0x;
    shiftKey[KEY_UNDO] = 0x;
    baseKey[KEY_FRONT]  = 0x;
    shiftKey[KEY_FRONT] = 0x;
    baseKey[KEY_COPY]  = 0x;
    shiftKey[KEY_COPY] = 0x;
    baseKey[KEY_OPEN]  = 0x;
    shiftKey[KEY_OPEN] = 0x;
    baseKey[KEY_PASTE]  = 0x;
    shiftKey[KEY_PASTE] = 0x;
    baseKey[KEY_FIND]  = 0x;
    shiftKey[KEY_FIND] = 0x;
    baseKey[KEY_CUT]  = 0x;
    shiftKey[KEY_CUT] = 0x;
    baseKey[KEY_HELP]  = 0x;
    shiftKey[KEY_HELP] = 0x;
    baseKey[KEY_MENU]  = 0x;
    shiftKey[KEY_MENU] = 0x;
    baseKey[KEY_CALC]  = 0x;
    shiftKey[KEY_CALC] = 0x;
    baseKey[KEY_SETUP]  = 0x;
    shiftKey[KEY_SETUP] = 0x;
    baseKey[KEY_SLEEP]  = 0x;
    shiftKey[KEY_SLEEP] = 0x;
    baseKey[KEY_WAKEUP]  = 0x;
    shiftKey[KEY_WAKEUP] = 0x;
    baseKey[KEY_FILE]  = 0x;
    shiftKey[KEY_FILE] = 0x;
    baseKey[KEY_SENDFILE]  = 0x;
    shiftKey[KEY_SENDFILE] = 0x;
    baseKey[KEY_DELETEFILE]  = 0x;
    shiftKey[KEY_DELETEFILE] = 0x;
    baseKey[KEY_XFER]  = 0x;
    shiftKey[KEY_XFER] = 0x;
    baseKey[KEY_PROG1]  = 0x;
    shiftKey[KEY_PROG1] = 0x;
    baseKey[KEY_PROG2]  = 0x;
    shiftKey[KEY_PROG2] = 0x;
    baseKey[KEY_WWW]  = 0x;
    shiftKey[KEY_WWW] = 0x;
    baseKey[KEY_MSDOS]  = 0x;
    shiftKey[KEY_MSDOS] = 0x;
    baseKey[KEY_COFFEE]  = 0x;
    shiftKey[KEY_COFFEE] = 0x;
    baseKey[KEY_SCREENLOCK]  = 0x;
    shiftKey[KEY_SCREENLOCK] = 0x;
    baseKey[KEY_ROTATE]  = 0x;
    shiftKey[KEY_ROTATE] = 0x;
    baseKey[KEY_DIRECTION]  = 0x;
    shiftKey[KEY_DIRECTION] = 0x;
    baseKey[KEY_CYCLEWINDOWS]  = 0x;
    shiftKey[KEY_CYCLEWINDOWS] = 0x;
    baseKey[KEY_MAIL]  = 0x;
    shiftKey[KEY_MAIL] = 0x;
    baseKey[KEY_BOOKMARKS]  = 0x;
    shiftKey[KEY_BOOKMARKS] = 0x;
    baseKey[KEY_COMPUTER]  = 0x;
    shiftKey[KEY_COMPUTER] = 0x;
    baseKey[KEY_BACK]  = 0x;
    shiftKey[KEY_BACK] = 0x;
    baseKey[KEY_FORWARD]  = 0x;
    shiftKey[KEY_FORWARD] = 0x;
    baseKey[KEY_CLOSECD]  = 0x;
    shiftKey[KEY_CLOSECD] = 0x;
    baseKey[KEY_EJECTCD]  = 0x;
    shiftKey[KEY_EJECTCD] = 0x;
    baseKey[KEY_EJECTCLOSECD]  = 0x;
    shiftKey[KEY_EJECTCLOSECD] = 0x;
    baseKey[KEY_NEXTSONG]  = 0x;
    shiftKey[KEY_NEXTSONG] = 0x;
    baseKey[KEY_PLAYPAUSE]  = 0x;
    shiftKey[KEY_PLAYPAUSE] = 0x;
    baseKey[KEY_PREVIOUSSONG]  = 0x;
    shiftKey[KEY_PREVIOUSSONG] = 0x;
    baseKey[KEY_STOPCD]  = 0x;
    shiftKey[KEY_STOPCD] = 0x;
    baseKey[KEY_RECORD]  = 0x;
    shiftKey[KEY_RECORD] = 0x;
    baseKey[KEY_REWIND]  = 0x;
    shiftKey[KEY_REWIND] = 0x;
    baseKey[KEY_PHONE]  = 0x;
    shiftKey[KEY_PHONE] = 0x;
    baseKey[KEY_ISO]  = 0x;
    shiftKey[KEY_ISO] = 0x;
    baseKey[KEY_CONFIG]  = 0x;
    shiftKey[KEY_CONFIG] = 0x;
    baseKey[KEY_HOMEPAGE]  = 0x;
    shiftKey[KEY_HOMEPAGE] = 0x;
    baseKey[KEY_REFRESH]  = 0x;
    shiftKey[KEY_REFRESH] = 0x;
    baseKey[KEY_EXIT]  = 0x;
    shiftKey[KEY_EXIT] = 0x;
    baseKey[KEY_MOVE]  = 0x;
    shiftKey[KEY_MOVE] = 0x;
    baseKey[KEY_EDIT]  = 0x;
    shiftKey[KEY_EDIT] = 0x;
    baseKey[KEY_SCROLLUP]  = 0x;
    shiftKey[KEY_SCROLLUP] = 0x;
    baseKey[KEY_SCROLLDOWN]  = 0x;
    shiftKey[KEY_SCROLLDOWN] = 0x;
    baseKey[KEY_KPLEFTPAREN]  = 0x;
    shiftKey[KEY_KPLEFTPAREN] = 0x;
    baseKey[KEY_KPRIGHTPAREN]  = 0x;
    shiftKey[KEY_KPRIGHTPAREN] = 0x;
    baseKey[KEY_NEW]  = 0x;
    shiftKey[KEY_NEW] = 0x;
    baseKey[KEY_REDO]  = 0x;
    shiftKey[KEY_REDO] = 0x;
    baseKey[KEY_F13]  = 0x;
    shiftKey[KEY_F13] = 0x;
    baseKey[KEY_F14]  = 0x;
    shiftKey[KEY_F14] = 0x;
    baseKey[KEY_F15]  = 0x;
    shiftKey[KEY_F15] = 0x;
    baseKey[KEY_F16]  = 0x;
    shiftKey[KEY_F16] = 0x;
    baseKey[KEY_F17]  = 0x;
    shiftKey[KEY_F17] = 0x;
    baseKey[KEY_F18]  = 0x;
    shiftKey[KEY_F18] = 0x;
    baseKey[KEY_F19]  = 0x;
    shiftKey[KEY_F19] = 0x;
    baseKey[KEY_F20]  = 0x;
    shiftKey[KEY_F20] = 0x;
    baseKey[KEY_F21]  = 0x;
    shiftKey[KEY_F21] = 0x;
    baseKey[KEY_F22]  = 0x;
    shiftKey[KEY_F22] = 0x;
    baseKey[KEY_F23]  = 0x;
    shiftKey[KEY_F23] = 0x;
    baseKey[KEY_F24]  = 0x;
    shiftKey[KEY_F24] = 0x;
    baseKey[KEY_PLAYCD]  = 0x;
    shiftKey[KEY_PLAYCD] = 0x;
    baseKey[KEY_PAUSECD]  = 0x;
    shiftKey[KEY_PAUSECD] = 0x;
    baseKey[KEY_PROG3]  = 0x;
    shiftKey[KEY_PROG3] = 0x;
    baseKey[KEY_PROG4]  = 0x;
    shiftKey[KEY_PROG4] = 0x;
    baseKey[KEY_DASHBOARD]  = 0x;
    shiftKey[KEY_DASHBOARD] = 0x;
    baseKey[KEY_SUSPEND]  = 0x;
    shiftKey[KEY_SUSPEND] = 0x;
    baseKey[KEY_CLOSE]  = 0x;
    shiftKey[KEY_CLOSE] = 0x;
    baseKey[KEY_PLAY]  = 0x;
    shiftKey[KEY_PLAY] = 0x;
    baseKey[KEY_FASTFORWARD]  = 0x;
    shiftKey[KEY_FASTFORWARD] = 0x;
    baseKey[KEY_BASSBOOST]  = 0x;
    shiftKey[KEY_BASSBOOST] = 0x;
    baseKey[KEY_PRINT]  = 0x;
    shiftKey[KEY_PRINT] = 0x;
    baseKey[KEY_HP]  = 0x;
    shiftKey[KEY_HP] = 0x;
    baseKey[KEY_CAMERA]  = 0x;
    shiftKey[KEY_CAMERA] = 0x;
    baseKey[KEY_SOUND]  = 0x;
    shiftKey[KEY_SOUND] = 0x;
    baseKey[KEY_QUESTION]  = 0x;
    shiftKey[KEY_QUESTION] = 0x;
    baseKey[KEY_EMAIL]  = 0x;
    shiftKey[KEY_EMAIL] = 0x;
    baseKey[KEY_CHAT]  = 0x;
    shiftKey[KEY_CHAT] = 0x;
    baseKey[KEY_SEARCH]  = 0x;
    shiftKey[KEY_SEARCH] = 0x;
    baseKey[KEY_CONNECT]  = 0x;
    shiftKey[KEY_CONNECT] = 0x;
    baseKey[KEY_FINANCE]  = 0x;
    shiftKey[KEY_FINANCE] = 0x;
    baseKey[KEY_SPORT]  = 0x;
    shiftKey[KEY_SPORT] = 0x;
    baseKey[KEY_SHOP]  = 0x;
    shiftKey[KEY_SHOP] = 0x;
    baseKey[KEY_ALTERASE]  = 0x;
    shiftKey[KEY_ALTERASE] = 0x;
    baseKey[KEY_CANCEL]  = 0x;
    shiftKey[KEY_CANCEL] = 0x;
    baseKey[KEY_BRIGHTNESSDOWN]  = 0x;
    shiftKey[KEY_BRIGHTNESSDOWN] = 0x;
    baseKey[KEY_BRIGHTNESSUP]  = 0x;
    shiftKey[KEY_BRIGHTNESSUP] = 0x;
    baseKey[KEY_MEDIA]  = 0x;
    shiftKey[KEY_MEDIA] = 0x;
    baseKey[KEY_SWITCHVIDEOMODE]  = 0x;
    shiftKey[KEY_SWITCHVIDEOMODE] = 0x;
    baseKey[KEY_KBDILLUMTOGGLE]  = 0x;
    shiftKey[KEY_KBDILLUMTOGGLE] = 0x;
    baseKey[KEY_KBDILLUMDOWN]  = 0x;
    shiftKey[KEY_KBDILLUMDOWN] = 0x;
    baseKey[KEY_KBDILLUMUP]  = 0x;
    shiftKey[KEY_KBDILLUMUP] = 0x;
    baseKey[KEY_SEND]  = 0x;
    shiftKey[KEY_SEND] = 0x;
    baseKey[KEY_REPLY]  = 0x;
    shiftKey[KEY_REPLY] = 0x;
    baseKey[KEY_FORWARDMAIL]  = 0x;
    shiftKey[KEY_FORWARDMAIL] = 0x;
    baseKey[KEY_SAVE]  = 0x;
    shiftKey[KEY_SAVE] = 0x;
    baseKey[KEY_DOCUMENTS]  = 0x;
    shiftKey[KEY_DOCUMENTS] = 0x;
    baseKey[KEY_BATTERY]  = 0x;
    shiftKey[KEY_BATTERY] = 0x;
    baseKey[KEY_BLUETOOTH]  = 0x;
    shiftKey[KEY_BLUETOOTH] = 0x;
    baseKey[KEY_WLAN]  = 0x;
    shiftKey[KEY_WLAN] = 0x;
    baseKey[KEY_UWB]  = 0x;
    shiftKey[KEY_UWB] = 0x;
    baseKey[KEY_UNKNOWN]  = 0x;
    shiftKey[KEY_UNKNOWN] = 0x;
    baseKey[KEY_VIDEO]  = 0x;
    shiftKey[KEY_VIDEO] = 0x;
    baseKey[KEY_VIDEO]  = 0x;
    shiftKey[KEY_VIDEO] = 0x;
    baseKey[KEY_BRIGHTNESS_CYCLE]  = 0x;
    shiftKey[KEY_BRIGHTNESS_CYCLE] = 0x;
    baseKey[KEY_BRIGHTNESS_AUTO]  = 0x;
    shiftKey[KEY_BRIGHTNESS_AUTO] = 0x;
    baseKey[KEY_BRIGHTNESS_ZERO]  = 0x;
    shiftKey[KEY_BRIGHTNESS_ZERO] = 0x;
    baseKey[KEY_DISPLAY_OFF]  = 0x;
    shiftKey[KEY_DISPLAY_OFF] = 0x;
    baseKey[KEY_WWAN]  = 0x;
    shiftKey[KEY_WWAN] = 0x;
    baseKey[KEY_WIMAX]  = 0x;
    shiftKey[KEY_WIMAX] = 0x;
    baseKey[KEY_RFKILL]  = 0x;
    shiftKey[KEY_RFKILL] = 0x;
    baseKey[KEY_MICMUTE]  = 0x;
    shiftKey[KEY_MICMUTE] = 0x;
**************/
    keyMapInitialized = 1; /* C thinks this means TRUE */
}


int keyCode2keyValue( int keyCode, int useCap ) {
  if (!keyMapInitialized) initKeyMaps();
  if ((0 <= keyCode) && (keyCode < KMAPSIZE)) {
    if (useCap) {
	return( shiftKey[ keyCode ] );
    } else {
	return( baseKey[ keyCode ] ) ;
    }
  }
  switch (keyCode) { /* KeyCodes above 256 */
  case BTN_LEFT:
    return(0); /* @@??@@ */
    break;
  case BTN_MIDDLE:
    return(0); /* @@??@@ */
    break;
  case BTN_RIGHT:
    return(0); /* @@??@@ */
    break;
  default:
    return( 0 );
  }
}

/*			--- E O F --- 			*/
