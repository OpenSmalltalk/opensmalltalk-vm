/* sqSetjmpShim.h
 *
 *	Defines to ensure the VM uses the most minimal version of setjmp/longjmp
 *	available on the platform to avoid issues with stack unwinding.
 *
 *	Author: Eliot Miranda
 *			eliot.miranda@gmail.com
 *
 *   This file is part of OpenSmalltalk-VM.
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

#if !defined(__SETJMP_SHIM)
#define __SETJMP_SHIM

#include <setjmp.h>

/* Use the most minimal setjmp/longjmp pair available; unix signal(3) handling
 * intentionally avoided. On win64 to avoid crashes when unwinding the stack in
 * Kernel32's longjmp use the pairs in platforms/win32/misc/_setjmp-???.asm.
 */
#undef setjmp
#undef _setjmp
#undef longjmp
#undef _longjmp
#define setjmp(b) _setjmp(b)
#define longjmp(b,v) _longjmp(b,v)

#if defined(_WIN32) || defined(_WIN64)
// Windows clang redeclares _setjmp so provide an alternative
# define _setjmp(b) _setjmp0(b)
# if defined(__GNUC__) || defined(__clang__)
int __attribute__((__nothrow__,__returns_twice__)) __cdecl _setjmp0(jmp_buf jb);
void __attribute__((_Noreturn)) __cdecl _longjmp(jmp_buf jb,int v);
# else
int  __cdecl _setjmp0(jmp_buf jb);
void __declspec(noreturn) __cdecl _longjmp(jmp_buf jb,int v);
# endif
#endif // _WIN32 || _WIN64

#endif // __SETJMP_SHIM
