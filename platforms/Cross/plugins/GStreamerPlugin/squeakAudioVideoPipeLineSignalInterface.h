/*
 *  squeakAudioVideoPipeLineSignalInterface.h
 *  GStreamer
 *
 *  Created by John M McIntosh on 4/1/08.
 *  Copyright 2008 Corporate Smalltalk Consulting Ltd. http://www.smalltalkconsulting.con All rights reserved.
 *  Written for Viewpoints Research Institute  http://www.vpri.org/
 * http://www.opensource.org/licenses/mit-license.php
 *
 */

struct _SqueakAudioVideoSink { 
   GstElement *owner;
   void*	handler;
   GstBuffer *copyToSendToSqueakAudio;
   gboolean semaphoreWasSignaled;
   gint semaphoreIndexForSink;
   gint prerollCounter;
   guchar *copyToSendToSqueakVideo;
   guint allocbytes;
   guint actualbytes;
   guint width;
   guint height;
   guint fps_n;
   guint fps_d;
   guint depth;
   GstClockTime startTime;
   GstClockTime duration;
   gboolean frame_ready;
	struct VirtualMachine* interpreterProxy;
};
typedef struct _SqueakAudioVideoSink       SqueakAudioVideoSink;
typedef struct _SqueakAudioVideoSink       *SqueakAudioVideoSinkPtr;

void squeakVideoHandOff (GstElement* object,
		GstBuffer* buf,
		GstPad* pad,
		gpointer user_data);

void squeakAudioHandOff (GstElement* object,
		GstBuffer* buf,
		GstPad* pad,
		gpointer user_data);
		
void squeakSrcHandOff (GstElement* object,
		GstBuffer* buf,
		GstPad* pad,
		gpointer user_data);

#define GST_LOCK(obj)			(g_mutex_lock(GST_OBJECT_CAST(obj)->lock))
#define GST_UNLOCK(obj)			(g_mutex_unlock(GST_OBJECT_CAST(obj)->lock))