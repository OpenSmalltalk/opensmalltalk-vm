/*
	skyeye_lcd_gtk.c - LCD display emulation in an X window.
	ARMulator extensions for the ARM7100 family.
	Copyright (C) 1999  Ben Williamson

	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/*
 * 1999			Written by Ben Williamson
 * 2004 - 2007		Modified by chy, zy, ywc, etc.
 * 04/13/2007		Modified for multi-devs by Anthony Lee
 */

#include "skyeye_lcd.h"

#include <gdk/gdk.h>
#include <gtk/gtk.h>

extern unsigned int Pen_buffer[8];

typedef struct SkyEyeLCD_GTK {
	int width;
	int virtual_width;
	int height;
	int depth;

	GdkRectangle update_rect;
	gboolean update_all;

	guchar *rgbbuf;
	guint32 *fbmem;
	GdkRgbCmap *colormap;
	guint timer;

	GtkWidget *window;
	GtkWidget *drawing;

	struct lcd_device *dev;
} SkyEyeLCD_GTK;

static guint32 colors1b[2] = {
	0x000000, 0xffffff
};
static guint32 colors4b[16] = {
	0x000000, 0x000080, 0x008000, 0x008080, 0x800000, 0x800080, 0x808000, 0x808080,
	0xc0c0c0, 0x0000ff, 0x00ff00, 0x00ffff, 0xff0000, 0xff00ff, 0xffff00, 0xffffff
};
static guint32 colors8b[256];


static void lcd_convert_callback(u32 c, u32 **buf_addr, void *noused)
{
	/* the gtk's 32 bits rgb buffer : X-B-G-R */
	*(*buf_addr) = ((c >> 16) | (c & 0xff00) | ((c & 0xff) << 16));
	*buf_addr = ++(*buf_addr);
}


/* use rgbbuf */
static gint callback_expose_event(GtkWidget *widget, GdkEventExpose *event, SkyEyeLCD_GTK *lcd)
{
	int i, j, x, y, pix, bit;

	int wordnum;		//for lcd_depth==16 , 1 word contain 2 pixel
	guint32 fbdata;		// |R1,G1,B1,R0,G0,B0|

	int tribytenum;		//for lcd_depth==12, 3 byte contain 2 pixel
	guchar fbdata8_0;	// |G0,R0|
	guchar fbdata8_1;	// |R1,B0|
	guchar fbdata8_2;	// |B1,G1|

	GdkRectangle rect;

	if (lcd == NULL || lcd->dev == NULL) return FALSE;

	if (lcd->update_all == FALSE) {
		if (lcd->update_rect.width < 0 || lcd->update_rect.height < 0) return TRUE;

		rect = lcd->update_rect;
		rect.width += 1;
		rect.height += 1;

		lcd->update_rect.x = 0;
		lcd->update_rect.y = 0;
		lcd->update_rect.width = -1;
		lcd->update_rect.height = -1;
	} else {
		rect.x = 0;
		rect.y = 0;
		rect.width = lcd->width;
		rect.height = lcd->height;
	}

	wordnum = lcd->virtual_width * rect.height * lcd->depth / 32;
	tribytenum = lcd->virtual_width * rect.height * lcd->depth / 24;

	// anthonylee 2007-01-29 : for lcd_lookup_color
	if (lcd->dev->lcd_lookup_color != NULL) {
		u32 *tmp = (u32*)lcd->rgbbuf + rect.y * lcd->width;
		skyeye_convert_color_from_lcd_dma(lcd->dev,
						  0, rect.y, lcd->width, rect.height,
						  (void (*)(u32, void*, void*))lcd_convert_callback,
						  &tmp, NULL);
		gdk_draw_rgb_32_image(widget->window,
				      widget->style->fg_gc[GTK_STATE_NORMAL],
				      0, rect.y, lcd->width, rect.height,
				      GDK_RGB_DITHER_NORMAL,
				      (guchar*)((u32*)lcd->rgbbuf + rect.y * lcd->width),
				      lcd->width * 4);
	} else switch (lcd->depth) {
		case 1:
//		case 2:
		case 4:
			// anthonylee 2007-01-28
			for (j = rect.y; j < lcd->height; j++)
			{
				guchar *buf = (guchar*)lcd->fbmem + j * lcd->virtual_width * lcd->depth / 8;

				for (i = 0; i < lcd->width;) {
					int k;
					guchar c = *buf++;
					guchar *tmp = (guchar*)lcd->rgbbuf + j * lcd->virtual_width + i;

					for (k = 0; k < 8 / lcd->depth; k++, i++, tmp++)
						*tmp = (c >> (8 - ((k + 1) << (lcd->depth - 1)))) &
						       ((1 << lcd->depth) - 1);
				}
			}
			gdk_draw_indexed_image(widget->window,
					       widget->style->fg_gc[GTK_STATE_NORMAL],
					       0, rect.y, lcd->width, rect.height,
					       GDK_RGB_DITHER_NORMAL,
					       (guchar*)lcd->rgbbuf + rect.y * lcd->virtual_width * lcd->depth / 8,
					       lcd->virtual_width, lcd->colormap);
			break;

		case 8:
			gdk_draw_indexed_image(widget->window,
					       widget->style->fg_gc[GTK_STATE_NORMAL],
					       0, rect.y, lcd->width, rect.height,
					       GDK_RGB_DITHER_NORMAL,
					       (guchar*)lcd->rgbbuf + rect.y * lcd->virtual_width,
					       lcd->virtual_width, lcd->colormap);
			break;

		case 12:
			for (i = lcd->virtual_width * rect.y / 2; i < tribytenum; i++) {
				fbdata8_0 = *((guchar*)lcd->fbmem + i * 3);
				fbdata8_1 = *((guchar*)lcd->fbmem + i * 3 + 1);
				fbdata8_2 = *((guchar*)lcd->fbmem + i * 3 + 2);
				*(lcd->rgbbuf + i * 6 + 0) = (fbdata8_0 & 0x0f) << 4;
				*(lcd->rgbbuf + i * 6 + 1) = (fbdata8_0 & 0xf0);
				*(lcd->rgbbuf + i * 6 + 2) = (fbdata8_1 & 0x0f) << 4;
				*(lcd->rgbbuf + i * 6 + 3) = (fbdata8_1 & 0xf0);
				*(lcd->rgbbuf + i * 6 + 4) = (fbdata8_2 & 0x0f) << 4;
				*(lcd->rgbbuf + i * 6 + 5) = (fbdata8_2 & 0xf0);
			}
			gdk_draw_rgb_image(widget->window,
					   widget->style->fg_gc[GTK_STATE_NORMAL],
					   0, rect.y, lcd->width, rect.height,
					   GDK_RGB_DITHER_MAX,
					   (guchar*)lcd->rgbbuf + rect.y * lcd->virtual_width * 3,
					   lcd->virtual_width * 3);
			break;

		case 16:
			for (i = lcd->virtual_width * rect.y / 2; i < wordnum; i++) {
				fbdata = *((guint32*)lcd->fbmem + i);

				*(lcd->rgbbuf + i * 6 + 0) =
					(guchar)((fbdata & 0x0000f800) >> 8);
				*(lcd->rgbbuf + i * 6 + 1) =
					(guchar)((fbdata & 0x000007e0) >> 3);
				*(lcd->rgbbuf + i * 6 + 2) =
					(guchar)((fbdata & 0x0000001f) << 3);
				*(lcd->rgbbuf + i * 6 + 3) =
					(guchar)((fbdata & 0xf8000000) >> 24);
				*(lcd->rgbbuf + i * 6 + 4) =
					(guchar)((fbdata & 0x07e00000) >> 19);
				*(lcd->rgbbuf + i * 6 + 5) =
					(guchar)((fbdata & 0x001f0000) >> 13);
			}
			gdk_draw_rgb_image(widget->window,
					   widget->style->fg_gc[GTK_STATE_NORMAL],
					   0, rect.y, lcd->width, rect.height,
					   GDK_RGB_DITHER_MAX,
					   (guchar*)lcd->rgbbuf + rect.y * lcd->virtual_width * 3,
					   lcd->virtual_width * 3);
			break;

		case 24:
			gdk_draw_rgb_image(widget->window,
					   widget->style->fg_gc[GTK_STATE_NORMAL],
					   0, rect.y, lcd->width, rect.height,
					   GDK_RGB_DITHER_NORMAL,
					   (guchar*)lcd->rgbbuf + rect.y * lcd->virtual_width * 3,
					   lcd->virtual_width * 3);
			break;

		case 32:
			gdk_draw_rgb_32_image(widget->window,
					      widget->style->fg_gc[GTK_STATE_NORMAL],
					      0, rect.y, lcd->width, rect.height,
					      GDK_RGB_DITHER_NORMAL,
					      (guchar*)((u32*)lcd->rgbbuf + rect.y * lcd->virtual_width),
					      lcd->virtual_width * 4);
			break;

		default:
			break;
	}

	return TRUE;
}


//********** touch srceen event callback funtion by ywc ************
static void skPenEvent(int *buffer, int eventType, int stateType, int x, int y)
{
//      printf("\nSkyEye: skPenEvent():event type=%d\n(x=%d,y=%d)\n",down,x,y);
	buffer[0] = x;
	buffer[1] = y;
	buffer[2] = 0;		// dx
	buffer[3] = 0;		// dy
	buffer[4] = eventType;	// event from pen (DOWN,UP,CLICK,MOVE)
	buffer[5] = stateType;	// state of pen (DOWN,UP,ERROR)
	buffer[6] = 1;		// no of the event
	buffer[7] = 0;		// time of the event (ms) since ts_open
}


static void callback_button_press(GtkWidget *w, GdkEventButton *event)
{
	skPenEvent(Pen_buffer, 0, 1, event->x, event->y);
//      g_print("button pressed , Skyeye get it !!!\n");
}


static void callback_button_release(GtkWidget *w, GdkEventButton *event)
{
	skPenEvent(Pen_buffer, 1, 0, event->x, event->y);
//      g_print("button released , Skyeye get it !!!\n\n");
}


static void callback_motion_notify(GtkWidget *w, GdkEventMotion *event)
{
	/*
	 * when mouse is moving, generate an skyeye pen motion event
	 * should changed to "when mouse is pressed and moving"
	 */
	if (Pen_buffer[5] == 1) skPenEvent(Pen_buffer, 2, 1, event->x, event->y);
//	g_print("and moving , Skyeye get it !!!\n");
}


static gint callback_redraw(GtkWidget *window)
{
	gtk_widget_queue_draw(window);
	return TRUE;
}


static int gtk_lcd_open(struct lcd_device *lcd_dev)
{
	SkyEyeLCD_GTK *lcd;
	guint32 *fbmem;
	char *title;
	GtkWidget *touch_screen;

	if (lcd_dev == NULL || lcd_dev->priv != NULL ||
	    lcd_dev->width <= 0 || lcd_dev->height <= 0) return -1;

	if ((fbmem = (guint32*)skyeye_find_lcd_dma(lcd_dev)) == NULL) {
		fprintf(stderr, "[GTK_LCD]: Can't find LCD DMA from address 0x%x\n", lcd_dev->lcd_addr_begin);
		return -1;
	}

	if ((lcd = (SkyEyeLCD_GTK*)malloc(sizeof(SkyEyeLCD_GTK))) == NULL) return -1;
	memset(lcd, 0, sizeof(SkyEyeLCD_GTK));

	lcd->width = lcd_dev->width;
	lcd->virtual_width = lcd_dev->width + (int)lcd_dev->lcd_line_offset;
	lcd->height = lcd_dev->height;
	lcd->depth = lcd_dev->depth;
	lcd->update_rect.width = -1;
	lcd->update_rect.height = -1;
	lcd->update_all = TRUE;
	lcd->fbmem = fbmem;
	lcd->dev = lcd_dev;

	if(lcd_dev->lcd_lookup_color != NULL) {
		lcd->rgbbuf = (guchar*)malloc(lcd->width * lcd->height * 4);
	} else switch (lcd->depth) {
		case 1:
		case 2:
		case 4:
			lcd->rgbbuf = (guchar*)malloc(lcd->virtual_width * lcd->height);
			break;
		case 12:
		case 16:
			lcd->rgbbuf = (guchar*)malloc(lcd->virtual_width * lcd->height * 3);
			break;

		case 8:
		case 24:
		case 32:
			lcd->rgbbuf = (guchar*)fbmem;
			break;

		default:
			break;
	}

	lcd->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
	gtk_signal_connect(GTK_OBJECT(lcd->window), "delete-event",
			   GTK_SIGNAL_FUNC(gtk_true), NULL);

	if ((title = g_strdup_printf("%dx%dx%d SkyEye LCD & Touch Screen (GTK+)",
				     lcd->width, lcd->height, lcd->depth)) != NULL) {
		gtk_window_set_title(GTK_WINDOW(lcd->window), title);
		g_free(title);
	}

	gtk_widget_set_usize(lcd->window, lcd->width, lcd->height);
	gtk_widget_set_events(lcd->window, GDK_EXPOSURE_MASK);

	touch_screen = gtk_event_box_new();
	gtk_container_add(GTK_CONTAINER(lcd->window), touch_screen);
	gtk_widget_set_events(touch_screen,
			      GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK | GDK_POINTER_MOTION_MASK);
	gtk_signal_connect(GTK_OBJECT(touch_screen), "button-press-event",
			   GTK_SIGNAL_FUNC(callback_button_press), NULL);
	gtk_signal_connect(GTK_OBJECT(touch_screen), "button-release-event",
			   GTK_SIGNAL_FUNC(callback_button_release), NULL);
	gtk_signal_connect(GTK_OBJECT(touch_screen), "motion-notify-event",
			   GTK_SIGNAL_FUNC(callback_motion_notify), NULL);
	gtk_widget_realize(touch_screen);
	gdk_window_set_cursor(touch_screen->window, gdk_cursor_new(GDK_HAND2));

	//zy 2004-4-02 Add Drawing area
	lcd->drawing = gtk_drawing_area_new();
	gtk_container_add(GTK_CONTAINER(touch_screen), lcd->drawing);
	gtk_signal_connect(GTK_OBJECT(lcd->drawing), "expose-event",
			   GTK_SIGNAL_FUNC(callback_expose_event), lcd);

	gtk_widget_show_all(lcd->window);

	if (lcd_dev->lcd_lookup_color == NULL) switch (lcd->depth) {
		case 1:
			lcd->colormap = gdk_rgb_cmap_new(colors1b, 2);
			break;
		case 2:
			break;
		case 4:
			lcd->colormap = gdk_rgb_cmap_new(colors4b, 16);
			break;
		case 8:
			lcd->colormap = gdk_rgb_cmap_new(colors8b, 256);
			break;

		default:
			break;
	}

	lcd->timer = gtk_timeout_add(200, (GtkFunction)callback_redraw, lcd->window);

	lcd_dev->priv = (void*)lcd;

	return 0;
}


static int gtk_lcd_close(struct lcd_device *lcd_dev)
{
	SkyEyeLCD_GTK *lcd = lcd_dev ? (SkyEyeLCD_GTK*)lcd_dev->priv : NULL;
	if(lcd == NULL) return -1;

	if (lcd->rgbbuf != NULL && lcd->rgbbuf != (void*)lcd->fbmem) free(lcd->rgbbuf);
	gtk_timeout_remove(lcd->timer);
	gtk_widget_destroy(lcd->window);
	if (lcd->colormap) gdk_rgb_cmap_free(lcd->colormap);
	free(lcd);

	lcd_dev->priv = NULL;
	lcd_dev->lcd_addr_end = lcd_dev->lcd_addr_begin = 0;

	return 0;
}


static int gtk_lcd_filter_write(struct lcd_device *lcd_dev, u32 addr, u32 data, size_t count)
{
	int offsetADDR1, offsetADDR2;
	int w, x1, y1, x2, y2;

	SkyEyeLCD_GTK *lcd = lcd_dev ? (SkyEyeLCD_GTK*)(lcd_dev->priv) : NULL;
	if (lcd == NULL || addr < lcd_dev->lcd_addr_begin || addr > lcd_dev->lcd_addr_end) return 0;

	offsetADDR1 = (int)(addr - lcd_dev->lcd_addr_begin) * 8 / lcd->depth;
	offsetADDR2 = offsetADDR1 + (int)count * 8 / lcd->depth;
	w = lcd->virtual_width;
	x1 = MIN(offsetADDR1 % w, w - 1);
	y1 = MIN(offsetADDR1 / w, lcd->height - 1);
	x2 = MIN(offsetADDR2 % w, w - 1);
	y2 = MIN(offsetADDR2 / w, lcd->height - 1);

	if (lcd->update_rect.width < 0 || lcd->update_rect.height < 0) {
		lcd->update_rect.x = min(x1, x2);
		lcd->update_rect.y = min(y1, y2);
		lcd->update_rect.width = max(x1, x2) - lcd->update_rect.x;
		lcd->update_rect.height = max(y1, y2) - lcd->update_rect.y;
	} else {
		int l = min(min(x1, x2), lcd->update_rect.x);
		int t = min(min(y1, y2), lcd->update_rect.y);
		int r = max(max(x1, x2), lcd->update_rect.x + lcd->update_rect.width);
		int b = max(max(y1, y2), lcd->update_rect.y + lcd->update_rect.height);

		lcd->update_rect.x = l;
		lcd->update_rect.y = t;
		lcd->update_rect.width = r - l;
		lcd->update_rect.height = b - t;
	}

	lcd->update_all = FALSE;

	return 0;
}


static int gtk_lcd_update(struct lcd_device *lcd_dev)
{
	if (lcd_dev == NULL || lcd_dev->priv == NULL) return -1;

	gtk_main_iteration_do(FALSE);

	return 0;
}


int gtk_lcd_init(struct lcd_device *lcd_dev)
{
	static int tmp_argc = 0;
	static gboolean once = FALSE;
	guint32 i;

	if (lcd_dev == NULL) return -1;

	if (once == FALSE) {
		if (gtk_init_check(&tmp_argc, NULL) == FALSE) {
			fprintf(stderr, "[GTK_LCD]: Can't initalize GTK+\n");
			return -1;
		}

		gdk_rgb_init();

		// ywc 2004-07-24 creat the 256 colormap from 8 TRUE_COLOR-8-332
		// should add PSEUDOCOLOR palette for depth==8
		for (i = 0; i < 256; i++) {
			colors8b[i] =
				((i & 0x000000e0) << 16) + ((i & 0x0000001c) << 11) +
				((i & 0x00000003) << 6);

		}

		once = TRUE;
	}

	lcd_dev->lcd_open = gtk_lcd_open;
	lcd_dev->lcd_close = gtk_lcd_close;
	lcd_dev->lcd_update = gtk_lcd_update;
	lcd_dev->lcd_filter_read = NULL;
	lcd_dev->lcd_filter_write = gtk_lcd_filter_write;

	return 0;
}

