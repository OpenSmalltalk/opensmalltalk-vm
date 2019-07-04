/*
 * Copyright © 2000 SuSE, Inc.
 * Copyright © 2007 Red Hat, Inc.
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of SuSE not be used in advertising or
 * publicity pertaining to distribution of the software without specific,
 * written prior permission.  SuSE makes no representations about the
 * suitability of this software for any purpose.  It is provided "as is"
 * without express or implied warranty.
 *
 * SuSE DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL SuSE
 * BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 * OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 * CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

* WRT the usage in the Squeak Smalltalk system -
* This file provides a function to discover the cpu features supported at runtime; we assume
* you understand that 'arm_cpu_features' is meaningful only on ARM cpu machines. 
* An equivalent file will be required for other ARM platforms; see BitBtArmOther.c in this directory
 */

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <string.h>
#include <elf.h>

#include "BitBltArm.h"

arm_cpu_features_t detectCpuFeatures(void)
{
    arm_cpu_features_t features = 0;
    Elf32_auxv_t aux;
    int fd;

    fd = open ("/proc/self/auxv", O_RDONLY);
    if (fd >= 0)
    {
	while (read (fd, &aux, sizeof(Elf32_auxv_t)) == sizeof(Elf32_auxv_t))
	{
	    if (aux.a_type == AT_HWCAP)
	    {
		uint32_t hwcap = aux.a_un.a_val;

		/* hardcode these values to avoid depending on specific
		 * versions of the hwcap header, e.g. HWCAP_NEON
		 */
		if ((hwcap & 64) != 0)
		    features |= ARM_VFP;
		if ((hwcap & 512) != 0)
		    features |= ARM_IWMMXT;
		/* this flag is only present on kernel 2.6.29 */
		if ((hwcap & 4096) != 0)
		    features |= ARM_NEON;
	    }
	    else if (aux.a_type == AT_PLATFORM)
	    {
		const char *plat = (const char*) aux.a_un.a_val;

		if (strncmp (plat, "v7l", 3) == 0)
		    features |= (ARM_V7 | ARM_V6);
		else if (strncmp (plat, "v6l", 3) == 0)
		    features |= ARM_V6;
	    }
	}
	close (fd);
    }

    return features;
}

