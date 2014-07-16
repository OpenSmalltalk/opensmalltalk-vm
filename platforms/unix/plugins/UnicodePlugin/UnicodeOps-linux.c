/* UnicodeOps-linux.c
 *
 * 
 *   Copyright (C) 2011 Massachusetts Institute of Technology
 *   All rights reserved.
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
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 */


#include <pango/pangocairo.h>
#include <glib/gprintf.h>
#include <string.h>

/* entry points */

int unicodeClipboardGet(unsigned short *utf16, int utf16Length);
void unicodeClipboardPut(unsigned short *utf16, int utf16Length);
int unicodeClipboardSize(void);
void unicodeDrawString(char *utf8, int utf8Length, int *wPtr, int *hPtr, unsigned int *bitmapPtr);
int unicodeGetFontList(char *str, int strLength);
int unicodeGetXRanges(char *utf8, int utf8Length, int *resultPtr, int resultLength);
void unicodeMeasureString(char *utf8, int utf8Length, int *wPtr, int *hPtr);
void unicodeSetColors(int fgRed, int fgGreen, int fgBlue, int bgRed, int bgGreen, int bgBlue, int mapBGToTransparent);
void unicodeSetFont(char *fontName, int fontSize, int boldFlag, int italicFlag, int antiAliasFlag);

/* globals */

PangoLayout *cachedLayout = NULL;  // used for measuring
PangoFontDescription *fontDescr = NULL;
cairo_font_options_t* fontOptions = NULL;

int	g_bgRed = 255, g_bgGreen = 255, g_bgBlue = 255;
int	g_fgRed = 0,   g_fgGreen = 0,   g_fgBlue = 0;
int	g_bgRGB = 0; // Squeak format
int	g_bgTransparent = 0;

/* helper procedures */

void computeLayout(PangoLayout *layout, char *utf8, int utf8Length, int *wPtr, int *hPtr, int *xOffsetPtr, int *yOffsetPtr, int *layoutDetailsPtr) {
	PangoRectangle inkRect, logicalRect;
	int left, top, right, bottom, baseline;
	PangoLayoutIter *iter;

	if (fontDescr == NULL) unicodeSetFont("Verdana", 18, 0, 0, 1);
	pango_cairo_context_set_font_options(pango_layout_get_context(layout), fontOptions);
	pango_layout_set_font_description(layout, fontDescr);
	pango_layout_set_text(layout, utf8, utf8Length);
	pango_layout_get_pixel_extents(layout, &inkRect, &logicalRect);

	left = (inkRect.x < logicalRect.x) ? inkRect.x : logicalRect.x;
	top = (inkRect.y < logicalRect.y) ? inkRect.y : logicalRect.y;
	right = inkRect.x + inkRect.width;
	if ((logicalRect.x + logicalRect.width) > right) right = logicalRect.x + logicalRect.width;
	bottom = inkRect.y + inkRect.height;
	if ((logicalRect.y + logicalRect.height) > bottom) bottom = logicalRect.y + logicalRect.height;

	iter = pango_layout_get_iter(layout);
	baseline = PANGO_PIXELS(pango_layout_iter_get_baseline(iter));
	pango_layout_iter_free(iter);

	if (left < 0) {
		inkRect.x = inkRect.x - left;
		logicalRect.x = logicalRect.x - left;
	}
	if (top < 0) {
		inkRect.y = inkRect.y - top;
		logicalRect.y = logicalRect.y - top;
		baseline = baseline - top;
	}

	if (layoutDetailsPtr != NULL) {
		layoutDetailsPtr[0] = inkRect.x;
		layoutDetailsPtr[1] = inkRect.y;
		layoutDetailsPtr[2] = inkRect.width;
		layoutDetailsPtr[3] = inkRect.height;
		
		layoutDetailsPtr[4] = logicalRect.x;
		layoutDetailsPtr[5] = logicalRect.y;
		layoutDetailsPtr[6] = logicalRect.width;
		layoutDetailsPtr[7] = logicalRect.height;

		layoutDetailsPtr[8] = baseline;
	}

	*wPtr =  right - left;
	*hPtr = bottom - top;
	*xOffsetPtr = left < 0 ? -left : 0;
	*yOffsetPtr =  top < 0 ? -top  : 0;
}

int unicodeLength(char *utf8, int utf8Length) {
	int count, i, ch;

	count = i = 0;
	while (i < utf8Length) {
		count++;
		ch = utf8[i];
		if ((ch & 0xE0) == 0xC0) i += 2;
		else if ((ch & 0xF0) == 0xE0) i += 3;
		else if ((ch & 0xF8) == 0xF0) i += 4;
		else i += 1;
	}
	return count;
}

/* entry points */

// Clipboard operations are not yet implemented
int unicodeClipboardGet(unsigned short *utf16, int utf16Length) { return 0; }
void unicodeClipboardPut(unsigned short *utf16, int utf16Length) { }
int unicodeClipboardSize(void) { return 0; }

int unicodeGetFontList(char *str, int strLength) {
	PangoFontMap *fontMap;
	PangoFontFamily **fontFomilies;
	int count, i;

	str[0] = '\0';

	if (cachedLayout == NULL) {
		cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_A8, 1, 1);
		cairo_t *cr = cairo_create(surface);
		cachedLayout = pango_cairo_create_layout(cr);
	}

	fontMap = pango_context_get_font_map(pango_layout_get_context(cachedLayout));
	pango_font_map_list_families(fontMap, &fontFomilies, &count);

	for (i = 0; i < count; i++) {
		strncat(str, pango_font_family_get_name(fontFomilies[i]), strLength);
		strncat(str, "\n", strLength);
	}
	g_free(fontFomilies);
	return strlen(str);
}

void unicodeDrawString(char *utf8, int utf8Length, int *wPtr, int *hPtr, unsigned int *bitmapPtr) {
	int w = *wPtr;
	int h = *hPtr;
	int pixelCount = w * h;
	int offsetX, offsetY;
	unsigned int *pixelPtr, *lastPtr;

	cairo_surface_t *surface = cairo_image_surface_create_for_data((unsigned char *) bitmapPtr, CAIRO_FORMAT_RGB24, w, h, (4 * w));
	cairo_t *cr = cairo_create(surface);
	PangoLayout *layout = pango_cairo_create_layout(cr);

	computeLayout(layout, utf8, utf8Length, wPtr, hPtr, &offsetX, &offsetY, NULL);

	// fill with background color if not transparent
	if (g_bgRGB != 0) {
		cairo_set_source_rgb(cr, g_bgRed / 255.0, g_bgGreen / 255.0, g_bgBlue / 255.0);
		cairo_paint(cr);
	}

	cairo_translate(cr, offsetX, offsetY);
	cairo_set_source_rgb(cr, g_fgRed / 255.0, g_fgGreen / 255.0, g_fgBlue / 255.0);
	pango_cairo_show_layout(cr, layout);

	// map bg color pixels to transparent if so desired
	if (g_bgTransparent) {
		pixelPtr = bitmapPtr;
		lastPtr = pixelPtr + pixelCount;
		while (pixelPtr < lastPtr) {
			if (*pixelPtr == g_bgRGB) *pixelPtr = 0;
			pixelPtr++;
		}
	}

	g_object_unref(layout);
	cairo_destroy(cr);
	cairo_surface_destroy(surface);
}

int unicodeGetXRanges(char *utf8, int utf8Length, int *resultPtr, int resultLength) {
	int w, h, offsetX, offsetY;
	int count, ch, i, j;
	PangoRectangle rect;

	count = unicodeLength(utf8, utf8Length);
	if (resultLength < (2 * count)) return -1;

	if (cachedLayout == NULL) {
		cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_A8, 1, 1);
		cairo_t *cr = cairo_create(surface);
		cachedLayout = pango_cairo_create_layout(cr);
	}

	computeLayout(cachedLayout, utf8, utf8Length, &w, &h, &offsetX, &offsetY, NULL);

	i = j = 0;
	while ((i < utf8Length) && (j < (resultLength - 1))) {
		pango_layout_index_to_pos(cachedLayout, i, &rect);
		ch = utf8[i];
		if ((ch & 0xE0) == 0xC0) i += 2;
		else if ((ch & 0xF0) == 0xE0) i += 3;
		else if ((ch & 0xF8) == 0xF0) i += 4;
		else i += 1;
		resultPtr[j] = PANGO_PIXELS(rect.x);
		resultPtr[j + 1] = PANGO_PIXELS(rect.x + rect.width);
		j += 2;
	}

	return count;
}

void unicodeMeasureString(char *utf8, int utf8Length, int *wPtr, int *hPtr) {
	int offsetX, offsetY;

	if (cachedLayout == NULL) {
		cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_A8, 1, 1);
		cairo_t *cr = cairo_create(surface);
		cachedLayout = pango_cairo_create_layout(cr);
	}

	computeLayout(cachedLayout, utf8, utf8Length, wPtr, hPtr, &offsetX, &offsetY, NULL);
}

void unicodeSetColors(int fgRed, int fgGreen, int fgBlue, int bgRed, int bgGreen, int bgBlue, int mapBGToTransparent) {
	g_fgRed   = fgRed & 255;
	g_fgGreen = fgGreen & 255;
	g_fgBlue  = fgBlue & 255;
	g_bgRed   = bgRed & 255;
	g_bgGreen = bgGreen & 255;
	g_bgBlue  = bgBlue & 255;
	g_bgRGB = (g_bgRed << 16) | (g_bgGreen << 8) | g_bgBlue;  // Squeak pixel format
	g_bgTransparent = mapBGToTransparent;
}

void unicodeSetFont(char *fontName, int fontSize, int boldFlag, int italicFlag, int antiAliasFlag) {
	char description[200];
	g_sprintf(description, "%s, %s %s %dpx",
		fontName,
		(boldFlag ? "bold" : ""),
		(italicFlag ? "italic" : ""),
		fontSize);

	if (fontDescr != NULL) pango_font_description_free(fontDescr);
	fontDescr = pango_font_description_from_string(description);

	if (fontOptions == NULL) {
		fontOptions = cairo_font_options_create();
		// Note: On Mac OS, the default hint style and metrics looked the best. Also, using
		// the default allows the user to control the look via the OS settings.
		/*
		styles:
			CAIRO_HINT_STYLE_DEFAULT		Use the default hint style for for font backend and target device
			CAIRO_HINT_STYLE_NONE			Do not hint outlines
			CAIRO_HINT_STYLE_SLIGHT			Hint outlines slightly to improve contrast while retaining good fidelity to the original shapes.
			CAIRO_HINT_STYLE_MEDIUM			Hint outlines with medium strength giving a compromise between fidelity to the original shapes and contrast
			CAIRO_HINT_STYLE_FULL			Hint outlines to maximize contrast
		metrics:
			CAIRO_HINT_METRICS_DEFAULT	Hint metrics in the default manner for the font backend and target device
			CAIRO_HINT_METRICS_OFF			Do not hint font metrics
			CAIRO_HINT_METRICS_ON			Hint font metrics
		*/
		cairo_font_options_set_hint_style(fontOptions, CAIRO_HINT_STYLE_DEFAULT);
		cairo_font_options_set_hint_metrics(fontOptions, CAIRO_HINT_METRICS_DEFAULT);
	}

	cairo_font_options_set_antialias(fontOptions, antiAliasFlag ? CAIRO_ANTIALIAS_GRAY : CAIRO_ANTIALIAS_NONE);
}
