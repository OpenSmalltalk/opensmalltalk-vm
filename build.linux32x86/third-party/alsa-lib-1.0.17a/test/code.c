#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sched.h>
#include <sys/time.h>

#ifndef __builtin_expect
#include <linux/compiler.h>
#endif

#define rdtscll(val) \
     __asm__ __volatile__("rdtsc" : "=A" (val))

#define likely(x)       __builtin_expect((x),1)
#define unlikely(x)     __builtin_expect((x),0)

typedef short int s16;
typedef int s32;

#if 0
#define CONFIG_SMP
#endif

#ifdef CONFIG_SMP
#define LOCK_PREFIX "lock ; "
#else
#define LOCK_PREFIX ""
#endif

struct __xchg_dummy { unsigned long a[100]; };
#define __xg(x) ((struct __xchg_dummy *)(x))

static inline unsigned long __cmpxchg(volatile void *ptr, unsigned long old,
				      unsigned long new, int size)
{
	unsigned long prev;
	switch (size) {
	case 1:
		__asm__ __volatile__(LOCK_PREFIX "cmpxchgb %b1,%2"
				     : "=a"(prev)
				     : "q"(new), "m"(*__xg(ptr)), "0"(old)
				     : "memory");
		return prev;
	case 2:
		__asm__ __volatile__(LOCK_PREFIX "cmpxchgw %w1,%2"
				     : "=a"(prev)
				     : "q"(new), "m"(*__xg(ptr)), "0"(old)
				     : "memory");
		return prev;
	case 4:
		__asm__ __volatile__(LOCK_PREFIX "cmpxchgl %1,%2"
				     : "=a"(prev)
				     : "q"(new), "m"(*__xg(ptr)), "0"(old)
				     : "memory");
		return prev;
	}
	return old;
}

#define cmpxchg(ptr,o,n)\
	((__typeof__(*(ptr)))__cmpxchg((ptr),(unsigned long)(o),\
				       (unsigned long)(n),sizeof(*(ptr))))

static inline void atomic_add(volatile int *dst, int v)
{
	__asm__ __volatile__(
		LOCK_PREFIX "addl %1,%0"
		:"=m" (*dst)
		:"ir" (v), "m" (*dst));
}

static double detect_cpu_clock()
{
	struct timeval tm_begin, tm_end;
	unsigned long long tsc_begin, tsc_end;

	/* Warm cache */
	gettimeofday(&tm_begin, 0);

	rdtscll(tsc_begin);
	gettimeofday(&tm_begin, 0);

	usleep(1000000);

	rdtscll(tsc_end);
	gettimeofday(&tm_end, 0);

	return (tsc_end - tsc_begin) / (tm_end.tv_sec - tm_begin.tv_sec + (tm_end.tv_usec - tm_begin.tv_usec) / 1e6);
}

void mix_areas_srv(unsigned int size,
		   const s16 *src,
		   volatile s32 *sum,
		   unsigned int src_step, unsigned int sum_step)
{
	src_step /= sizeof(*src);
	sum_step /= sizeof(*sum);
        while (size-- > 0) {
                atomic_add(sum, *src);
                src += src_step;
                sum += sum_step;
        }
}

void saturate(unsigned int size,
              s16 *dst, const s32 *sum,
              unsigned int dst_step, unsigned int sum_step)
{
	dst_step /= sizeof(*dst);
	sum_step /= sizeof(*sum);
        while (size-- > 0) {
                s32 sample = *sum;
                if (unlikely(sample < -0x8000))
                        *dst = -0x8000;
                else if (unlikely(sample > 0x7fff))
                        *dst = 0x7fff;
                else
                        *dst = sample;
                dst += dst_step;
                sum += sum_step;
        }
}

void mix_areas0(unsigned int size,
		volatile s16 *dst, s16 *src,
		volatile s32 *sum,
		unsigned int dst_step,
		unsigned int src_step,
		unsigned int sum_step)
{
	dst_step /= sizeof(*dst);
	src_step /= sizeof(*src);
	sum_step /= sizeof(*sum);
	while (size-- > 0) {
		s32 sample = *dst + *src;
		if (unlikely(sample < -0x8000))
			*dst = -0x8000;
		else if (unlikely(sample > 0x7fff))
			*dst = 0x7fff;
		else
			*dst = sample;
		dst += dst_step;
		src += src_step;
		sum += sum_step;
	}
}

#define MIX_AREAS1 mix_areas1
#define MIX_AREAS1_MMX mix_areas1_mmx
#include "../src/pcm/pcm_dmix_i386.h"
#undef MIX_AREAS1
#undef MIX_AREAS1_MMX

void mix_areas2(unsigned int size,
		volatile s16 *dst, const s16 *src,
		volatile s32 *sum,
		unsigned int dst_step,
		unsigned int src_step)
{
	dst_step /= sizeof(*dst);
	src_step /= sizeof(*src);
	while (size-- > 0) {
		s32 sample = *src;
		s32 old_sample = *sum;
		if (cmpxchg(dst, 0, 1) == 0)
			sample -= old_sample;
		atomic_add(sum, sample);
		do {
			sample = *sum;
			if (unlikely(sample < -0x8000))
				*dst = -0x8000;
			else if (unlikely(sample > 0x7fff))
				*dst = 0x7fff;
			else
				*dst = sample;
		} while (unlikely(sample != *sum));
		sum++;
		dst += dst_step;
		src += src_step;
	}
}

void setscheduler(void)
{
	struct sched_param sched_param;

	if (sched_getparam(0, &sched_param) < 0) {
		printf("Scheduler getparam failed...\n");
		return;
	}
	sched_param.sched_priority = sched_get_priority_max(SCHED_RR);
	if (!sched_setscheduler(0, SCHED_RR, &sched_param)) {
		printf("Scheduler set to Round Robin with priority %i...\n", sched_param.sched_priority);
		fflush(stdout);
		return;
	}
	printf("!!!Scheduler set to Round Robin with priority %i FAILED!!!\n", sched_param.sched_priority);
}

int cache_size = 1024*1024;

void init(s16 *dst, s32 *sum, int size)
{
	int count;
	char *a;
	
	for (count = size - 1; count >= 0; count--)
		*sum++ = 0;
	for (count = size - 1; count >= 0; count--)
		*dst++ = 0;
	a = malloc(cache_size);
	for (count = cache_size - 1; count >= 0; count--) {
		a[count] = count & 0xff;
		a[count] ^= 0x55;
		a[count] ^= 0xaa;
	}
	free(a);
}

int main(int argc, char **argv)
{
	int size = 2048, n = 4, max = 32267;
	int LOOP = 100;
	int i, t;
	unsigned long long begin, end, diff, diffS, diff0, diff1, diff1_mmx, diff2;
        double cpu_clock = detect_cpu_clock();
	s16 *dst = malloc(sizeof(*dst) * size);
	s32 *sum = calloc(size, sizeof(*sum));
	s16 **srcs = malloc(sizeof(*srcs) * n);

	setscheduler();
#ifndef CONFIG_SMP
        printf("CPU clock: %fMhz (UP)\n\n", cpu_clock / 10e5);
#else
        printf("CPU clock: %fMhz (SMP)\n\n", cpu_clock / 10e5);
#endif
	if (argc > 3) {
		size = atoi(argv[1]);
		n = atoi(argv[2]);
		max = atoi(argv[3]);
	}
	if (argc > 4)
		cache_size = atoi(argv[4]) * 1024;
	for (i = 0; i < n; i++) {
		int k;
		s16 *s;
		srcs[i] = s = malloc(sizeof(s16) * size);
		for (k = 0; k < size; ++k, ++s) {
			*s = (rand() % (max * 2)) - max;
		}
	}

	for (t = 0, diffS = -1; t < LOOP; t++) {
		init(dst, sum, size);
		rdtscll(begin);
		for (i = 0; i < n; i++) {
			mix_areas_srv(size, srcs[i], sum, 2, 4);
		}
		saturate(size, dst, sum, 2, 4);
		rdtscll(end);
		diff = end - begin;
		if (diff < diffS)
			diffS = diff;
		printf("mix_areas_srv : %lld               \r", diff); fflush(stdout);
	}

	for (t = 0, diff0 = -1; t < LOOP; t++) {
		init(dst, sum, size);
		rdtscll(begin);
		for (i = 0; i < n; i++) {
			mix_areas0(size, dst, srcs[i], sum, 2, 2, 4);
		}
		rdtscll(end);
		diff = end - begin;
		if (diff < diff0)
			diff0 = diff;
		printf("mix_areas0    : %lld               \r", diff); fflush(stdout);
	}

	for (t = 0, diff1 = -1; t < LOOP; t++) {
		init(dst, sum, size);
		rdtscll(begin);
		for (i = 0; i < n; i++) {
			mix_areas1(size, dst, srcs[i], sum, 2, 2, 4);
		}
		rdtscll(end);
		diff = end - begin;
		if (diff < diff1)
			diff1 = diff;
		printf("mix_areas1    : %lld              \r", diff); fflush(stdout);
	}

	for (t = 0, diff1_mmx = -1; t < LOOP; t++) {
		init(dst, sum, size);
		rdtscll(begin);
		for (i = 0; i < n; i++) {
			mix_areas1_mmx(size, dst, srcs[i], sum, 2, 2, 4);
		}
		rdtscll(end);
		diff = end - begin;
		if (diff < diff1_mmx)
			diff1_mmx = diff;
		printf("mix_areas1_mmx: %lld              \r", diff); fflush(stdout);
	}

	for (t = 0, diff2 = -1; t < LOOP; t++) {
		init(dst, sum, size);
		rdtscll(begin);
		for (i = 0; i < n; i++) {
			mix_areas2(size, dst, srcs[i], sum, 2, 2);
		}
		rdtscll(end);
		diff = end - begin;
		if (diff < diff2)
			diff2 = diff;
		printf("mix_areas2    : %lld              \r", diff); fflush(stdout);
	}

	printf("                                                                           \r");
	printf("Summary (the best times):\n");
	printf("mix_areas_srv : %lld %f%%\n", diffS, 100*2*44100.0*diffS/(size*n*cpu_clock));
	printf("mix_areas0    : %lld %f%%\n", diff0, 100*2*44100.0*diff0/(size*n*cpu_clock));
	printf("mix_areas1    : %lld %f%%\n", diff1, 100*2*44100.0*diff1/(size*n*cpu_clock));
	printf("mix_areas1_mmx: %lld %f%%\n", diff1_mmx, 100*2*44100.0*diff1_mmx/(size*n*cpu_clock));
	printf("mix_areas2    : %lld %f%%\n", diff2, 100*2*44100.0*diff2/(size*n*cpu_clock));

	printf("\n");
	printf("areas1/srv ratio     : %f\n", (double)diff1 / diffS);
	printf("areas1_mmx/srv ratio : %f\n", (double)diff1_mmx / diffS);

	return 0;
}
