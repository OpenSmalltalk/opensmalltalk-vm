/* sqUnixProfiler.c -- VM profiler plugin for Unix Squeak	-*- C -*-
 * 
 *   Copyright (C) 1996 1997 1998 1999 2000 2001 Ian Piumarta and individual
 *      authors/contributors listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. This notice may not be removed or altered in any source distribution.
 * 
 *   Using or modifying this file for use in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the base
 *   of the distribution before proceeding with any such use.
 * 
 *   You are STRONGLY DISCOURAGED from distributing a modified version of
 *   this file under its original name without permission.  If you must
 *   change it, rename it first.
 */

/* Author: Ian.Piumarta@INRIA.Fr
 * 
 * Last edited: Mon Aug 14 16:33:04 2000 by piumarta (Ian Piumarta) on emilia
 */

/* NAME
 *	Profiler - execution time profiler for static VM code.
 *
 * SYNOPSIS
 *	SystemDictionary methodsFor: 'profiling'
 *
 *	    startVMProfiling
 *		<primitive: 'startProfiling' module: 'Profiler'>
 *
 *	    stopVMProfiling
 *		<primitive: 'stopProfiling' module: 'Profiler'>
 *
 *	    clearVMProfile
 *		<primitive: 'clearProfile' module: 'Profiler'>
 *
 *	    dumpVMProfile
 *		<primitive: 'dumpProfile' module: 'Profiler'>
 *
 *	    vmProfile: aBlock
 *		| answer |
 *		self clearVMProfile; startVMprofiling.
 *		answer := aBlock value.
 *		self stopVMProfiling; dumpVMprofile.
 *		^answer
 *
 * DESCRIPTION
 *	These primitives provide a means to find out in which areas the VM
 *	is spending most of its time.  They use a vector "short"s to
 *	statistically sample the execution frequency of each instruction in
 *	the ".text" section of the compiled VM.  Every virtual 10
 *	milliseconds, the VM's program counter is examined.  If it is
 *	somewhere inside the static (compiled C) part of the VM then the
 *	corresponding entry in the vector is incremented.
 *	
 *	The primitive #dumpVMProfile scans the functions defined in the text
 *	section of the compiled VM and sums the sampled execution counts for
 *	each of their implementations, one at a time.  If a sum is non-zero
 *	it prints (on stdout) the total number of samples for the function,
 *	the percentage of sampled execution time consumed by the function,
 *	its first and last instruction addresses, and then its name.  At the
 *	end of the dump it summarizes the number of samples actually
 *	recorded for the static VM code, the number expected (based on the
 *	total amount of time spent executing with sampling enabled), and
 *	estimates of the percentage of time spent executing in static VM code
 *	and "elsewhere".
 *	
 *	Profiling is only performed for execution that occurs within
 *	#startVMProfiling and #stopVMProfiling pairs, and is cumulative.
 *	This is useful to profile just a subset of a program.  For example,
 *	to profile the execution time rooted at #doSomethingInteresing: in 
 *	
 *		a := self doSomethingBoring.
 *		b := self doSomethingInteresting: a.
 *		c := self doSomethingIrrelevant: b.
 *	
 *	insert profiling code as follows:
 *	
 *		a := self doSomethingBoring.
 *		Smalltalk startVMProfiling.
 *		b := self doSomethingInteresting: a.
 *		Smalltalk stopVMProfiling.
 *		c := self doSomethingIrrelevant: b.
 *	
 *	A subsequent call to #dumpVMProfile will show the profiling results
 *	associated with this particular send of #doSomethingInteresting:,
 *	accumulating the results for successive sends.
 *	
 *	#dumpVMProfile does not alter the profiling information.
 *	#clearVMProfile must used to reset the sample counts to zero.
 *
 * RETURN VALUE
 *	All primitives answer "self" (i.e. Smalltalk).
 *
 * BUGS
 *   0. Profiling is based on sampling, not counting.  It is therefore
 *	subject to statistical error.  For a function whose overall
 *	execution time is T seconds and a sampling interval of 0.01 second,
 *	the expected error in the profiling report for the function is
 *	
 *		((T / 0.01) ^ 0.5) / (T / 0.01) * 100 %
 *	
 *   1.	This plugin requires a file called "Squeak.map" in the working
 *	directory that contains a table of the VM's text symbols in BSD "nm"
 *	format, sorted numerically.  If you haven't got one handy, make your
 *	own with:
 *
 *	  nm -nBC squeak | grep -iw [tT] | fgrep -v ' .' > Squeak.map
 *
 *	(It would be nice to read the symbols directly out of the running
 *	core, but that seems difficult to do portably.  Having thought
 *	about this some more I looked at libbfd, and several seconds later
 *	came to the revised conclusion that there absolutely isn't any
 *	portable way to do it.  Even a popen() on the above command is
 *	doomed to failure since several Unices [including the one we love
 *	to hate, which barely deserves to call itself Unix] don't have an
 *	option to generate a BSD format symbol listing from nm.  Sigh.)
 *
 *   2.	If the Squeak.map file doesn't correspond to the running VM then
 *	the profiler will cheerfully generate a pile of very plausible
 *	looking garbage instead of a faithful profile.  Caveat emptor.
 *
 *   3.	The whole caboodle requires a SVr4-like profil() system call or
 *	library routine.  If you haven't got one of those then give up
 *	now.  There's no simple alternative, other than installing a
 *	real GNU-based OS on your machine -- which is always the best way
 *	forward no matter what the problem might be.  (In the limit you
 *	might get away with compiling/linking with a gcc configured to
 *	use its own copy of glibc.)
 *
 *   4.	The profiler should really be part of the VM itself, connected
 *	via sqXWindow.c:{start,stop,clear,dump}Profil{e,ing}() to the
 *	primitives of the same names in SystemDictionary.  Considering
 *	the above limitations, I figured this wasn't such a great idea.
 *
 *   5.	We could at least do the right thing on a few Unices by extending the
 *	autoconf stuff in several places -- but I needed a profiler for some
 *	heavy biz and didn't want the hassle: ethics and aesthetics were not
 *	even scrawled on the back of the list of considerations.
 *	
 *   6.	The Profiler is incompatible with other uses of the ITIMER_PROF
 *	interval timer.  On some systems it may even interfere with the
 *	itimer-based low-res millisecond clock.  If in doubt, recompile
 *	the VM with the option "USE_ITIMER" in sqXWindow.c *disabled*
 *	before using these profiling primitives.
 *
 *   7.	The two profiling facilities in SystemDictionary cannot
 *	both be active at the same time.
 *	
 *   8.	Profiling does not work for functions in other plugins.
 *	
 *   9.	Profiling consumes approximately 0.25% of your CPU.
 *	
 *  10.	We could significantly reduce the amount of space used by the sample
 *	buffer (and increase the speed of report generation) by estimating
 *	the largest granularity that would not result in incorrectly
 *	identifying the function associated with a given sampled PC.  A
 *	suitable value might be the largest power of 2 no greater than the
 *	alignment of function entry points.  Of course, increasing the
 *	granularity in the sample buffer for very long profiles would
 *	increase the risk of a sample wrapping around to zero.
 *	
 * CONFORMING TO
 *	This plugin is Y2K compliant and fully interoperable with j3.
 *
 * FILES
 *	Squeak.map - table of VM text symbols (must exist in working dir).
 *	
 * SEE ALSO
 *	SystemDictionary methodsFor: 'profiling'.  "primProfile.cc" in j3.
 *	pofil(3) and setitimer(2) manual pages.
 *	
 * NOTES
 *   1.	If you want to see the filename and line numbers correspoding to each
 *	function in the profiling output, generate the Squeak.map file with:
 *	
 *	  nm -nlBC squeak | grep -iw '[tT]' | fgrep -v ' .' |
 *		sed 's:/.*\/\(.*\):<\1>:' > Squeak.map
 *	
 *   2.	j3 snarfs the regular SystemDictionary profiling primitives and
 *	redefines them to do profiling on the _dynamic_ (runtime generated)
 *	code.  The two sets of primitives are therefore complementary: the
 *	primitives defined here profile rather the _static_ code in the
 *	runtime support.  The regular profiling primitives might tell you
 *	that execution time was "50% dynamic, 50% static" (and show a
 *	detailed analysis of the 50% of execution time spent in dynamic
 *	code).  To find out the details for the 50% of time spent in static
 *	code, run the same program profiling it using the primitives defined
 *	here instead of the regular primitives.  For example:
 *	
 *		"time spent in dynamic code..."
 *		Smalltalk profile: [RichardsBenchmark start].
 *		"time spent in static code..."
 *		Smalltalk vmProfile: [RichardsBenchmark start].
 */


#define Squeak_map	"Squeak.map"
#define FNAME_MAX	1024		// longest function name

#undef	DEBUG


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/times.h>

#include "sq.h"
#include "sqVirtualMachine.h"

#undef ioMSecs


#if defined(DEBUG)
# define PRINTF(ARGS)	printf ARGS
#else
# define PRINTF(ARGS)
#endif


#if defined(__powerpc__) || defined(__sparc__)
  typedef unsigned int insn;
#elif defined(__i386__)
  typedef unsigned char insn;
#else
# warning: ASSUMING DEFAULT INSN TYPE
  typedef unsigned char insn;	/* pessimistic (but expensive) failsafe */
#endif

#define STRINGIFY(S)	#S
#define ESTRINGIFY(S)	STRINGIFY(S)

typedef unsigned short sample;

typedef struct
{
  size_t  addr;
  char	 *name;
} Symbol;

typedef struct
{
  unsigned  count;
  char	   *name;
} Profile;


static size_t origin=	0;
static size_t limit=	0;
static size_t maxIndex= 0;

static sample *samples=     0;
static size_t  samplesSize= 0;

static unsigned	onTime=     0;
static unsigned	offTime=    0;
static unsigned profilTime= 0;

static Profile *profiles=     0;
static size_t   profilesSize= 0;
static size_t	profileCount= 0;

static const size_t DefaultProfilesSize= 64;


/* ITIMER_PROF uses VIRTUAL system+user time, NOT wall-clock time! */

static unsigned vMSecs(void)
{
  struct tms buf;
  times(&buf);
  return (unsigned)(( (float)buf.tms_stime + (float)buf.tms_utime)
		    / (float)CLK_TCK * 1000.0);
}


static int profileIncludes(size_t addr)
{
  return (addr >= origin) && (addr < limit);
}


static unsigned tally(unsigned from, unsigned to)
{
  if (profileIncludes(from) && profileIncludes(to - sizeof(insn)))
    {
      unsigned min= (from - origin) / sizeof(insn);
      unsigned max= (to   - origin) / sizeof(insn);
      unsigned count= 0;
      unsigned i;
      for (i= min; i < max; ++i)
	count+= samples[i];
      return count;
    }
  return 0;
}


static float percent(unsigned num, unsigned den)
{
  return den < 1 ? 0.0 : ((float)num * 100.0) / (float)den;
}


static void growProfiles(void)
{
  profilesSize*= 2;
  profiles= (Profile *)realloc((void *)profiles, profilesSize * sizeof(Profile));
}


static void allocProfiles(size_t size)
{
  if (size == 0)
    {
      unsigned i;
      for (i= 0;  i < profileCount;  ++i)
	free(profiles[i].name);
      free(profiles);
      profiles= 0;
      profilesSize= 0;
      profileCount= 0;
    }
  else
    {
      profiles= (Profile *)calloc(size, sizeof(Profile));
      profilesSize= size;
      profileCount= 0;
    }
}


static int profileCompare(const void *v, const void *w)
{
  const Profile *p= (Profile *)v;
  const Profile *q= (Profile *)w;
  if (q->count < p->count) return -1;
  if (q->count > p->count) return  1;
  /* equal counts are sorted by function name */
  return strcmp(p->name, q->name);
}


static void printProfiles(unsigned recorded, unsigned expected,
			  float sampled, float elapsed)
{
  unsigned i;
  qsort((void *)profiles, profileCount, sizeof(Profile), profileCompare);
  printf("%5s %7s %6s %6s  %s\n", "count", "   time", "elapsed", "sampled", "function");
  printf("%5s %7s %6s %6s  %s\n", "-----", "-------", "-------", "-------", "--------");
  for (i= 0;  i < profileCount;  ++i)
    {
      float time= (float)profiles[i].count / (float)expected * elapsed;
      printf("%5d %6.2fs %6.2f%% %6.2f%%  %s\n",
	     profiles[i].count,
	     time,
	     percent(profiles[i].count, expected),
	     percent(profiles[i].count, recorded),
	     profiles[i].name);
    }
}


static unsigned profile(size_t org, size_t end, char *name)
{
  unsigned observed= tally(org, end);
  if (observed > 0)
    {
      if (profileCount == profilesSize)
	growProfiles();
      profiles[profileCount].count= observed;
      profiles[profileCount].name= strdup(name);
      ++profileCount;
    }
  return observed;
}


static void swapSymbols(Symbol *s1, Symbol *s2)
{
  size_t  a1= s1->addr;
  char   *n1= s1->name;
  s1->addr= s2->addr;
  s1->name= s2->name;
  s2->addr= a1;
  s2->name= n1;
}


static int readSymbol(FILE *map, Symbol *aSymbol)
{
  extern int main();
  int ok= (2 == fscanf(map, "%x %*c %"ESTRINGIFY(FNAME_MAX)"[^\n]",
		       &aSymbol->addr, aSymbol->name));
  if (ok && !strcmp(aSymbol->name, "main") && (aSymbol->addr != (unsigned)main))
    {
      fprintf(stderr,
	"\nWARNING: "Squeak_map" does not appear to correspond to the running VM."
	"\nWARNING: Your profile is almost certainly meaningless.\n\n");
    }
  return ok;
}


static int profileSymbolsInMap(FILE *map)
{
  float    elapsed= (float)profilTime / 1000.0;	/* seconds */
  unsigned expected= profilTime / 10;		/* 0,01 secs/sample */
  unsigned recorded= tally(origin, limit);
  unsigned observed= 0;
  float    sampled= (float)recorded / (float)expected * elapsed;
  char currName[FNAME_MAX+1], nextName[FNAME_MAX+1];
  Symbol curr, next;
  curr.name= currName;
  next.name= nextName;
  for (;;)
    {
      if (readSymbol(map, &curr))
	{
	  printf("Profiler: %d samples covering %.3f (of %.3f virtual) seconds\n\n",
		 recorded, sampled, elapsed);
	  while (readSymbol(map, &next))
	    {
	      observed+= profile(curr.addr, next.addr, curr.name);
	      swapSymbols(&curr, &next);
	    }
	  if (feof(map))
	    break;
	}
      fprintf(stderr, "Profiler: Cannot parse `"Squeak_map"'\n");
      return 0;
    }

  printProfiles(recorded, expected, sampled, elapsed);

  if (observed != recorded)
    {
      printf("*** %d samples were AWOL ***\n", recorded - observed);
    }

  printf("\n");
  printf("static VM: %6.2fs %6.2f%%\n",
	 sampled, percent(observed, expected));
  printf("elsewhere: %6.2fs %6.2f%%\n\n",
	 elapsed - sampled, percent(expected - observed, expected));

  return 1;
}


/**
*** PRIMITIVES
**/

int dumpProfile(void)
{
  int ok= 1;

  if (samples)
    {
      FILE *map= fopen(Squeak_map, "r");
      if (map == 0)
	{
	  perror(Squeak_map);
	  success(false);
	  return 0;
	}
      allocProfiles(DefaultProfilesSize);
      ok= profileSymbolsInMap(map);
      allocProfiles(0);
      fclose(map);
      if (!ok)
	success(false);
    }

  return ok;
}


int startProfiling(void)
{
  if (!samples)
    {
      extern char _start, _etext;
      size_t range= 0;
      origin= (size_t)&_start;
      limit= (size_t)&_etext;
      range= limit - origin;
      maxIndex= range / sizeof(insn);
      samplesSize= maxIndex * sizeof(sample);
      samples= (sample *)calloc(maxIndex, sizeof(sample));
      PRINTF(("Profiler: sampling %d bytes in [%08x %08x]\n", range, origin, limit));
    }
  onTime= vMSecs();
  PRINTF(("Profiler: started at %.3f\n", (float)onTime / 1000.0));
  /* 4th arg is a magic formula -- see <unistd.h> for enlightenment */
  profil(samples, samplesSize, origin, (65536 / sizeof(insn)) * sizeof(sample));
  return 1;
}


int stopProfiling(void)
{
  if (samples)
    {
      offTime= vMSecs();
      profil(0, 0, 0, 0);
      profilTime+= (offTime - onTime);
      PRINTF(("Profiler: stopped at %.3f (profile time is %.3f)\n",
	     (float)offTime / 1000.0, (float)profilTime / 1000.0));
    }
  return 1;
}


int clearProfile(void)
{
  if (samples)
    {
      memset((void *)samples, 0, samplesSize);
      profilTime= 0;
      PRINTF(("Profiler: cleared\n"));
    }
  return 1;
}


/**
*** MODULE INITIALISATION
**/


int setInterpreter(struct VirtualMachine *anInterpreter)
{
  return 1;
}
