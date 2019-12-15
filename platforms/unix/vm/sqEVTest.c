/*
 *  Copyright (c) 1999-2000 Vojtech Pavlik
 *  Copyright (c) 2009-2011 Red Hat, Inc
 */

/**
 * @file
 * Event device test program
 *
 * evtest prints the capabilities on the kernel devices in /dev/input/eventX
 * and their events. Its primary purpose is for kernel or X driver
 * debugging.
 *
 * See INSTALL for installation details or manually compile with
 * gcc -o evtest evtest.c
 */

/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * Should you need to contact me, the author, you can do so either by
 * e-mail - mail your message to <vojtech@ucw.cz>, or by paper mail:
 * Vojtech Pavlik, Simunkova 1594, Prague 8, 182 00 Czech Republic
 */

#define _GNU_SOURCE /* for asprintf */
#include <stdio.h>
#include <stdint.h>

#if HAVE_CONFIG_H
#include <config.h>
#endif

#include <linux/version.h>
#include <linux/input.h>

#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <errno.h>
#include <getopt.h>
#include <ctype.h>
#include <signal.h>
#include <limits.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <limits.h> /* PATH_MAX */

#ifndef input_event_sec
#define input_event_sec time.tv_sec
#define input_event_usec time.tv_usec
#endif

#define BITS_PER_LONG (sizeof(long) * 8)
#define NBITS(x) ((((x)-1)/BITS_PER_LONG)+1)
#define OFF(x)  ((x)%BITS_PER_LONG)
#define BIT(x)  (1UL<<OFF(x))
#define LONG(x) ((x)/BITS_PER_LONG)
#define test_bit(bit, array)	((array[LONG(bit)] >> OFF(bit)) & 1)

#define DEV_INPUT_EVENT "/dev/input"
#define EVENT_DEV_NAME "event"

#ifndef EV_SYN
#define EV_SYN 0
#endif
#ifndef SYN_MAX
#define SYN_MAX 3
#define SYN_CNT (SYN_MAX + 1)
#endif
#ifndef SYN_MT_REPORT
#define SYN_MT_REPORT 2
#endif
#ifndef SYN_DROPPED
#define SYN_DROPPED 3
#endif

#define NAME_ELEMENT(element) [element] = #element

enum evtest_mode {
	MODE_CAPTURE,
	MODE_QUERY,
	MODE_VERSION,
};

static const struct query_mode {
	const char *name;
	int event_type;
	int max;
	int rq;
} query_modes[] = {
	{ "EV_KEY", EV_KEY, KEY_MAX, EVIOCGKEY(KEY_MAX) },
	{ "EV_LED", EV_LED, LED_MAX, EVIOCGLED(LED_MAX) },
	{ "EV_SND", EV_SND, SND_MAX, EVIOCGSND(SND_MAX) },
	{ "EV_SW",  EV_SW, SW_MAX, EVIOCGSW(SW_MAX) },
};

static int grab_flag = 0;
static volatile sig_atomic_t stop = 0;

static void interrupt_handler(int sig)
{
	stop = 1;
}

/**
 * Look up an entry in the query_modes table by its textual name.
 *
 * @param mode The name of the entry to be found.
 *
 * @return The requested query_mode, or NULL if it could not be found.
 */
static const struct query_mode *find_query_mode_by_name(const char *name)
{
	int i;
	for (i = 0; i < sizeof(query_modes) / sizeof(*query_modes); i++) {
		const struct query_mode *mode = &query_modes[i];
		if (strcmp(mode->name, name) == 0)
			return mode;
	}
	return NULL;
}

/**
 * Look up an entry in the query_modes table by value.
 *
 * @param event_type The value of the entry to be found.
 *
 * @return The requested query_mode, or NULL if it could not be found.
 */
static const struct query_mode *find_query_mode_by_value(int event_type)
{
	int i;
	for (i = 0; i < sizeof(query_modes) / sizeof(*query_modes); i++) {
		const struct query_mode *mode = &query_modes[i];
		if (mode->event_type == event_type)
			return mode;
	}
	return NULL;
}

/**
 * Find a query_mode based on a string identifier. The string can either
 * be a numerical value (e.g. "5") or the name of the event type in question
 * (e.g. "EV_SW").
 *
 * @param query_mode The mode to search for
 *
 * @return The requested code's numerical value, or negative on error.
 */
static const struct query_mode *find_query_mode(const char *query_mode)
{
	if (isdigit(query_mode[0])) {
		unsigned long val;
		errno = 0;
		val = strtoul(query_mode, NULL, 0);
		if (errno)
			return NULL;
		return find_query_mode_by_value(val);
	} else {
		return find_query_mode_by_name(query_mode);
	}
}

static const char * const events[EV_MAX + 1] = {
	[0 ... EV_MAX] = NULL,
	NAME_ELEMENT(EV_SYN),			NAME_ELEMENT(EV_KEY),
	NAME_ELEMENT(EV_REL),			NAME_ELEMENT(EV_ABS),
	NAME_ELEMENT(EV_MSC),			NAME_ELEMENT(EV_LED),
	NAME_ELEMENT(EV_SND),			NAME_ELEMENT(EV_REP),
	NAME_ELEMENT(EV_FF),			NAME_ELEMENT(EV_PWR),
	NAME_ELEMENT(EV_FF_STATUS),		NAME_ELEMENT(EV_SW),
};

static const int maxval[EV_MAX + 1] = {
	[0 ... EV_MAX] = -1,
	[EV_SYN] = SYN_MAX,
	[EV_KEY] = KEY_MAX,
	[EV_REL] = REL_MAX,
	[EV_ABS] = ABS_MAX,
	[EV_MSC] = MSC_MAX,
	[EV_SW] = SW_MAX,
	[EV_LED] = LED_MAX,
	[EV_SND] = SND_MAX,
	[EV_REP] = REP_MAX,
	[EV_FF] = FF_MAX,
	[EV_FF_STATUS] = FF_STATUS_MAX,
};


#ifdef INPUT_PROP_SEMI_MT
static const char * const props[INPUT_PROP_MAX + 1] = {
	[0 ... INPUT_PROP_MAX] = NULL,
	NAME_ELEMENT(INPUT_PROP_POINTER),
	NAME_ELEMENT(INPUT_PROP_DIRECT),
	NAME_ELEMENT(INPUT_PROP_BUTTONPAD),
	NAME_ELEMENT(INPUT_PROP_SEMI_MT),
#ifdef INPUT_PROP_TOPBUTTONPAD
	NAME_ELEMENT(INPUT_PROP_TOPBUTTONPAD),
#endif
#ifdef INPUT_PROP_POINTING_STICK
	NAME_ELEMENT(INPUT_PROP_POINTING_STICK),
#endif
#ifdef INPUT_PROP_ACCELEROMETER
	NAME_ELEMENT(INPUT_PROP_ACCELEROMETER),
#endif
};
#endif

static const char * const keys[KEY_MAX + 1] = {
	[0 ... KEY_MAX] = NULL,
	NAME_ELEMENT(KEY_RESERVED),		NAME_ELEMENT(KEY_ESC),
	NAME_ELEMENT(KEY_1),			NAME_ELEMENT(KEY_2),
	NAME_ELEMENT(KEY_3),			NAME_ELEMENT(KEY_4),
	NAME_ELEMENT(KEY_5),			NAME_ELEMENT(KEY_6),
	NAME_ELEMENT(KEY_7),			NAME_ELEMENT(KEY_8),
	NAME_ELEMENT(KEY_9),			NAME_ELEMENT(KEY_0),
	NAME_ELEMENT(KEY_MINUS),		NAME_ELEMENT(KEY_EQUAL),
	NAME_ELEMENT(KEY_BACKSPACE),		NAME_ELEMENT(KEY_TAB),
	NAME_ELEMENT(KEY_Q),			NAME_ELEMENT(KEY_W),
	NAME_ELEMENT(KEY_E),			NAME_ELEMENT(KEY_R),
	NAME_ELEMENT(KEY_T),			NAME_ELEMENT(KEY_Y),
	NAME_ELEMENT(KEY_U),			NAME_ELEMENT(KEY_I),
	NAME_ELEMENT(KEY_O),			NAME_ELEMENT(KEY_P),
	NAME_ELEMENT(KEY_LEFTBRACE),		NAME_ELEMENT(KEY_RIGHTBRACE),
	NAME_ELEMENT(KEY_ENTER),		NAME_ELEMENT(KEY_LEFTCTRL),
	NAME_ELEMENT(KEY_A),			NAME_ELEMENT(KEY_S),
	NAME_ELEMENT(KEY_D),			NAME_ELEMENT(KEY_F),
	NAME_ELEMENT(KEY_G),			NAME_ELEMENT(KEY_H),
	NAME_ELEMENT(KEY_J),			NAME_ELEMENT(KEY_K),
	NAME_ELEMENT(KEY_L),			NAME_ELEMENT(KEY_SEMICOLON),
	NAME_ELEMENT(KEY_APOSTROPHE),		NAME_ELEMENT(KEY_GRAVE),
	NAME_ELEMENT(KEY_LEFTSHIFT),		NAME_ELEMENT(KEY_BACKSLASH),
	NAME_ELEMENT(KEY_Z),			NAME_ELEMENT(KEY_X),
	NAME_ELEMENT(KEY_C),			NAME_ELEMENT(KEY_V),
	NAME_ELEMENT(KEY_B),			NAME_ELEMENT(KEY_N),
	NAME_ELEMENT(KEY_M),			NAME_ELEMENT(KEY_COMMA),
	NAME_ELEMENT(KEY_DOT),			NAME_ELEMENT(KEY_SLASH),
	NAME_ELEMENT(KEY_RIGHTSHIFT),		NAME_ELEMENT(KEY_KPASTERISK),
	NAME_ELEMENT(KEY_LEFTALT),		NAME_ELEMENT(KEY_SPACE),
	NAME_ELEMENT(KEY_CAPSLOCK),		NAME_ELEMENT(KEY_F1),
	NAME_ELEMENT(KEY_F2),			NAME_ELEMENT(KEY_F3),
	NAME_ELEMENT(KEY_F4),			NAME_ELEMENT(KEY_F5),
	NAME_ELEMENT(KEY_F6),			NAME_ELEMENT(KEY_F7),
	NAME_ELEMENT(KEY_F8),			NAME_ELEMENT(KEY_F9),
	NAME_ELEMENT(KEY_F10),			NAME_ELEMENT(KEY_NUMLOCK),
	NAME_ELEMENT(KEY_SCROLLLOCK),		NAME_ELEMENT(KEY_KP7),
	NAME_ELEMENT(KEY_KP8),			NAME_ELEMENT(KEY_KP9),
	NAME_ELEMENT(KEY_KPMINUS),		NAME_ELEMENT(KEY_KP4),
	NAME_ELEMENT(KEY_KP5),			NAME_ELEMENT(KEY_KP6),
	NAME_ELEMENT(KEY_KPPLUS),		NAME_ELEMENT(KEY_KP1),
	NAME_ELEMENT(KEY_KP2),			NAME_ELEMENT(KEY_KP3),
	NAME_ELEMENT(KEY_KP0),			NAME_ELEMENT(KEY_KPDOT),
	NAME_ELEMENT(KEY_ZENKAKUHANKAKU), 	NAME_ELEMENT(KEY_102ND),
	NAME_ELEMENT(KEY_F11),			NAME_ELEMENT(KEY_F12),
	NAME_ELEMENT(KEY_RO),			NAME_ELEMENT(KEY_KATAKANA),
	NAME_ELEMENT(KEY_HIRAGANA),		NAME_ELEMENT(KEY_HENKAN),
	NAME_ELEMENT(KEY_KATAKANAHIRAGANA),	NAME_ELEMENT(KEY_MUHENKAN),
	NAME_ELEMENT(KEY_KPJPCOMMA),		NAME_ELEMENT(KEY_KPENTER),
	NAME_ELEMENT(KEY_RIGHTCTRL),		NAME_ELEMENT(KEY_KPSLASH),
	NAME_ELEMENT(KEY_SYSRQ),		NAME_ELEMENT(KEY_RIGHTALT),
	NAME_ELEMENT(KEY_LINEFEED),		NAME_ELEMENT(KEY_HOME),
	NAME_ELEMENT(KEY_UP),			NAME_ELEMENT(KEY_PAGEUP),
	NAME_ELEMENT(KEY_LEFT),			NAME_ELEMENT(KEY_RIGHT),
	NAME_ELEMENT(KEY_END),			NAME_ELEMENT(KEY_DOWN),
	NAME_ELEMENT(KEY_PAGEDOWN),		NAME_ELEMENT(KEY_INSERT),
	NAME_ELEMENT(KEY_DELETE),		NAME_ELEMENT(KEY_MACRO),
	NAME_ELEMENT(KEY_MUTE),			NAME_ELEMENT(KEY_VOLUMEDOWN),
	NAME_ELEMENT(KEY_VOLUMEUP),		NAME_ELEMENT(KEY_POWER),
	NAME_ELEMENT(KEY_KPEQUAL),		NAME_ELEMENT(KEY_KPPLUSMINUS),
	NAME_ELEMENT(KEY_PAUSE),		NAME_ELEMENT(KEY_KPCOMMA),
	NAME_ELEMENT(KEY_HANGUEL),		NAME_ELEMENT(KEY_HANJA),
	NAME_ELEMENT(KEY_YEN),			NAME_ELEMENT(KEY_LEFTMETA),
	NAME_ELEMENT(KEY_RIGHTMETA),		NAME_ELEMENT(KEY_COMPOSE),
	NAME_ELEMENT(KEY_STOP),			NAME_ELEMENT(KEY_AGAIN),
	NAME_ELEMENT(KEY_PROPS),		NAME_ELEMENT(KEY_UNDO),
	NAME_ELEMENT(KEY_FRONT),		NAME_ELEMENT(KEY_COPY),
	NAME_ELEMENT(KEY_OPEN),			NAME_ELEMENT(KEY_PASTE),
	NAME_ELEMENT(KEY_FIND),			NAME_ELEMENT(KEY_CUT),
	NAME_ELEMENT(KEY_HELP),			NAME_ELEMENT(KEY_MENU),
	NAME_ELEMENT(KEY_CALC),			NAME_ELEMENT(KEY_SETUP),
	NAME_ELEMENT(KEY_SLEEP),		NAME_ELEMENT(KEY_WAKEUP),
	NAME_ELEMENT(KEY_FILE),			NAME_ELEMENT(KEY_SENDFILE),
	NAME_ELEMENT(KEY_DELETEFILE),		NAME_ELEMENT(KEY_XFER),
	NAME_ELEMENT(KEY_PROG1),		NAME_ELEMENT(KEY_PROG2),
	NAME_ELEMENT(KEY_WWW),			NAME_ELEMENT(KEY_MSDOS),
	NAME_ELEMENT(KEY_COFFEE),		NAME_ELEMENT(KEY_DIRECTION),
	NAME_ELEMENT(KEY_CYCLEWINDOWS),		NAME_ELEMENT(KEY_MAIL),
	NAME_ELEMENT(KEY_BOOKMARKS),		NAME_ELEMENT(KEY_COMPUTER),
	NAME_ELEMENT(KEY_BACK),			NAME_ELEMENT(KEY_FORWARD),
	NAME_ELEMENT(KEY_CLOSECD),		NAME_ELEMENT(KEY_EJECTCD),
	NAME_ELEMENT(KEY_EJECTCLOSECD),		NAME_ELEMENT(KEY_NEXTSONG),
	NAME_ELEMENT(KEY_PLAYPAUSE),		NAME_ELEMENT(KEY_PREVIOUSSONG),
	NAME_ELEMENT(KEY_STOPCD),		NAME_ELEMENT(KEY_RECORD),
	NAME_ELEMENT(KEY_REWIND),		NAME_ELEMENT(KEY_PHONE),
	NAME_ELEMENT(KEY_ISO),			NAME_ELEMENT(KEY_CONFIG),
	NAME_ELEMENT(KEY_HOMEPAGE),		NAME_ELEMENT(KEY_REFRESH),
	NAME_ELEMENT(KEY_EXIT),			NAME_ELEMENT(KEY_MOVE),
	NAME_ELEMENT(KEY_EDIT),			NAME_ELEMENT(KEY_SCROLLUP),
	NAME_ELEMENT(KEY_SCROLLDOWN),		NAME_ELEMENT(KEY_KPLEFTPAREN),
	NAME_ELEMENT(KEY_KPRIGHTPAREN), 	NAME_ELEMENT(KEY_F13),
	NAME_ELEMENT(KEY_F14),			NAME_ELEMENT(KEY_F15),
	NAME_ELEMENT(KEY_F16),			NAME_ELEMENT(KEY_F17),
	NAME_ELEMENT(KEY_F18),			NAME_ELEMENT(KEY_F19),
	NAME_ELEMENT(KEY_F20),			NAME_ELEMENT(KEY_F21),
	NAME_ELEMENT(KEY_F22),			NAME_ELEMENT(KEY_F23),
	NAME_ELEMENT(KEY_F24),			NAME_ELEMENT(KEY_PLAYCD),
	NAME_ELEMENT(KEY_PAUSECD),		NAME_ELEMENT(KEY_PROG3),
	NAME_ELEMENT(KEY_PROG4),		NAME_ELEMENT(KEY_SUSPEND),
	NAME_ELEMENT(KEY_CLOSE),		NAME_ELEMENT(KEY_PLAY),
	NAME_ELEMENT(KEY_FASTFORWARD),		NAME_ELEMENT(KEY_BASSBOOST),
	NAME_ELEMENT(KEY_PRINT),		NAME_ELEMENT(KEY_HP),
	NAME_ELEMENT(KEY_CAMERA),		NAME_ELEMENT(KEY_SOUND),
	NAME_ELEMENT(KEY_QUESTION),		NAME_ELEMENT(KEY_EMAIL),
	NAME_ELEMENT(KEY_CHAT),			NAME_ELEMENT(KEY_SEARCH),
	NAME_ELEMENT(KEY_CONNECT),		NAME_ELEMENT(KEY_FINANCE),
	NAME_ELEMENT(KEY_SPORT),		NAME_ELEMENT(KEY_SHOP),
	NAME_ELEMENT(KEY_ALTERASE),		NAME_ELEMENT(KEY_CANCEL),
	NAME_ELEMENT(KEY_BRIGHTNESSDOWN),	NAME_ELEMENT(KEY_BRIGHTNESSUP),
	NAME_ELEMENT(KEY_MEDIA),		NAME_ELEMENT(KEY_UNKNOWN),
	NAME_ELEMENT(KEY_OK),
	NAME_ELEMENT(KEY_SELECT),		NAME_ELEMENT(KEY_GOTO),
	NAME_ELEMENT(KEY_CLEAR),		NAME_ELEMENT(KEY_POWER2),
	NAME_ELEMENT(KEY_OPTION),		NAME_ELEMENT(KEY_INFO),
	NAME_ELEMENT(KEY_TIME),			NAME_ELEMENT(KEY_VENDOR),
	NAME_ELEMENT(KEY_ARCHIVE),		NAME_ELEMENT(KEY_PROGRAM),
	NAME_ELEMENT(KEY_CHANNEL),		NAME_ELEMENT(KEY_FAVORITES),
	NAME_ELEMENT(KEY_EPG),			NAME_ELEMENT(KEY_PVR),
	NAME_ELEMENT(KEY_MHP),			NAME_ELEMENT(KEY_LANGUAGE),
	NAME_ELEMENT(KEY_TITLE),		NAME_ELEMENT(KEY_SUBTITLE),
	NAME_ELEMENT(KEY_ANGLE),		NAME_ELEMENT(KEY_ZOOM),
	NAME_ELEMENT(KEY_MODE),			NAME_ELEMENT(KEY_KEYBOARD),
	NAME_ELEMENT(KEY_SCREEN),		NAME_ELEMENT(KEY_PC),
	NAME_ELEMENT(KEY_TV),			NAME_ELEMENT(KEY_TV2),
	NAME_ELEMENT(KEY_VCR),			NAME_ELEMENT(KEY_VCR2),
	NAME_ELEMENT(KEY_SAT),			NAME_ELEMENT(KEY_SAT2),
	NAME_ELEMENT(KEY_CD),			NAME_ELEMENT(KEY_TAPE),
	NAME_ELEMENT(KEY_RADIO),		NAME_ELEMENT(KEY_TUNER),
	NAME_ELEMENT(KEY_PLAYER),		NAME_ELEMENT(KEY_TEXT),
	NAME_ELEMENT(KEY_DVD),			NAME_ELEMENT(KEY_AUX),
	NAME_ELEMENT(KEY_MP3),			NAME_ELEMENT(KEY_AUDIO),
	NAME_ELEMENT(KEY_VIDEO),		NAME_ELEMENT(KEY_DIRECTORY),
	NAME_ELEMENT(KEY_LIST),			NAME_ELEMENT(KEY_MEMO),
	NAME_ELEMENT(KEY_CALENDAR),		NAME_ELEMENT(KEY_RED),
	NAME_ELEMENT(KEY_GREEN),		NAME_ELEMENT(KEY_YELLOW),
	NAME_ELEMENT(KEY_BLUE),			NAME_ELEMENT(KEY_CHANNELUP),
	NAME_ELEMENT(KEY_CHANNELDOWN),		NAME_ELEMENT(KEY_FIRST),
	NAME_ELEMENT(KEY_LAST),			NAME_ELEMENT(KEY_AB),
	NAME_ELEMENT(KEY_NEXT),			NAME_ELEMENT(KEY_RESTART),
	NAME_ELEMENT(KEY_SLOW),			NAME_ELEMENT(KEY_SHUFFLE),
	NAME_ELEMENT(KEY_BREAK),		NAME_ELEMENT(KEY_PREVIOUS),
	NAME_ELEMENT(KEY_DIGITS),		NAME_ELEMENT(KEY_TEEN),
	NAME_ELEMENT(KEY_TWEN),			NAME_ELEMENT(KEY_DEL_EOL),
	NAME_ELEMENT(KEY_DEL_EOS),		NAME_ELEMENT(KEY_INS_LINE),
	NAME_ELEMENT(KEY_DEL_LINE),
	NAME_ELEMENT(KEY_VIDEOPHONE),		NAME_ELEMENT(KEY_GAMES),
	NAME_ELEMENT(KEY_ZOOMIN),		NAME_ELEMENT(KEY_ZOOMOUT),
	NAME_ELEMENT(KEY_ZOOMRESET),		NAME_ELEMENT(KEY_WORDPROCESSOR),
	NAME_ELEMENT(KEY_EDITOR),		NAME_ELEMENT(KEY_SPREADSHEET),
	NAME_ELEMENT(KEY_GRAPHICSEDITOR), 	NAME_ELEMENT(KEY_PRESENTATION),
	NAME_ELEMENT(KEY_DATABASE),		NAME_ELEMENT(KEY_NEWS),
	NAME_ELEMENT(KEY_VOICEMAIL),		NAME_ELEMENT(KEY_ADDRESSBOOK),
	NAME_ELEMENT(KEY_MESSENGER),		NAME_ELEMENT(KEY_DISPLAYTOGGLE),
#ifdef KEY_SPELLCHECK
	NAME_ELEMENT(KEY_SPELLCHECK),
#endif
#ifdef KEY_LOGOFF
	NAME_ELEMENT(KEY_LOGOFF),
#endif
#ifdef KEY_DOLLAR
	NAME_ELEMENT(KEY_DOLLAR),
#endif
#ifdef KEY_EURO
	NAME_ELEMENT(KEY_EURO),
#endif
#ifdef KEY_FRAMEBACK
	NAME_ELEMENT(KEY_FRAMEBACK),
#endif
#ifdef KEY_FRAMEFORWARD
	NAME_ELEMENT(KEY_FRAMEFORWARD),
#endif
#ifdef KEY_CONTEXT_MENU
	NAME_ELEMENT(KEY_CONTEXT_MENU),
#endif
#ifdef KEY_MEDIA_REPEAT
	NAME_ELEMENT(KEY_MEDIA_REPEAT),
#endif
#ifdef KEY_10CHANNELSUP
	NAME_ELEMENT(KEY_10CHANNELSUP),
#endif
#ifdef KEY_10CHANNELSDOWN
	NAME_ELEMENT(KEY_10CHANNELSDOWN),
#endif
#ifdef KEY_IMAGES
	NAME_ELEMENT(KEY_IMAGES),
#endif
	NAME_ELEMENT(KEY_DEL_EOL),		NAME_ELEMENT(KEY_DEL_EOS),
	NAME_ELEMENT(KEY_INS_LINE),	 	NAME_ELEMENT(KEY_DEL_LINE),
	NAME_ELEMENT(KEY_FN),			NAME_ELEMENT(KEY_FN_ESC),
	NAME_ELEMENT(KEY_FN_F1),		NAME_ELEMENT(KEY_FN_F2),
	NAME_ELEMENT(KEY_FN_F3),		NAME_ELEMENT(KEY_FN_F4),
	NAME_ELEMENT(KEY_FN_F5),		NAME_ELEMENT(KEY_FN_F6),
	NAME_ELEMENT(KEY_FN_F7),		NAME_ELEMENT(KEY_FN_F8),
	NAME_ELEMENT(KEY_FN_F9),		NAME_ELEMENT(KEY_FN_F10),
	NAME_ELEMENT(KEY_FN_F11),		NAME_ELEMENT(KEY_FN_F12),
	NAME_ELEMENT(KEY_FN_1),			NAME_ELEMENT(KEY_FN_2),
	NAME_ELEMENT(KEY_FN_D),			NAME_ELEMENT(KEY_FN_E),
	NAME_ELEMENT(KEY_FN_F),			NAME_ELEMENT(KEY_FN_S),
	NAME_ELEMENT(KEY_FN_B),
	NAME_ELEMENT(KEY_BRL_DOT1),		NAME_ELEMENT(KEY_BRL_DOT2),
	NAME_ELEMENT(KEY_BRL_DOT3),		NAME_ELEMENT(KEY_BRL_DOT4),
	NAME_ELEMENT(KEY_BRL_DOT5),		NAME_ELEMENT(KEY_BRL_DOT6),
	NAME_ELEMENT(KEY_BRL_DOT7),		NAME_ELEMENT(KEY_BRL_DOT8),
	NAME_ELEMENT(KEY_BRL_DOT9),		NAME_ELEMENT(KEY_BRL_DOT10),
#ifdef KEY_NUMERIC_0
	NAME_ELEMENT(KEY_NUMERIC_0),		NAME_ELEMENT(KEY_NUMERIC_1),
	NAME_ELEMENT(KEY_NUMERIC_2),		NAME_ELEMENT(KEY_NUMERIC_3),
	NAME_ELEMENT(KEY_NUMERIC_4),		NAME_ELEMENT(KEY_NUMERIC_5),
	NAME_ELEMENT(KEY_NUMERIC_6),		NAME_ELEMENT(KEY_NUMERIC_7),
	NAME_ELEMENT(KEY_NUMERIC_8),		NAME_ELEMENT(KEY_NUMERIC_9),
	NAME_ELEMENT(KEY_NUMERIC_STAR),		NAME_ELEMENT(KEY_NUMERIC_POUND),
#endif
#ifdef KEY_NUMERIC_11
	NAME_ELEMENT(KEY_NUMERIC_11),		NAME_ELEMENT(KEY_NUMERIC_12),
#endif
	NAME_ELEMENT(KEY_BATTERY),
	NAME_ELEMENT(KEY_BLUETOOTH),		NAME_ELEMENT(KEY_BRIGHTNESS_CYCLE),
	NAME_ELEMENT(KEY_BRIGHTNESS_ZERO),
#ifdef KEY_DASHBOARD
	NAME_ELEMENT(KEY_DASHBOARD),
#endif
	NAME_ELEMENT(KEY_DISPLAY_OFF),		NAME_ELEMENT(KEY_DOCUMENTS),
	NAME_ELEMENT(KEY_FORWARDMAIL),		NAME_ELEMENT(KEY_NEW),
	NAME_ELEMENT(KEY_KBDILLUMDOWN),		NAME_ELEMENT(KEY_KBDILLUMUP),
	NAME_ELEMENT(KEY_KBDILLUMTOGGLE), 	NAME_ELEMENT(KEY_REDO),
	NAME_ELEMENT(KEY_REPLY),		NAME_ELEMENT(KEY_SAVE),
#ifdef KEY_SCALE
	NAME_ELEMENT(KEY_SCALE),
#endif
	NAME_ELEMENT(KEY_SEND),
	NAME_ELEMENT(KEY_SCREENLOCK),		NAME_ELEMENT(KEY_SWITCHVIDEOMODE),
#ifdef KEY_UWB
	NAME_ELEMENT(KEY_UWB),
#endif
#ifdef KEY_VIDEO_NEXT
	NAME_ELEMENT(KEY_VIDEO_NEXT),
#endif
#ifdef KEY_VIDEO_PREV
	NAME_ELEMENT(KEY_VIDEO_PREV),
#endif
#ifdef KEY_WIMAX
	NAME_ELEMENT(KEY_WIMAX),
#endif
#ifdef KEY_WLAN
	NAME_ELEMENT(KEY_WLAN),
#endif
#ifdef KEY_RFKILL
	NAME_ELEMENT(KEY_RFKILL),
#endif
#ifdef KEY_MICMUTE
	NAME_ELEMENT(KEY_MICMUTE),
#endif
#ifdef KEY_CAMERA_FOCUS
	NAME_ELEMENT(KEY_CAMERA_FOCUS),
#endif
#ifdef KEY_WPS_BUTTON
	NAME_ELEMENT(KEY_WPS_BUTTON),
#endif
#ifdef KEY_TOUCHPAD_TOGGLE
	NAME_ELEMENT(KEY_TOUCHPAD_TOGGLE),
	NAME_ELEMENT(KEY_TOUCHPAD_ON),
	NAME_ELEMENT(KEY_TOUCHPAD_OFF),
#endif
#ifdef KEY_CAMERA_ZOOMIN
	NAME_ELEMENT(KEY_CAMERA_ZOOMIN),	NAME_ELEMENT(KEY_CAMERA_ZOOMOUT),
	NAME_ELEMENT(KEY_CAMERA_UP),		NAME_ELEMENT(KEY_CAMERA_DOWN),
	NAME_ELEMENT(KEY_CAMERA_LEFT),		NAME_ELEMENT(KEY_CAMERA_RIGHT),
#endif
#ifdef KEY_ATTENDANT_ON
	NAME_ELEMENT(KEY_ATTENDANT_ON),		NAME_ELEMENT(KEY_ATTENDANT_OFF),
	NAME_ELEMENT(KEY_ATTENDANT_TOGGLE),	NAME_ELEMENT(KEY_LIGHTS_TOGGLE),
#endif

	NAME_ELEMENT(BTN_0),			NAME_ELEMENT(BTN_1),
	NAME_ELEMENT(BTN_2),			NAME_ELEMENT(BTN_3),
	NAME_ELEMENT(BTN_4),			NAME_ELEMENT(BTN_5),
	NAME_ELEMENT(BTN_6),			NAME_ELEMENT(BTN_7),
	NAME_ELEMENT(BTN_8),			NAME_ELEMENT(BTN_9),
	NAME_ELEMENT(BTN_LEFT),			NAME_ELEMENT(BTN_RIGHT),
	NAME_ELEMENT(BTN_MIDDLE),		NAME_ELEMENT(BTN_SIDE),
	NAME_ELEMENT(BTN_EXTRA),		NAME_ELEMENT(BTN_FORWARD),
	NAME_ELEMENT(BTN_BACK),			NAME_ELEMENT(BTN_TASK),
	NAME_ELEMENT(BTN_TRIGGER),		NAME_ELEMENT(BTN_THUMB),
	NAME_ELEMENT(BTN_THUMB2),		NAME_ELEMENT(BTN_TOP),
	NAME_ELEMENT(BTN_TOP2),			NAME_ELEMENT(BTN_PINKIE),
	NAME_ELEMENT(BTN_BASE),			NAME_ELEMENT(BTN_BASE2),
	NAME_ELEMENT(BTN_BASE3),		NAME_ELEMENT(BTN_BASE4),
	NAME_ELEMENT(BTN_BASE5),		NAME_ELEMENT(BTN_BASE6),
	NAME_ELEMENT(BTN_DEAD),			NAME_ELEMENT(BTN_C),
#ifdef BTN_SOUTH
	NAME_ELEMENT(BTN_SOUTH),		NAME_ELEMENT(BTN_EAST),
	NAME_ELEMENT(BTN_NORTH),		NAME_ELEMENT(BTN_WEST),
#else
	NAME_ELEMENT(BTN_A),			NAME_ELEMENT(BTN_B),
	NAME_ELEMENT(BTN_X),			NAME_ELEMENT(BTN_Y),
#endif
	NAME_ELEMENT(BTN_Z),			NAME_ELEMENT(BTN_TL),
	NAME_ELEMENT(BTN_TR),			NAME_ELEMENT(BTN_TL2),
	NAME_ELEMENT(BTN_TR2),			NAME_ELEMENT(BTN_SELECT),
	NAME_ELEMENT(BTN_START),		NAME_ELEMENT(BTN_MODE),
	NAME_ELEMENT(BTN_THUMBL),		NAME_ELEMENT(BTN_THUMBR),
	NAME_ELEMENT(BTN_TOOL_PEN),		NAME_ELEMENT(BTN_TOOL_RUBBER),
	NAME_ELEMENT(BTN_TOOL_BRUSH),		NAME_ELEMENT(BTN_TOOL_PENCIL),
	NAME_ELEMENT(BTN_TOOL_AIRBRUSH),	NAME_ELEMENT(BTN_TOOL_FINGER),
	NAME_ELEMENT(BTN_TOOL_MOUSE),		NAME_ELEMENT(BTN_TOOL_LENS),
	NAME_ELEMENT(BTN_TOUCH),		NAME_ELEMENT(BTN_STYLUS),
	NAME_ELEMENT(BTN_STYLUS2),		NAME_ELEMENT(BTN_TOOL_DOUBLETAP),
	NAME_ELEMENT(BTN_TOOL_TRIPLETAP),
#ifdef BTN_TOOL_QUADTAP
	NAME_ELEMENT(BTN_TOOL_QUADTAP),
#endif
	NAME_ELEMENT(BTN_GEAR_DOWN),
	NAME_ELEMENT(BTN_GEAR_UP),

#ifdef BTN_DPAD_UP
	NAME_ELEMENT(BTN_DPAD_UP),		NAME_ELEMENT(BTN_DPAD_DOWN),
	NAME_ELEMENT(BTN_DPAD_LEFT),		NAME_ELEMENT(BTN_DPAD_RIGHT),
#endif
#ifdef KEY_ALS_TOGGLE
	NAME_ELEMENT(KEY_ALS_TOGGLE),
#endif
#ifdef KEY_BUTTONCONFIG
	NAME_ELEMENT(KEY_BUTTONCONFIG),
#endif
#ifdef KEY_TASKMANAGER
	NAME_ELEMENT(KEY_TASKMANAGER),
#endif
#ifdef KEY_JOURNAL
	NAME_ELEMENT(KEY_JOURNAL),
#endif
#ifdef KEY_CONTROLPANEL
	NAME_ELEMENT(KEY_CONTROLPANEL),
#endif
#ifdef KEY_APPSELECT
	NAME_ELEMENT(KEY_APPSELECT),
#endif
#ifdef KEY_SCREENSAVER
	NAME_ELEMENT(KEY_SCREENSAVER),
#endif
#ifdef KEY_VOICECOMMAND
	NAME_ELEMENT(KEY_VOICECOMMAND),
#endif
#ifdef KEY_ASSISTANT
	NAME_ELEMENT(KEY_ASSISTANT),
#endif
#ifdef KEY_BRIGHTNESS_MIN
	NAME_ELEMENT(KEY_BRIGHTNESS_MIN),
#endif
#ifdef KEY_BRIGHTNESS_MAX
	NAME_ELEMENT(KEY_BRIGHTNESS_MAX),
#endif
#ifdef KEY_KBDINPUTASSIST_PREV
	NAME_ELEMENT(KEY_KBDINPUTASSIST_PREV),
#endif
#ifdef KEY_KBDINPUTASSIST_NEXT
	NAME_ELEMENT(KEY_KBDINPUTASSIST_NEXT),
#endif
#ifdef KEY_KBDINPUTASSIST_PREVGROUP
	NAME_ELEMENT(KEY_KBDINPUTASSIST_PREVGROUP),
#endif
#ifdef KEY_KBDINPUTASSIST_NEXTGROUP
	NAME_ELEMENT(KEY_KBDINPUTASSIST_NEXTGROUP),
#endif
#ifdef KEY_KBDINPUTASSIST_ACCEPT
	NAME_ELEMENT(KEY_KBDINPUTASSIST_ACCEPT),
#endif
#ifdef KEY_KBDINPUTASSIST_CANCEL
	NAME_ELEMENT(KEY_KBDINPUTASSIST_CANCEL),
#endif

#ifdef KEY_RIGHT_UP
	NAME_ELEMENT(KEY_RIGHT_UP),		NAME_ELEMENT(KEY_RIGHT_DOWN),
	NAME_ELEMENT(KEY_LEFT_UP),		NAME_ELEMENT(KEY_LEFT_DOWN),
#endif

#ifdef KEY_ROOT_MENU
	NAME_ELEMENT(KEY_ROOT_MENU),
	NAME_ELEMENT(KEY_MEDIA_TOP_MENU),
	NAME_ELEMENT(KEY_AUDIO_DESC),
	NAME_ELEMENT(KEY_3D_MODE),
	NAME_ELEMENT(KEY_NEXT_FAVORITE),
	NAME_ELEMENT(KEY_STOP_RECORD),
	NAME_ELEMENT(KEY_PAUSE_RECORD),
	NAME_ELEMENT(KEY_VOD),
	NAME_ELEMENT(KEY_UNMUTE),
	NAME_ELEMENT(KEY_FASTREVERSE),
	NAME_ELEMENT(KEY_SLOWREVERSE),
#endif

#ifdef KEY_DATA
	NAME_ELEMENT(KEY_DATA),
#endif

#ifdef KEY_ONSCREEN_KEYBOARD
	NAME_ELEMENT(KEY_ONSCREEN_KEYBOARD),
#endif

#ifdef BTN_TRIGGER_HAPPY
	NAME_ELEMENT(BTN_TRIGGER_HAPPY1),	NAME_ELEMENT(BTN_TRIGGER_HAPPY11),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY2),	NAME_ELEMENT(BTN_TRIGGER_HAPPY12),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY3),	NAME_ELEMENT(BTN_TRIGGER_HAPPY13),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY4),	NAME_ELEMENT(BTN_TRIGGER_HAPPY14),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY5),	NAME_ELEMENT(BTN_TRIGGER_HAPPY15),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY6),	NAME_ELEMENT(BTN_TRIGGER_HAPPY16),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY7),	NAME_ELEMENT(BTN_TRIGGER_HAPPY17),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY8),	NAME_ELEMENT(BTN_TRIGGER_HAPPY18),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY9),	NAME_ELEMENT(BTN_TRIGGER_HAPPY19),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY10),	NAME_ELEMENT(BTN_TRIGGER_HAPPY20),

	NAME_ELEMENT(BTN_TRIGGER_HAPPY21),	NAME_ELEMENT(BTN_TRIGGER_HAPPY31),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY22),	NAME_ELEMENT(BTN_TRIGGER_HAPPY32),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY23),	NAME_ELEMENT(BTN_TRIGGER_HAPPY33),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY24),	NAME_ELEMENT(BTN_TRIGGER_HAPPY34),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY25),	NAME_ELEMENT(BTN_TRIGGER_HAPPY35),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY26),	NAME_ELEMENT(BTN_TRIGGER_HAPPY36),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY27),	NAME_ELEMENT(BTN_TRIGGER_HAPPY37),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY28),	NAME_ELEMENT(BTN_TRIGGER_HAPPY38),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY29),	NAME_ELEMENT(BTN_TRIGGER_HAPPY39),
	NAME_ELEMENT(BTN_TRIGGER_HAPPY30),	NAME_ELEMENT(BTN_TRIGGER_HAPPY40),
#endif
#ifdef BTN_TOOL_QUINTTAP
	NAME_ELEMENT(BTN_TOOL_QUINTTAP),
#endif
};

static const char * const absval[6] = { "Value", "Min  ", "Max  ", "Fuzz ", "Flat ", "Resolution "};

static const char * const relatives[REL_MAX + 1] = {
	[0 ... REL_MAX] = NULL,
	NAME_ELEMENT(REL_X),			NAME_ELEMENT(REL_Y),
	NAME_ELEMENT(REL_Z),			NAME_ELEMENT(REL_RX),
	NAME_ELEMENT(REL_RY),			NAME_ELEMENT(REL_RZ),
	NAME_ELEMENT(REL_HWHEEL),
	NAME_ELEMENT(REL_DIAL),			NAME_ELEMENT(REL_WHEEL),
	NAME_ELEMENT(REL_MISC),
#ifdef REL_WHEEL_HI_RES
	NAME_ELEMENT(REL_WHEEL_HI_RES),
	NAME_ELEMENT(REL_HWHEEL_HI_RES),
#endif
};

static const char * const absolutes[ABS_MAX + 1] = {
	[0 ... ABS_MAX] = NULL,
	NAME_ELEMENT(ABS_X),			NAME_ELEMENT(ABS_Y),
	NAME_ELEMENT(ABS_Z),			NAME_ELEMENT(ABS_RX),
	NAME_ELEMENT(ABS_RY),			NAME_ELEMENT(ABS_RZ),
	NAME_ELEMENT(ABS_THROTTLE),		NAME_ELEMENT(ABS_RUDDER),
	NAME_ELEMENT(ABS_WHEEL),		NAME_ELEMENT(ABS_GAS),
	NAME_ELEMENT(ABS_BRAKE),		NAME_ELEMENT(ABS_HAT0X),
	NAME_ELEMENT(ABS_HAT0Y),		NAME_ELEMENT(ABS_HAT1X),
	NAME_ELEMENT(ABS_HAT1Y),		NAME_ELEMENT(ABS_HAT2X),
	NAME_ELEMENT(ABS_HAT2Y),		NAME_ELEMENT(ABS_HAT3X),
	NAME_ELEMENT(ABS_HAT3Y),		NAME_ELEMENT(ABS_PRESSURE),
	NAME_ELEMENT(ABS_DISTANCE),		NAME_ELEMENT(ABS_TILT_X),
	NAME_ELEMENT(ABS_TILT_Y),		NAME_ELEMENT(ABS_TOOL_WIDTH),
	NAME_ELEMENT(ABS_VOLUME),		NAME_ELEMENT(ABS_MISC),
#ifdef ABS_MT_BLOB_ID
	NAME_ELEMENT(ABS_MT_TOUCH_MAJOR),
	NAME_ELEMENT(ABS_MT_TOUCH_MINOR),
	NAME_ELEMENT(ABS_MT_WIDTH_MAJOR),
	NAME_ELEMENT(ABS_MT_WIDTH_MINOR),
	NAME_ELEMENT(ABS_MT_ORIENTATION),
	NAME_ELEMENT(ABS_MT_POSITION_X),
	NAME_ELEMENT(ABS_MT_POSITION_Y),
	NAME_ELEMENT(ABS_MT_TOOL_TYPE),
	NAME_ELEMENT(ABS_MT_BLOB_ID),
#endif
#ifdef ABS_MT_TRACKING_ID
	NAME_ELEMENT(ABS_MT_TRACKING_ID),
#endif
#ifdef ABS_MT_PRESSURE
	NAME_ELEMENT(ABS_MT_PRESSURE),
#endif
#ifdef ABS_MT_SLOT
	NAME_ELEMENT(ABS_MT_SLOT),
#endif
#ifdef ABS_MT_TOOL_X
	NAME_ELEMENT(ABS_MT_TOOL_X),
	NAME_ELEMENT(ABS_MT_TOOL_Y),
	NAME_ELEMENT(ABS_MT_DISTANCE),
#endif

};

static const char * const misc[MSC_MAX + 1] = {
	[ 0 ... MSC_MAX] = NULL,
	NAME_ELEMENT(MSC_SERIAL),		NAME_ELEMENT(MSC_PULSELED),
	NAME_ELEMENT(MSC_GESTURE),		NAME_ELEMENT(MSC_RAW),
	NAME_ELEMENT(MSC_SCAN),
#ifdef MSC_TIMESTAMP
	NAME_ELEMENT(MSC_TIMESTAMP),
#endif
};

static const char * const leds[LED_MAX + 1] = {
	[0 ... LED_MAX] = NULL,
	NAME_ELEMENT(LED_NUML),			NAME_ELEMENT(LED_CAPSL),
	NAME_ELEMENT(LED_SCROLLL),		NAME_ELEMENT(LED_COMPOSE),
	NAME_ELEMENT(LED_KANA),			NAME_ELEMENT(LED_SLEEP),
	NAME_ELEMENT(LED_SUSPEND),		NAME_ELEMENT(LED_MUTE),
	NAME_ELEMENT(LED_MISC),
#ifdef LED_MAIL
	NAME_ELEMENT(LED_MAIL),
#endif
#ifdef LED_CHARGING
	NAME_ELEMENT(LED_CHARGING),
#endif
};

static const char * const repeats[REP_MAX + 1] = {
	[0 ... REP_MAX] = NULL,
	NAME_ELEMENT(REP_DELAY),		NAME_ELEMENT(REP_PERIOD)
};

static const char * const sounds[SND_MAX + 1] = {
	[0 ... SND_MAX] = NULL,
	NAME_ELEMENT(SND_CLICK),		NAME_ELEMENT(SND_BELL),
	NAME_ELEMENT(SND_TONE)
};

static const char * const syns[SYN_MAX + 1] = {
	[0 ... SYN_MAX] = NULL,
	NAME_ELEMENT(SYN_REPORT),
	NAME_ELEMENT(SYN_CONFIG),
	NAME_ELEMENT(SYN_MT_REPORT),
	NAME_ELEMENT(SYN_DROPPED)
};

static const char * const switches[SW_MAX + 1] = {
	[0 ... SW_MAX] = NULL,
	NAME_ELEMENT(SW_LID),
	NAME_ELEMENT(SW_TABLET_MODE),
	NAME_ELEMENT(SW_HEADPHONE_INSERT),
#ifdef SW_RFKILL_ALL
	NAME_ELEMENT(SW_RFKILL_ALL),
#endif
#ifdef SW_MICROPHONE_INSERT
	NAME_ELEMENT(SW_MICROPHONE_INSERT),
#endif
#ifdef SW_DOCK
	NAME_ELEMENT(SW_DOCK),
#endif
#ifdef SW_LINEOUT_INSERT
	NAME_ELEMENT(SW_LINEOUT_INSERT),
#endif
#ifdef SW_JACK_PHYSICAL_INSERT
	NAME_ELEMENT(SW_JACK_PHYSICAL_INSERT),
#endif
#ifdef SW_VIDEOOUT_INSERT
	NAME_ELEMENT(SW_VIDEOOUT_INSERT),
#endif
#ifdef SW_CAMERA_LENS_COVER
	NAME_ELEMENT(SW_CAMERA_LENS_COVER),
	NAME_ELEMENT(SW_KEYPAD_SLIDE),
	NAME_ELEMENT(SW_FRONT_PROXIMITY),
#endif
#ifdef SW_ROTATE_LOCK
	NAME_ELEMENT(SW_ROTATE_LOCK),
#endif
#ifdef SW_LINEIN_INSERT
	NAME_ELEMENT(SW_LINEIN_INSERT),
#endif
#ifdef SW_MUTE_DEVICE
	NAME_ELEMENT(SW_MUTE_DEVICE),
#endif
#ifdef SW_PEN_INSERTED
	NAME_ELEMENT(SW_PEN_INSERTED),
#endif
};

static const char * const force[FF_MAX + 1] = {
	[0 ... FF_MAX] = NULL,
	NAME_ELEMENT(FF_RUMBLE),		NAME_ELEMENT(FF_PERIODIC),
	NAME_ELEMENT(FF_CONSTANT),		NAME_ELEMENT(FF_SPRING),
	NAME_ELEMENT(FF_FRICTION),		NAME_ELEMENT(FF_DAMPER),
	NAME_ELEMENT(FF_INERTIA),		NAME_ELEMENT(FF_RAMP),
	NAME_ELEMENT(FF_SQUARE),		NAME_ELEMENT(FF_TRIANGLE),
	NAME_ELEMENT(FF_SINE),			NAME_ELEMENT(FF_SAW_UP),
	NAME_ELEMENT(FF_SAW_DOWN),		NAME_ELEMENT(FF_CUSTOM),
	NAME_ELEMENT(FF_GAIN),			NAME_ELEMENT(FF_AUTOCENTER),
};

static const char * const forcestatus[FF_STATUS_MAX + 1] = {
	[0 ... FF_STATUS_MAX] = NULL,
	NAME_ELEMENT(FF_STATUS_STOPPED),	NAME_ELEMENT(FF_STATUS_PLAYING),
};

static const char * const * const names[EV_MAX + 1] = {
	[0 ... EV_MAX] = NULL,
	[EV_SYN] = syns,			[EV_KEY] = keys,
	[EV_REL] = relatives,			[EV_ABS] = absolutes,
	[EV_MSC] = misc,			[EV_LED] = leds,
	[EV_SND] = sounds,			[EV_REP] = repeats,
	[EV_SW] = switches,
	[EV_FF] = force,			[EV_FF_STATUS] = forcestatus,
};

/**
 * Convert a string to a specific key/snd/led/sw code. The string can either
 * be the name of the key in question (e.g. "SW_DOCK") or the numerical
 * value, either as decimal (e.g. "5") or as hex (e.g. "0x5").
 *
 * @param mode The mode being queried (key, snd, led, sw)
 * @param kstr The string to parse and convert
 *
 * @return The requested code's numerical value, or negative on error.
 */
static int get_keycode(const struct query_mode *query_mode, const char *kstr)
{
	if (isdigit(kstr[0])) {
		unsigned long val;
		errno = 0;
		val = strtoul(kstr, NULL, 0);
		if (errno) {
			fprintf(stderr, "Could not interpret value %s\n", kstr);
			return -1;
		}
		return (int) val;
	} else {
		const char * const *keynames = names[query_mode->event_type];
		int i;

		for (i = 0; i < query_mode->max; i++) {
			const char *name = keynames[i];
			if (name && strcmp(name, kstr) == 0)
				return i;
		}

		return -1;
	}
}

/**
 * Filter for the AutoDevProbe scandir on /dev/input.
 *
 * @param dir The current directory entry provided by scandir.
 *
 * @return Non-zero if the given directory entry starts with "event", or zero
 * otherwise.
 */
static int is_event_device(const struct dirent *dir) {
	return strncmp(EVENT_DEV_NAME, dir->d_name, 5) == 0;
}

/**
 * Scans all /dev/input/event*, display them and ask the user which one to
 * open.
 *
 * @return The event device file name of the device file selected. This
 * string is allocated and must be freed by the caller.
 */
static char* scan_devices(void)
{
	struct dirent **namelist;
	int i, ndev, devnum, match;
	char *filename;
	int max_device = 0;

	ndev = scandir(DEV_INPUT_EVENT, &namelist, is_event_device, versionsort);
	if (ndev <= 0)
		return NULL;

	fprintf(stderr, "Available devices:\n");

	for (i = 0; i < ndev; i++)
	{
		char fname[PATH_MAX];
		int fd = -1;
		char name[256] = "???";

		snprintf(fname, sizeof(fname),
			 "%s/%s", DEV_INPUT_EVENT, namelist[i]->d_name);
		fd = open(fname, O_RDONLY);
		if (fd < 0)
			continue;
		ioctl(fd, EVIOCGNAME(sizeof(name)), name);

		fprintf(stderr, "%s:	%s\n", fname, name);
		close(fd);

		match = sscanf(namelist[i]->d_name, "event%d", &devnum);
		if (match >= 1 && devnum > max_device)
			max_device = devnum;

		free(namelist[i]);
	}

	fprintf(stderr, "Select the device event number [0-%d]: ", max_device);

	match = scanf("%d", &devnum);
	if (match < 1 || devnum > max_device || devnum < 0)
		return NULL;

	if (asprintf(&filename, "%s/%s%d",
		     DEV_INPUT_EVENT, EVENT_DEV_NAME,
		     devnum) < 0)
		return NULL;

	return filename;
}

static int version(void)
{
#ifndef PACKAGE_VERSION
#define PACKAGE_VERSION "<version undefined>"
#endif
	printf("%s %s\n", program_invocation_short_name, PACKAGE_VERSION);
	return EXIT_SUCCESS;
}


/**
 * Print usage information.
 */
static int usage(void)
{
	printf("USAGE:\n");
	printf(" Capture mode:\n");
	printf("   %s [--grab] /dev/input/eventX\n", program_invocation_short_name);
	printf("     --grab  grab the device for exclusive access\n");
	printf("\n");
	printf(" Query mode: (check exit code)\n");
	printf("   %s --query /dev/input/eventX <type> <value>\n",
		program_invocation_short_name);

	printf("\n");
	printf("<type> is one of: EV_KEY, EV_SW, EV_LED, EV_SND\n");
	printf("<value> can either be a numerical value, or the textual name of the\n");
	printf("key/switch/LED/sound being queried (e.g. SW_DOCK).\n");

	return EXIT_FAILURE;
}

/**
 * Print additional information for absolute axes (min/max, current value,
 * etc.).
 *
 * @param fd The file descriptor to the device.
 * @param axis The axis identifier (e.g. ABS_X).
 */
static void print_absdata(int fd, int axis)
{
	int abs[6] = {0};
	int k;

	ioctl(fd, EVIOCGABS(axis), abs);
	for (k = 0; k < 6; k++)
		if ((k < 3) || abs[k])
			printf("      %s %6d\n", absval[k], abs[k]);
}

static void print_repdata(int fd)
{
	int i;
	unsigned int rep[2];

	ioctl(fd, EVIOCGREP, rep);

	for (i = 0; i <= REP_MAX; i++) {
		printf("    Repeat code %d (%s)\n", i, names[EV_REP] ? (names[EV_REP][i] ? names[EV_REP][i] : "?") : "?");
		printf("      Value %6d\n", rep[i]);
	}

}

static inline const char* typename(unsigned int type)
{
	return (type <= EV_MAX && events[type]) ? events[type] : "?";
}

static inline const char* codename(unsigned int type, unsigned int code)
{
	return (type <= EV_MAX && code <= maxval[type] && names[type] && names[type][code]) ? names[type][code] : "?";
}

#ifdef INPUT_PROP_SEMI_MT
static inline const char* propname(unsigned int prop)
{
	return (prop <= INPUT_PROP_MAX && props[prop]) ? props[prop] : "?";
}
#endif

static int get_state(int fd, unsigned int type, unsigned long *array, size_t size)
{
	int rc;

	switch(type) {
	case EV_LED:
		rc = ioctl(fd, EVIOCGLED(size), array);
		break;
	case EV_SND:
		rc = ioctl(fd, EVIOCGSND(size), array);
		break;
	case EV_SW:
		rc = ioctl(fd, EVIOCGSW(size), array);
		break;
	case EV_KEY:
		/* intentionally not printing the value for EV_KEY, let the
		 * repeat handle this */
	default:
		return 1;
	}
	if (rc == -1)
		return 1;

	return 0;
}

/**
 * Print static device information (no events). This information includes
 * version numbers, device name and all bits supported by this device.
 *
 * @param fd The file descriptor to the device.
 * @return 0 on success or 1 otherwise.
 */
static int print_device_info(int fd)
{
	unsigned int type, code;
	int version;
	unsigned short id[4];
	char name[256] = "Unknown";
	unsigned long bit[EV_MAX][NBITS(KEY_MAX)];
	unsigned long state[KEY_CNT] = {0};
#ifdef INPUT_PROP_SEMI_MT
	unsigned int prop;
	unsigned long propbits[INPUT_PROP_MAX];
#endif
	int stateval;
	int have_state;

	if (ioctl(fd, EVIOCGVERSION, &version)) {
		perror("evtest: can't get version");
		return 1;
	}

	printf("Input driver version is %d.%d.%d\n",
		version >> 16, (version >> 8) & 0xff, version & 0xff);

	ioctl(fd, EVIOCGID, id);
	printf("Input device ID: bus 0x%x vendor 0x%x product 0x%x version 0x%x\n",
		id[ID_BUS], id[ID_VENDOR], id[ID_PRODUCT], id[ID_VERSION]);

	ioctl(fd, EVIOCGNAME(sizeof(name)), name);
	printf("Input device name: \"%s\"\n", name);

	memset(bit, 0, sizeof(bit));
	ioctl(fd, EVIOCGBIT(0, EV_MAX), bit[0]);
	printf("Supported events:\n");

	for (type = 0; type < EV_MAX; type++) {
		if (test_bit(type, bit[0]) && type != EV_REP) {
			have_state = (get_state(fd, type, state, sizeof(state)) == 0);

			printf("  Event type %d (%s)\n", type, typename(type));
			if (type == EV_SYN) continue;
			ioctl(fd, EVIOCGBIT(type, KEY_MAX), bit[type]);
			for (code = 0; code < KEY_MAX; code++)
				if (test_bit(code, bit[type])) {
					if (have_state) {
						stateval = test_bit(code, state);
						printf("    Event code %d (%s) state %d\n",
						       code, codename(type, code), stateval);
					} else {
						printf("    Event code %d (%s)\n", code, codename(type, code));
					}
					if (type == EV_ABS)
						print_absdata(fd, code);
				}
		}
	}

	if (test_bit(EV_REP, bit[0])) {
		printf("Key repeat handling:\n");
		printf("  Repeat type %d (%s)\n", EV_REP, events[EV_REP] ?  events[EV_REP] : "?");
		print_repdata(fd);
	}
#ifdef INPUT_PROP_SEMI_MT
	memset(propbits, 0, sizeof(propbits));
	ioctl(fd, EVIOCGPROP(sizeof(propbits)), propbits);
	printf("Properties:\n");
	for (prop = 0; prop < INPUT_PROP_MAX; prop++) {
		if (test_bit(prop, propbits))
			printf("  Property type %d (%s)\n", prop, propname(prop));
	}
#endif

	return 0;
}

/**
 * Print device events as they come in.
 *
 * @param fd The file descriptor to the device.
 * @return 0 on success or 1 otherwise.
 */
static int print_events(int fd)
{
	struct input_event ev[64];
	int i, rd;
	fd_set rdfs;

	FD_ZERO(&rdfs);
	FD_SET(fd, &rdfs);

	while (!stop) {
		select(fd + 1, &rdfs, NULL, NULL, NULL);
		if (stop)
			break;
		rd = read(fd, ev, sizeof(ev));

		if (rd < (int) sizeof(struct input_event)) {
			printf("expected %d bytes, got %d\n", (int) sizeof(struct input_event), rd);
			perror("\nevtest: error reading");
			return 1;
		}

		for (i = 0; i < rd / sizeof(struct input_event); i++) {
			unsigned int type, code;

			type = ev[i].type;
			code = ev[i].code;

			printf("Event: time %ld.%06ld, ", ev[i].input_event_sec, ev[i].input_event_usec);

			if (type == EV_SYN) {
				if (code == SYN_MT_REPORT)
					printf("++++++++++++++ %s ++++++++++++\n", codename(type, code));
				else if (code == SYN_DROPPED)
					printf(">>>>>>>>>>>>>> %s <<<<<<<<<<<<\n", codename(type, code));
				else
					printf("-------------- %s ------------\n", codename(type, code));
			} else {
				printf("type %d (%s), code %d (%s), ",
					type, typename(type),
					code, codename(type, code));
				if (type == EV_MSC && (code == MSC_RAW || code == MSC_SCAN))
					printf("value %02x\n", ev[i].value);
				else
					printf("value %d\n", ev[i].value);
			}
		}

	}

	ioctl(fd, EVIOCGRAB, (void*)0);
	return EXIT_SUCCESS;
}

/**
 * Grab and immediately ungrab the device.
 *
 * @param fd The file descriptor to the device.
 * @return 0 if the grab was successful, or 1 otherwise.
 */
static int test_grab(int fd, int grab_flag)
{
	int rc;

	rc = ioctl(fd, EVIOCGRAB, (void*)1);

	if (rc == 0 && !grab_flag)
		ioctl(fd, EVIOCGRAB, (void*)0);

	return rc;
}

/**
 * Enter capture mode. The requested event device will be monitored, and any
 * captured events will be decoded and printed on the console.
 *
 * @param device The device to monitor, or NULL if the user should be prompted.
 * @return 0 on success, non-zero on error.
 */
static int do_capture(const char *device, int grab_flag)
{
	int fd;
	char *filename = NULL;

	if (!device) {
		fprintf(stderr, "No device specified, trying to scan all of %s/%s*\n",
			DEV_INPUT_EVENT, EVENT_DEV_NAME);

		if (getuid() != 0)
			fprintf(stderr, "Not running as root, no devices may be available.\n");

		filename = scan_devices();
		if (!filename)
			return usage();
	} else
		filename = strdup(device);

	if (!filename)
		return EXIT_FAILURE;

	if ((fd = open(filename, O_RDONLY)) < 0) {
		perror("evtest");
		if (errno == EACCES && getuid() != 0)
			fprintf(stderr, "You do not have access to %s. Try "
					"running as root instead.\n",
					filename);
		goto error;
	}

	if (!isatty(fileno(stdout)))
		setbuf(stdout, NULL);

	if (print_device_info(fd))
		goto error;

	printf("Testing ... (interrupt to exit)\n");

	if (test_grab(fd, grab_flag))
	{
		printf("***********************************************\n");
		printf("  This device is grabbed by another process.\n");
		printf("  No events are available to evtest while the\n"
		       "  other grab is active.\n");
		printf("  In most cases, this is caused by an X driver,\n"
		       "  try VT-switching and re-run evtest again.\n");
		printf("  Run the following command to see processes with\n"
		       "  an open fd on this device\n"
		       " \"fuser -v %s\"\n", filename);
		printf("***********************************************\n");
	}

	signal(SIGINT, interrupt_handler);
	signal(SIGTERM, interrupt_handler);

	free(filename);

	return print_events(fd);

error:
	free(filename);
	return EXIT_FAILURE;
}

/**
 * Perform a one-shot state query on a specific device. The query can be of
 * any known mode, on any valid keycode.
 *
 * @param device Path to the evdev device node that should be queried.
 * @param query_mode The event type that is being queried (e.g. key, switch)
 * @param keycode The code of the key/switch/sound/LED to be queried
 * @return 0 if the state bit is unset, 10 if the state bit is set, 1 on error.
 */
static int query_device(const char *device, const struct query_mode *query_mode, int keycode)
{
	int fd;
	int r;
	unsigned long state[NBITS(query_mode->max)];

	fd = open(device, O_RDONLY);
	if (fd < 0) {
		perror("open");
		return EXIT_FAILURE;
	}
	memset(state, 0, sizeof(state));
	r = ioctl(fd, query_mode->rq, state);
	close(fd);

	if (r == -1) {
		perror("ioctl");
		return EXIT_FAILURE;
	}

	if (test_bit(keycode, state))
		return 10; /* different from EXIT_FAILURE */
	else
		return 0;
}

/**
 * Enter query mode. The requested event device will be queried for the state
 * of a particular switch/key/sound/LED.
 *
 * @param device The device to query.
 * @param mode The mode (event type) that is to be queried (snd, sw, key, led)
 * @param keycode The key code to query the state of.
 * @return 0 if the state bit is unset, 10 if the state bit is set.
 */
static int do_query(const char *device, const char *event_type, const char *keyname)
{
	const struct query_mode *query_mode;
	int keycode;

	if (!device) {
		fprintf(stderr, "Device argument is required for query.\n");
		return usage();
	}

	query_mode = find_query_mode(event_type);
	if (!query_mode) {
		fprintf(stderr, "Unrecognised event type: %s\n", event_type);
		return usage();
	}

	keycode = get_keycode(query_mode, keyname);
	if (keycode < 0) {
		fprintf(stderr, "Unrecognised key name: %s\n", keyname);
		return usage();
	} else if (keycode > query_mode->max) {
		fprintf(stderr, "Key %d is out of bounds.\n", keycode);
		return EXIT_FAILURE;
	}

	return query_device(device, query_mode, keycode);
}

static const struct option long_options[] = {
	{ "grab", no_argument, &grab_flag, 1 },
	{ "query", no_argument, NULL, MODE_QUERY },
	{ "version", no_argument, NULL, MODE_VERSION },
	{ 0, },
};

int main (int argc, char **argv)
{
	const char *device = NULL;
	const char *keyname;
	const char *event_type;
	enum evtest_mode mode = MODE_CAPTURE;

	while (1) {
		int option_index = 0;
		int c = getopt_long(argc, argv, "", long_options, &option_index);
		if (c == -1)
			break;
		switch (c) {
		case 0:
			break;
		case MODE_QUERY:
			mode = c;
			break;
		case MODE_VERSION:
			return version();
		default:
			return usage();
		}
	}

	if (optind < argc)
		device = argv[optind++];

	if (mode == MODE_CAPTURE)
		return do_capture(device, grab_flag);

	if ((argc - optind) < 2) {
		fprintf(stderr, "Query mode requires device, type and key parameters\n");
		return usage();
	}

	event_type = argv[optind++];
	keyname = argv[optind++];
	return do_query(device, event_type, keyname);
}

/* vim: set noexpandtab tabstop=8 shiftwidth=8: */
