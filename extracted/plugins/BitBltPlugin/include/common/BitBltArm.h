/*
 * Copyright © 2013 Raspberry Pi Foundation
 * Copyright © 2013 RISC OS Open Ltd
 *
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of the copyright holders not be used in
 * advertising or publicity pertaining to distribution of the software without
 * specific, written prior permission.  The copyright holders make no
 * representations about the suitability of this software for any purpose.  It
 * is provided "as is" without express or implied warranty.
 *
 * THE COPYRIGHT HOLDERS DISCLAIM ALL WARRANTIES WITH REGARD TO THIS
 * SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS, IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 * AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 *
 */

#ifndef BITBLTARM_H_
#define BITBLTARM_H_

typedef enum {
	ARM_V7     = (1 << 0),
	ARM_V6     = (1 << 1),
	ARM_VFP    = (1 << 2),
	ARM_NEON   = (1 << 3),
	ARM_IWMMXT = (1 << 4)
} arm_cpu_features_t;

extern arm_cpu_features_t armCpuFeatures;

/* There's a separate implementation of this function for each OS */
arm_cpu_features_t detectCpuFeatures(void);

void addArmFastPaths(void);

#endif /* BITBLTARM_H_ */
