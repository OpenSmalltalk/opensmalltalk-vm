/*
 *  squeakAudioVideoPipeLineSignalInterface.c
 *  GStreamer
 *
 *  Created by John M McIntosh on 3/29/08.
 *  Copyright 2008 Corporate Smalltalk Consulting Ltd. http://www.smalltalkconsulting.con All rights reserved.
 *  Written for Viewpoints Research Institute  http://www.vpri.org/
 * http://www.opensource.org/licenses/mit-license.php
 *
 */

#include <gst/gst.h>
#include <gst/gstobject.h>
#include <string.h>
#include "squeakAudioVideoPipeLineSignalInterface.h"
#include "sqVirtualMachine.h"


void gst_SqueakVideoSink_set_caps (SqueakAudioVideoSinkPtr sink, GstCaps * caps);
void gst_SqueakAudioSink_sink_write(GstElement* plugin, SqueakAudioVideoSinkPtr sink, gpointer data, guint length, GstClockTime  duration);


/* Element Signals:
  "handoff" :  void user_function (GstElement* object,
                                   GstBuffer* arg0,
                                   GstPad* arg1,
                                   gpointer user_data);
  "preroll-handoff" :  void user_function (GstElement* object,
                                           GstBuffer* arg0,
                                           GstPad* arg1,
                                           gpointer user_data); */


void squeakVideoHandOff (GstElement* object,
		GstBuffer* buf,
		GstPad* pad,
		gpointer user_data)  {

	GST_LOCK(object);
	{
	SqueakAudioVideoSinkPtr  squeaker = (SqueakAudioVideoSinkPtr) user_data;
	
	if (squeaker->width == 0)
		gst_SqueakVideoSink_set_caps(squeaker,GST_BUFFER_CAPS(buf));
	
	
	if (squeaker->width == 0) {
		GST_UNLOCK(object);
		return;  /* should not happen but let's check */
	}
		
	if (GST_BUFFER_DATA(buf)) {
			guint totalBytes = (squeaker->depth == 24 ? 4 : 2)*squeaker->width*squeaker->height;
		squeaker->frame_ready = TRUE;
		if (totalBytes != squeaker->allocbytes) {
			if (squeaker->copyToSendToSqueakVideo) 
				g_free(squeaker->copyToSendToSqueakVideo);
			squeaker->copyToSendToSqueakVideo = g_malloc(totalBytes);
			squeaker->allocbytes = totalBytes;
		}
		memcpy(squeaker->copyToSendToSqueakVideo,GST_BUFFER_DATA(buf),totalBytes);
	}
	}
	GST_UNLOCK(object);

	
}

void squeakSrcHandOff (GstElement* object,
		GstBuffer* buf,
		GstPad* pad,
		gpointer user_data)  {

	GST_LOCK(object);
	{
	SqueakAudioVideoSinkPtr  squeaker = (SqueakAudioVideoSinkPtr) user_data;
	
	if (squeaker->frame_ready) {
		squeaker->frame_ready = FALSE;
		if (squeaker->semaphoreIndexForSink && squeaker->interpreterProxy) {
			squeaker->interpreterProxy->signalSemaphoreWithIndex(squeaker->semaphoreIndexForSink);
		}
		if (GST_BUFFER_SIZE (buf) >= squeaker->actualbytes)
			memcpy(GST_BUFFER_DATA(buf),squeaker->copyToSendToSqueakVideo,squeaker->actualbytes);
		GST_BUFFER_TIMESTAMP(buf) = squeaker->startTime;
		GST_BUFFER_DURATION(buf) = squeaker->duration;
	}
	}
	GST_UNLOCK(object);

}

void
	gst_SqueakVideoSink_set_caps (SqueakAudioVideoSinkPtr sink, GstCaps * caps) {
	GstStructure *structure;	
	int width, height, depth;
	gboolean ret;
	const GValue *fps;
	structure = gst_caps_get_structure (caps, 0);
	ret = gst_structure_get_int (structure, "width", &width);
	ret = ret && gst_structure_get_int (structure, "height", &height);
	ret = ret && gst_structure_get_int (structure, "depth", &depth);
	fps = gst_structure_get_value (structure, "framerate");
	ret = ret && (fps != NULL);
	if (!ret) return;
	sink->width = width;
	sink->height = height;
	sink->depth = depth;
	sink->fps_n = gst_value_get_fraction_numerator(fps);
	sink->fps_d = gst_value_get_fraction_denominator(fps);
	sink->width = width;
	sink->height = height;
}


void squeakAudioHandOff (GstElement* object,
		GstBuffer* buf,
		GstPad* pad,
		gpointer user_data)  {

	SqueakAudioVideoSinkPtr  squeaker = (SqueakAudioVideoSinkPtr) user_data;
	
	if (GST_BUFFER_DATA(buf)) {
		gst_SqueakAudioSink_sink_write(object, squeaker,GST_BUFFER_DATA(buf), GST_BUFFER_SIZE(buf),GST_BUFFER_DURATION(buf));
	}
	
}



void gst_SqueakAudioSink_sink_write(GstElement* plugin, SqueakAudioVideoSinkPtr sink, gpointer data,guint length, GstClockTime  duration)
{
	guint64 squeakbuffersize;
	guint8		* startLocation;
	
		
	GST_LOCK(plugin);
	
	if (sink->copyToSendToSqueakAudio == NULL) {
		sink->copyToSendToSqueakAudio = gst_buffer_new_and_alloc(22050*8);  /* 2.0 second of data */
		GST_BUFFER_OFFSET_END(sink->copyToSendToSqueakAudio) = 0;
	}

	squeakbuffersize = GST_BUFFER_OFFSET_END(sink->copyToSendToSqueakAudio);
	/* semaphore not signalled and if we go over X then we want to signal the semaphore if it exits, but only once */
	
	if ((sink->semaphoreWasSignaled == 0) && 
		((squeakbuffersize + length) > 22050))
		{	sink->semaphoreWasSignaled = 1;
			if (sink->semaphoreIndexForSink && sink->interpreterProxy) {
				sink->interpreterProxy->signalSemaphoreWithIndex(sink->semaphoreIndexForSink);
			}
		}
	
	/* if squeakbuffersize + incoming length <= 22050*8 then allow the copy, otherwise we FLUSH the buffer and start over */
	
	if ((squeakbuffersize + length) <= 22050*8) {
			startLocation = GST_BUFFER_DATA(sink->copyToSendToSqueakAudio) + squeakbuffersize;
		} else {
			/* buffer full and squeak not getting data, please wait */
			
			GST_BUFFER_OFFSET_END(sink->copyToSendToSqueakAudio) = 0;
			startLocation = GST_BUFFER_DATA(sink->copyToSendToSqueakAudio);
		} 
	
	/* copy data to the start of the squeak buffer or to some offset, and not run over the end! */
			
	memcpy(startLocation,data,length);
	GST_BUFFER_OFFSET_END(sink->copyToSendToSqueakAudio) = GST_BUFFER_OFFSET_END(sink->copyToSendToSqueakAudio) + length;
	if (sink->prerollCounter) {
		sink->prerollCounter = sink->prerollCounter -1;
		GST_UNLOCK(plugin);
		return;
	}
		
	GST_UNLOCK(plugin);
	 	

	{
			/* Wait for this many milliseconds so squeak can catch up per buffer write */
			
	/*		GstClock *clock;
			GstClockID id;
			GstClockTime base;
			GstClockReturn result;
			gdouble millisecondestimate;
						
			millisecondestimate = (duration/1000000);
				
			clock = gst_system_clock_obtain ();
			base = gst_clock_get_time (clock);
			id = gst_clock_new_single_shot_id (clock, base + (gint)millisecondestimate);
			result = gst_clock_id_wait (id, NULL);
			gst_clock_id_unref(id); */
		} 
	
	return;
}
