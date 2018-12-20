/* sqLowcodeFFI -- Platform specific definitions for the FFI.
 *
 * Author: Ronie Salgado (roniesalg@gmail.com)
 */


#ifndef _SQ_LOWCODE_FFI_H_
#define _SQ_LOWCODE_FFI_H_

#include <stdint.h>

#if defined(__i386__)
#include "sqLowcodeFFI-i386.h"
#elif defined(__x86_64__)
#include "sqLowcodeFFI-x86_64.h"
#else
#include "sqLowcodeFFI-Unsupported.h"
#endif

#endif /*_SQ_LOWCODE_FFI_H_*/
