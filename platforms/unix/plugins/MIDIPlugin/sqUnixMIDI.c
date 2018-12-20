/* sqUnixMIDI.c -- Unix MIDI support
 * 
 *   Copyright (C) 1996-2007 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

/* Author: Ian.Piumarta@INRIA.FR
 * 
 * Last edited: 2007-03-11 16:56:02 by piumarta on emilia.local
 */

#include "sq.h"
#include "MIDIPlugin.h"

#include "config.h"
#include "debug.h"

/*
 * After an autoreconf this worked but the buildsystem is not prepared
 * to pass the right libraries to the linker. There was no interest in
 * the pull request for more than three month so let's move on.
 */
#if defined(USE_MIDI_ALSA)
#warning "We could have real MIDI support but..."
//# include "sqUnixMIDIALSA.inc"
# include "sqUnixMIDINone.inc"
#else

# include "sqUnixMIDINone.inc"
#endif


/* # include "sqUnixMIDIALSA.inc" */
