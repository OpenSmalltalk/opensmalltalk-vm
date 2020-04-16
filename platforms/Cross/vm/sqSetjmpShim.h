/* sqSetjmpShim.h
 *
 *	Defines to ensure we use the most minimal version of setjmp/longjmp
 *	available on the platform to avoid issues with stack unwinding.
 *
 *	Author: Eliot Miranda
 *			eliot.miranda@gmil.com
 *
 *   This file is part of Squeak.
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

/* Use the most minimal setjmp/longjmp pair available; no signal handling
 * wanted or necessary.
 */
#if !defined(_WIN32)
# undef setjmp
# undef longjmp
# define setjmp _setjmp
# define longjmp _longjmp
#endif
/*  N.B. on windows 64 via mingw-w64, the 2nd argument NULL to _setjmp
 *  prevents stack unwinding
 */
#if defined(_WIN64)
# undef setjmp
# undef longjmp
# if defined(__GNUC__)
#  define setjmp(jb) _setjmp(jb,NULL)
# elif defined(_MSC_VER)
#  define setjmp(jb) _setjmp(jb)
# endif
#endif
