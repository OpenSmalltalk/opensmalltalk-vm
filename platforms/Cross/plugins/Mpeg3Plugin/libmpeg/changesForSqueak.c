/****************************************************************************
*   PROJECT: Changes for Squeak 
*   FILE:    changesForSqueak.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: See change log below.
*	12/27/2001 JMM added support to build as a OS-X Bundle, a bit werid because its a mixture of unix and mac OS
*****************************************************************************/
/* Squeak on MPEG
   by John M McIntosh johnmci#smalltalkconsulting.com  Sept 2000
   
   For the macintosh I've 
   1) coded up #ifdef for TARGET_OS_MAC
   2) Coded around the pthreads
   3) ignored most of mpeg3io_device
   4) some changes to make CodeWarrior 5 happy
   
   In General
   
   1) Added some casts
   2) had some problems with Mpeg3_stream_coeffs_t
   3) coded up memoryAllocate/memoryFree versus malloc/cmalloc/free
   4) created a mpeg3_generate_toc_for_Squeak
   5) Ignore perror
   
*/
// Nov 2nd, 2000  JMM changed memoryAllocate, use calloc
// Sept 7nd, 2001 JMM added carbon logic
// May 31st, 2002 JMM a few additions to make it compile on the mac with latest code

#include <stdlib.h>
#include <string.h>
#include "mpeg3private.h"
#include "changesForSqueak.h"

#if defined(TARGET_OS_MAC) && !defined ( __APPLE__ ) && !defined ( __MACH__ )
#include <Memory.h>
#include <QuickDraw.h>
#include "sq.h"
#endif

#ifdef WIN32
#include <windows.h>
#endif

mpeg3_demuxer_t* mpeg3_new_demuxer(mpeg3_t *file, int do_audio, int do_video, int stream_id);
mpeg3_title_t* mpeg3_new_title(mpeg3_t *file, char *path);
mpeg3demux_timecode_t* mpeg3_append_timecode(mpeg3_demuxer_t *demuxer, 
		mpeg3_title_t *title, 
		long prev_byte, 
		double prev_time, 
		long next_byte, 
		double next_time,
		int dont_store);
void appendStringToBufferIfPossible(char *buffer,char *append,int bufferSize);
		

static long counter = 0;

void * memoryAllocate(int number,unsigned size) {
    void * stuff;
#if defined(TARGET_OS_MAC) && !defined ( __APPLE__ ) && !defined ( __MACH__ )
#if TARGET_API_MAC_CARBON
    stuff = (void *) NewPtrClear(size*number);
#else
    stuff = (void *) NewPtrSysClear(size*number);
#endif
//    if (stuff == nil) Debugger();
#else
    stuff = (void *) calloc(size,number);
#endif
    counter++;
    return stuff;
}

void memoryFree(void *stuff) {
    counter--;
#if defined(TARGET_OS_MAC) && !defined ( __APPLE__ ) && !defined ( __MACH__ )
    DisposePtr((char *)stuff);
#else
    free(stuff);
#endif
}



#if (defined(TARGET_OS_MAC) && !defined ( __APPLE__ ) && !defined ( __MACH__ )) || (defined(WIN32) && !defined(__GNUC__))
#define NEEDSTRFUNCS
#endif

#ifdef NEEDSTRFUNCS
void perror(const char * string) {

}
int			strncasecmp(const char *str1, const char *str2, size_t nchars);
int			strcasecmp (const char *str1, const char *str2);

int			strncasecmp(const char *s1, const char *s2, size_t len)
{
  /* Return true if the two strings are the same, not considering case. */
	int i, c1, c2;

	for (i = 0; i < len; i++) {
		c1 = s1[i];
		c2 = s2[i];
		if ((c1 >= 'a') && (c1 <= 'z')) {
			c1 = c1 - ('a' - 'A');
		}
		if ((c2 >= 'a') && (c2 <= 'z')) {
			c2 = c2 - ('a' - 'A');
		}
		if (c1 != c2) return 0;
	}
	return 1;
}

int			strcasecmp (const char *str1, const char *str2) {
	if (strlen(str1) != strlen(str2)) return 0;
    return strncasecmp(str1,str2,strlen(str1));
}


#endif

#ifdef WIN32
int bzero(char* block, long size) {
	ZeroMemory(block,size);
}
#endif


#if defined(TARGET_OS_MAC) && !defined ( __APPLE__ ) && !defined ( __MACH__ )
int bzero(char *block,long size) {
    BlockZero(block,size);
}

int main ()
{
} 

#endif

#if defined(TARGET_OS_MAC) && defined ( __APPLE__ ) && defined ( __MACH__ )
int isSystem9_0_or_better(void)
{
    return 1;
}
#endif 

void appendStringToBufferIfPossible(char *buffer,char *append,int bufferSize) 
{
	if (strlen(append) + strlen(buffer) < bufferSize) 
		strcat(buffer,append);

}

int mpeg3_generate_toc_for_Squeak(mpeg3_t *file, int timecode_search, int print_streams, char *buffer, int bufferSize) {
	mpeg3_demuxer_t *demuxer;
	int i;
	char temp_buffer[256];
	if(file)
	{
		buffer[0] = 0x00;
		demuxer = mpeg3_new_demuxer(file, 0, 0, -1);
		mpeg3demux_create_title_for_Squeak(demuxer, timecode_search, buffer, bufferSize);
/* Just print the first title's streams */
		if(print_streams) mpeg3demux_print_streams_for_Squeak(demuxer, buffer,bufferSize);

		sprintf(temp_buffer, "SIZE: %ld\n", demuxer->titles[demuxer->current_title]->total_bytes);
		appendStringToBufferIfPossible(buffer,temp_buffer,bufferSize);		
		sprintf(temp_buffer, "PACKETSIZE: %ld\n", demuxer->packet_size);
		appendStringToBufferIfPossible(buffer,temp_buffer,bufferSize);		

		mpeg3demux_print_timecodes(demuxer->titles[demuxer->current_title], buffer);

		mpeg3_delete_demuxer(demuxer);
		return 0;
	}
	return 1;
}
/* Create a title. */
/* Build a table of timecodes contained in the program stream. */
/* If toc is 0 just read the first and last timecode. */
int mpeg3demux_create_title_for_Squeak(mpeg3_demuxer_t *demuxer, int timecode_search, char *buffer,int buffer_size)
{
	int result = 0, done = 0, counter_start, counter;
	mpeg3_t *file = (mpeg3_t *) demuxer->file;
	long next_byte=0, prev_byte=0;
	double next_time, prev_time, absolute_time;
	long i;
	mpeg3_title_t *title;
	unsigned long test_header = 0;
	mpeg3demux_timecode_t *timecode = 0;
	char temp_buffer[256];
	
	demuxer->error_flag = 0;
	demuxer->generating_timecode = 1;

/* Create a single title */
	if(!demuxer->total_titles)
	{
		demuxer->titles[0] = mpeg3_new_title(file, file->fs->path);
		demuxer->total_titles = 1;
		mpeg3demux_open_title(demuxer, 0);
	}
	title = demuxer->titles[0];
	title->total_bytes = mpeg3io_total_bytes(title->fs);


/* Get the packet size from the file */
	if(file->is_program_stream)
	{
		mpeg3io_seek(title->fs, 4);
		for(i = 0; i < MPEG3_MAX_PACKSIZE && 
			test_header != MPEG3_PACK_START_CODE; i++)
		{
			test_header <<= 8;
			test_header |= mpeg3io_read_char(title->fs);
		}
		if(i < MPEG3_MAX_PACKSIZE) demuxer->packet_size = i;
		mpeg3io_seek(title->fs, 0);
	}
	else
		demuxer->packet_size = file->packet_size;

/* Get timecodes for the title */
	if(file->is_transport_stream || file->is_program_stream)
	{
		mpeg3io_seek(title->fs, 0);
		while(!done && !result && !mpeg3io_eof(title->fs))
		{
			next_byte = mpeg3io_tell(title->fs);
			result = mpeg3_read_next_packet(demuxer);

			if(!result)
			{
				next_time = demuxer->time;
				sprintf(temp_buffer,"%f %f\n", next_time, prev_time);
	 			appendStringToBufferIfPossible(buffer,temp_buffer,buffer_size);	
				if(next_time < prev_time || 
					next_time - prev_time > MPEG3_CONTIGUOUS_THRESHOLD ||
					!title->timecode_table_size)
				{
/* Discontinuous */
					timecode = mpeg3_append_timecode(demuxer, 
						title, 
						prev_byte, 
						prev_time, 
						next_byte, 
						next_time,
						0);
 
  			sprintf(temp_buffer,"timecode: %ld %ld %f %f\n",
   				timecode->start_byte,
   				timecode->end_byte,
   				timecode->start_time,
  				timecode->end_time);
 			appendStringToBufferIfPossible(buffer,temp_buffer,buffer_size);	


					counter_start = next_time;
				}
				prev_time = next_time;
				prev_byte = next_byte;
				counter = next_time;
			}

/* Just get the first bytes if not building a toc to get the stream ID's. */
			if(next_byte > 0x100000 && 
				(!timecode_search || !buffer)) done = 1;
		}

/* Get the last timecode */
		if(!buffer || !timecode_search)
		{
			result = mpeg3io_seek(title->fs, title->total_bytes);
			if(!result) result = mpeg3_read_prev_packet(demuxer);
		}

		if(title->timecode_table && timecode)
		{
			timecode->end_byte = title->total_bytes;
//			timecode->end_byte = mpeg3io_tell(title->fs)/*  + demuxer->packet_size */;
			timecode->end_time = demuxer->time;
			timecode->absolute_end_time = timecode->end_time - timecode->start_time;
		}
	}

	mpeg3io_seek(title->fs, 0);
	demuxer->generating_timecode = 0;
	return 0;
}

int mpeg3demux_print_streams_for_Squeak(mpeg3_demuxer_t *demuxer, char *buffer,int buffer_size)
{
	int i;
	char temp_buffer[256];
	
/* Print the stream information */
	for(i = 0; i < MPEG3_MAX_STREAMS; i++)
	{
		if(demuxer->astream_table[i]) {
			sprintf(temp_buffer, "ASTREAM: %d %d\n", i, demuxer->astream_table[i]);
			appendStringToBufferIfPossible(buffer,temp_buffer,buffer_size);	
		}	

		if(demuxer->vstream_table[i]) {
			sprintf(temp_buffer, "VSTREAM: %d %d\n", i, demuxer->vstream_table[i]);
			appendStringToBufferIfPossible(buffer,temp_buffer,buffer_size);	
		}	
	}
	return 0;
}

mpeg3_css_t* mpeg3_new_css()
{
	return 0;
}

int mpeg3_delete_css(mpeg3_css_t *css)
{
	return 0;
}

int mpeg3_get_keys(mpeg3_css_t *css, char *path)
{
	return 1;
}

int mpeg3_decrypt_packet(mpeg3_css_t *css, unsigned char *sector)
{
	return 1;
}


/*** System Attributes ***/

int IsImageName(char *name) {
	char *suffix;

	suffix = strrchr(name, '.');  /* pointer to last period in name */
	if (suffix == NULL) return 0;
	if (strcmp(suffix, ".ima") == 0) return 1;
	if (strcmp(suffix, ".image") == 0) return 1;
	if (strcmp(suffix, ".IMA") == 0) return 1;
	if (strcmp(suffix, ".IMAGE") == 0) return 1;
	return 0;
}


