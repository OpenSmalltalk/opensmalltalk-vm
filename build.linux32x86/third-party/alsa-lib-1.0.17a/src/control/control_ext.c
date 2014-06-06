/**
 * \file control/control_ext.c
 * \ingroup CtlPlugin_SDK
 * \brief External Control Plugin SDK
 * \author Takashi Iwai <tiwai@suse.de>
 * \date 2005
 */
/*
 *  Control Interface - External Control Plugin SDK
 *
 *  Copyright (c) 2005 Takashi Iwai <tiwai@suse.de>
 *
 *
 *   This library is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Lesser General Public License as
 *   published by the Free Software Foundation; either version 2.1 of
 *   the License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, write to the Free Software
 *   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "control_local.h"
#include "control_external.h"

#ifndef PIC
/* entry for static linking */
const char *_snd_module_control_ext = "";
#endif

static int snd_ctl_ext_close(snd_ctl_t *handle)
{
	snd_ctl_ext_t *ext = handle->private_data;
	
	if (ext->callback->close)
		ext->callback->close(ext);
	return 0;
}

static int snd_ctl_ext_nonblock(snd_ctl_t *handle, int nonblock)
{
	snd_ctl_ext_t *ext = handle->private_data;

	ext->nonblock = nonblock;
	return 0;
}

static int snd_ctl_ext_async(snd_ctl_t *ctl ATTRIBUTE_UNUSED,
			     int sig ATTRIBUTE_UNUSED,
			     pid_t pid ATTRIBUTE_UNUSED)
{
	return -ENOSYS;
}

static int snd_ctl_ext_subscribe_events(snd_ctl_t *handle, int subscribe)
{
	snd_ctl_ext_t *ext = handle->private_data;

	if (subscribe < 0)
		return ext->subscribed;
	ext->subscribed = !!subscribe;
	if (ext->callback->subscribe_events)
		ext->callback->subscribe_events(ext, subscribe);
	return 0;
}

static int snd_ctl_ext_card_info(snd_ctl_t *handle, snd_ctl_card_info_t *info)
{
	snd_ctl_ext_t *ext = handle->private_data;

	memset(info, 0, sizeof(*info));
	info->card = ext->card_idx;
	memcpy(info->id, ext->id, sizeof(info->id));
	memcpy(info->driver, ext->driver, sizeof(info->driver));
	memcpy(info->name, ext->name, sizeof(info->name));
	memcpy(info->longname, ext->longname, sizeof(info->longname));
	memcpy(info->mixername, ext->mixername, sizeof(info->mixername));
	return 0;
}

static int snd_ctl_ext_elem_list(snd_ctl_t *handle, snd_ctl_elem_list_t *list)
{
	snd_ctl_ext_t *ext = handle->private_data;
	int ret;
	unsigned int i, offset;
	snd_ctl_elem_id_t *ids;

	list->count = ext->callback->elem_count(ext);
	list->used = 0;
	ids = list->pids;
	offset = list->offset;
	for (i = 0; i < list->space; i++) {
		if (offset >= list->count)
			break;
		snd_ctl_elem_id_clear(ids);
		ret = ext->callback->elem_list(ext, offset, ids);
		if (ret < 0)
			return ret;
		list->used++;
		offset++;
		ids++;
	}
	return 0;
}

static int snd_ctl_ext_elem_info(snd_ctl_t *handle, snd_ctl_elem_info_t *info)
{
	snd_ctl_ext_t *ext = handle->private_data;
	snd_ctl_ext_key_t key;
	int type, ret;

	key = ext->callback->find_elem(ext, &info->id);
	if (key == SND_CTL_EXT_KEY_NOT_FOUND)
		return -ENOENT;
	ret = ext->callback->get_attribute(ext, key, &type, &info->access, &info->count);
	if (ret < 0)
		goto err;
	info->type = type;
	ret = -EINVAL;
	switch (info->type) {
	case SND_CTL_ELEM_TYPE_BOOLEAN:
		info->value.integer.min = 0;
		info->value.integer.max = 1;
		ret = 0;
		break;
	case SND_CTL_ELEM_TYPE_INTEGER:
		if (! ext->callback->get_integer_info)
			goto err;
		ret = ext->callback->get_integer_info(ext, key, &info->value.integer.min,
						      &info->value.integer.max,
						      &info->value.integer.step);
		break;
	case SND_CTL_ELEM_TYPE_INTEGER64:
		if (! ext->callback->get_integer64_info)
			goto err;
		{
			int64_t xmin, xmax, xstep;
			ret = ext->callback->get_integer64_info(ext, key,
								&xmin,
								&xmax,
								&xstep);
			info->value.integer64.min = xmin;
			info->value.integer64.max = xmax;
			info->value.integer64.step = xstep;
		}
		break;
	case SND_CTL_ELEM_TYPE_ENUMERATED:
		if (! ext->callback->get_enumerated_info)
			goto err;
		ret = ext->callback->get_enumerated_info(ext, key, &info->value.enumerated.items);
		ext->callback->get_enumerated_name(ext, key, info->value.enumerated.item,
						   info->value.enumerated.name,
						   sizeof(info->value.enumerated.name));
		break;
	default:
		ret = 0;
		break;
	}

 err:
	if (ext->callback->free_key)
		ext->callback->free_key(ext, key);

	return ret;
}

static int snd_ctl_ext_elem_add(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				snd_ctl_elem_info_t *info ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_elem_replace(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				    snd_ctl_elem_info_t *info ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_elem_remove(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				   snd_ctl_elem_id_t *id ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_elem_read(snd_ctl_t *handle, snd_ctl_elem_value_t *control)
{
	snd_ctl_ext_t *ext = handle->private_data;
	snd_ctl_ext_key_t key;
	int type, ret;
	unsigned int access, count;

	key = ext->callback->find_elem(ext, &control->id);
	if (key == SND_CTL_EXT_KEY_NOT_FOUND)
		return -ENOENT;
	ret = ext->callback->get_attribute(ext, key, &type, &access, &count);
	if (ret < 0)
		goto err;
	ret = -EINVAL;
	switch (type) {
	case SND_CTL_ELEM_TYPE_BOOLEAN:
	case SND_CTL_ELEM_TYPE_INTEGER:
		if (! ext->callback->read_integer)
			goto err;
		ret = ext->callback->read_integer(ext, key, control->value.integer.value);
		break;
	case SND_CTL_ELEM_TYPE_INTEGER64:
		if (! ext->callback->read_integer64)
			goto err;
		ret = ext->callback->read_integer64(ext, key,
						    (int64_t*)control->value.integer64.value);
		break;
	case SND_CTL_ELEM_TYPE_ENUMERATED:
		if (! ext->callback->read_enumerated)
			goto err;
		ret = ext->callback->read_enumerated(ext, key, control->value.enumerated.item);
		break;
	case SND_CTL_ELEM_TYPE_BYTES:
		if (! ext->callback->read_bytes)
			goto err;
		ret = ext->callback->read_bytes(ext, key, control->value.bytes.data,
						sizeof(control->value.bytes.data));
		break;
	case SND_CTL_ELEM_TYPE_IEC958:
		if (! ext->callback->read_iec958)
			goto err;
		ret = ext->callback->read_iec958(ext, key, (snd_aes_iec958_t *)&control->value.iec958);
		break;
	default:
		break;
	}

 err:
	if (ext->callback->free_key)
		ext->callback->free_key(ext, key);

	return ret;
}

static int snd_ctl_ext_elem_write(snd_ctl_t *handle, snd_ctl_elem_value_t *control)
{
	snd_ctl_ext_t *ext = handle->private_data;
	snd_ctl_ext_key_t key;
	int type, ret;
	unsigned int access, count;

	key = ext->callback->find_elem(ext, &control->id);
	if (key == SND_CTL_EXT_KEY_NOT_FOUND)
		return -ENOENT;
	ret = ext->callback->get_attribute(ext, key, &type, &access, &count);
	if (ret < 0)
		goto err;
	ret = -EINVAL;
	switch (type) {
	case SND_CTL_ELEM_TYPE_BOOLEAN:
	case SND_CTL_ELEM_TYPE_INTEGER:
		if (! ext->callback->write_integer)
			goto err;
		ret = ext->callback->write_integer(ext, key, control->value.integer.value);
		break;
	case SND_CTL_ELEM_TYPE_INTEGER64:
		if (! ext->callback->write_integer64)
			goto err;
		ret = ext->callback->write_integer64(ext, key, (int64_t *)control->value.integer64.value);
		break;
	case SND_CTL_ELEM_TYPE_ENUMERATED:
		if (! ext->callback->write_enumerated)
			goto err;
		ret = ext->callback->write_enumerated(ext, key, control->value.enumerated.item);
		break;
	case SND_CTL_ELEM_TYPE_BYTES:
		if (! ext->callback->write_bytes)
			goto err;
		ret = ext->callback->write_bytes(ext, key, control->value.bytes.data,
						sizeof(control->value.bytes.data));
		break;
	case SND_CTL_ELEM_TYPE_IEC958:
		if (! ext->callback->write_iec958)
			goto err;
		ret = ext->callback->write_iec958(ext, key, (snd_aes_iec958_t *)&control->value.iec958);
		break;
	default:
		break;
	}

 err:
	if (ext->callback->free_key)
		ext->callback->free_key(ext, key);

	return ret;
}

static int snd_ctl_ext_elem_lock(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				 snd_ctl_elem_id_t *id ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_elem_unlock(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				   snd_ctl_elem_id_t *id ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_next_device(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				   int *device ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_prefer_subdevice(snd_ctl_t *handle ATTRIBUTE_UNUSED,
					int subdev ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_hwdep_info(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				  snd_hwdep_info_t *info ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_pcm_info(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				snd_pcm_info_t *info ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_rawmidi_info(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				    snd_rawmidi_info_t *info ATTRIBUTE_UNUSED)
{
	return -ENXIO;
}

static int snd_ctl_ext_set_power_state(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				       unsigned int state ATTRIBUTE_UNUSED)
{
	return 0;
}

static int snd_ctl_ext_get_power_state(snd_ctl_t *handle ATTRIBUTE_UNUSED,
				       unsigned int *state ATTRIBUTE_UNUSED)
{
	return 0;
}

static int snd_ctl_ext_read(snd_ctl_t *handle, snd_ctl_event_t *event)
{
	snd_ctl_ext_t *ext = handle->private_data;

	memset(event, 0, sizeof(*event));
	return ext->callback->read_event(ext, &event->data.elem.id, &event->data.elem.mask);
}

static int snd_ctl_ext_poll_descriptors_count(snd_ctl_t *handle)
{
	snd_ctl_ext_t *ext = handle->private_data;

	if (ext->callback->poll_descriptors_count)
		return ext->callback->poll_descriptors_count(ext);
	if (ext->poll_fd >= 0)
		return 1;
	return 0;
}

static int snd_ctl_ext_poll_descriptors(snd_ctl_t *handle, struct pollfd *pfds, unsigned int space)
{
	snd_ctl_ext_t *ext = handle->private_data;

	if (ext->callback->poll_descriptors)
		return ext->callback->poll_descriptors(ext, pfds, space);
	if (ext->poll_fd < 0)
		return 0;
	if (space > 0) {
		pfds->fd = ext->poll_fd;
		pfds->events = POLLIN|POLLERR|POLLNVAL;
		return 1;
	}
	return 0;
}

static int snd_ctl_ext_poll_revents(snd_ctl_t *handle, struct pollfd *pfds, unsigned int nfds, unsigned short *revents)
{
	snd_ctl_ext_t *ext = handle->private_data;

	if (ext->callback->poll_revents)
		return ext->callback->poll_revents(ext, pfds, nfds, revents);
	if (nfds == 1) {
		*revents = pfds->revents;
                return 0;
	}
	return -EINVAL;
}

static snd_ctl_ops_t snd_ctl_ext_ops = {
	.close = snd_ctl_ext_close,
	.nonblock = snd_ctl_ext_nonblock,
	.async = snd_ctl_ext_async,
	.subscribe_events = snd_ctl_ext_subscribe_events,
	.card_info = snd_ctl_ext_card_info,
	.element_list = snd_ctl_ext_elem_list,
	.element_info = snd_ctl_ext_elem_info,
	.element_add = snd_ctl_ext_elem_add,
	.element_replace = snd_ctl_ext_elem_replace,
	.element_remove = snd_ctl_ext_elem_remove,
	.element_read = snd_ctl_ext_elem_read,
	.element_write = snd_ctl_ext_elem_write,
	.element_lock = snd_ctl_ext_elem_lock,
	.element_unlock = snd_ctl_ext_elem_unlock,
	.hwdep_next_device = snd_ctl_ext_next_device,
	.hwdep_info = snd_ctl_ext_hwdep_info,
	.pcm_next_device = snd_ctl_ext_next_device,
	.pcm_info = snd_ctl_ext_pcm_info,
	.pcm_prefer_subdevice = snd_ctl_ext_prefer_subdevice,
	.rawmidi_next_device = snd_ctl_rawmidi_next_device,
	.rawmidi_info = snd_ctl_ext_rawmidi_info,
	.rawmidi_prefer_subdevice = snd_ctl_ext_prefer_subdevice,
	.set_power_state = snd_ctl_ext_set_power_state,
	.get_power_state = snd_ctl_ext_get_power_state,
	.read = snd_ctl_ext_read,
	.poll_descriptors_count = snd_ctl_ext_poll_descriptors_count,
	.poll_descriptors = snd_ctl_ext_poll_descriptors,
	.poll_revents = snd_ctl_ext_poll_revents,
};

/*
 * Exported functions
 */

/*! \page ctl_external_plugins External Control Plugin SDK

\section ctl_externals External Control Plugins

The external plugins are implemented in a shared object file located
at /usr/lib/alsa-lib (the exact location depends on the build option
and asoundrc configuration).  It has to be the file like
libasound_module_ctl_MYPLUGIN.so, where MYPLUGIN corresponds to your
own plugin name.

The entry point of the plugin is defined via
#SND_CTL_PLUGIN_DEFINE_FUNC() macro.  This macro defines the function
with a proper name to be referred from alsa-lib.  The function takes
the following 5 arguments:
\code
int (snd_ctl_t **phandle, const char *name, snd_config_t *root,
	snd_config_t *conf, int mode)
\endcode
The first argument, phandle, is the pointer to store the resultant control
handle.  The arguments name, root and mode are the parameters
to be passed to the plugin constructor.  The conf is the configuration
tree for the plugin.  The arguments above are defined in the macro
itself, so don't use variables with the same names to shadow
parameters.

After parsing the configuration parameters in the given conf tree,
usually you will call the external plugin API function
#snd_ctl_ext_create().
The control handle must be filled *phandle in return.
Then this function must return either a value 0 when succeeded, or a
negative value as the error code. 

Finally, add #SND_CTL_PLUGIN_SYMBOL() with the name of your
plugin as the argument at the end.  This defines the proper versioned
symbol as the reference.

The typical code would look like below:
\code
struct myctl_info {
	snd_ctl_ext_t ext;
	int my_own_data;
	...
};

SND_CTL_PLUGIN_DEFINE_FUNC(myctl)
{
	snd_config_iterator_t i, next;
	struct myctl_info *myctl;
	int err;

	snd_config_for_each(i, next, conf) {
		snd_config_t *n = snd_config_iterator_entry(i);
		const char *id;
		if (snd_config_get_id(n, &id) < 0)
			continue;
		if (strcmp(id, "comment") == 0 || strcmp(id, "type") == 0)
			continue;
		if (strcmp(id, "my_own_parameter") == 0) {
			....
			continue;
		}
		SNDERR("Unknown field %s", id);
		return -EINVAL;
	}

	myctl = calloc(1, sizeof(*myctl));
	if (myctl == NULL)
		return -ENOMEM;

	myctl->ext.version = SND_CTL_EXT_VERSION;
	myctl->ext.card_idx = 0;
	strcpy(myctl->ext.id, "Myctl");
	strcpy(myctl->ext.name, "My Control");
	strcpy(myctl->ext.longname, "My External Control for Foobar");
	strcpy(myctl->ext.mixername, "My Control");
	myctl->ext.callback = &my_own_callback;
	myctl->ext.private_data = myctl;
	....

	err = snd_pcm_extplug_create(&myctl->ext, name, mode);
	if (err < 0) {
		myctl_free(myctl);
		return err;
	}

	*phandle = myctl->ext.handle;
	return 0;
}

SND_CTL_PLUGIN_SYMBOL(myctl);
\endcode

Read the codes in alsa-plugins package for the real examples.


\section ctl_ext_impl Implementation of External Control Plugins

The following fields have to be filled in external control record before calling
#snd_ctl_ext_create() : version, card_idx, id, name, longname, mixername, poll_fd and callback.
Otherfields are optional and should be initialized with zero.

The constant #SND_CTL_EXT_VERSION must be passed to the version
field for the version check in alsa-lib.  The card_idx field specifies the card
index of this control.  [FIXME: solve confliction of card index in alsa-lib?]

The id, name, longname and mixername fields are the strings shown in the card_info
inqurirys.  They are the char arrays, so you have to <i>copy</i> strings to these
fields.

The callback field contains the  table of callback functions for this plugin (defined as
#snd_ctl_ext_callback_t).
The poll_fd can be used to specify the poll file descriptor for this control.
Set -1 if not available.  Alternatively, you can define poll_descriptors_count and
poll_descriptors callbacks in the callback table for handling the poll descriptor(s)
dynamically after the creation of plugin instance.

The driver can set an arbitrary value (pointer) to private_data
field to refer its own data in the callbacks.

The rest fields are filled by #snd_ctl_ext_create().  The handle field
is the resultant PCM handle.  The others are the current status of the
PCM.

\section ctl_ext_impl Callback Functions of External Control Plugins

The callback functions in #snd_ctl_ext_callback_t define the real
behavior of the driver.  There are many callbacks but many of them are optional. 

The close callback is called when the PCM is closed.  If the plugin
allocates private resources, this is the place to release them
again.  This callback is optional.

The elem_count and elem_list callbacks are mandatory.  The elem_count returns the
total number of control elements.  The elem_list returns the control element ID
of the corresponding element offset (the offset is from 0 to elem_count - 1).
The id field is initialized to all zero in prior to elem_list callback.  The callback
has to fill the necessary field (typically iface, name and index) in return via the
standard control API functions like #snd_ctl_elem_id_set_ifarce,
#snd_ctl_elem_id_set_name and #snd_ctl_elem_id_set_index, etc.  The callbacks should
return 0 if successful, or a negative error code.

The find_elem callback is used to convert the given control element ID to the
certain key value for the faster access to get, read and write callbacks.
The key type is alias of unsigned long, so you can assign some static number
(e.g. index of the array) to this value of the corresponding element, or
assign the pointer (cast to #snd_ctl_ext_key_t).  When no key is defined or found,
return #SND_CTL_EXT_KEY_NOT_FOUND.  This callback is (very likely) required
if you use get, read and write callbacks as follows.
If you need to create a record dynamically (e.g. via malloc) at each find_elem call,
the allocated record can be released with the optional free_key callback.

The get_attribute is a mandatory callback, which returns the attribute of the 
control element given via a key value (converted with find_elem callback).
It must fill the control element type (#snd_ctl_elem_type_t), the access type
(#snd_ctl_ext_access_t), and the count (element array size).  The callback returns
0 if successful, or a negative error code, as usual.

The get_integer_info, get_integetr64_info and get_enumerated_info callbacks are called
to return the information of the given control element for each element type.
For integer and integer64 types, the callbacks need to fill the minimal (imin),
maximal (imax) and the step (istep) values of the control.  For the enumerated type,
the number of enum items must be filled.  Additionally, the enum control has to define
get_enumerated_name callback to store the name of the enumerated item of the given control
element.  All functions return 0 if successful, or a negative error code.

For reading the current values of a control element, read_integer, read_integer64,
read_enumerated, read_bytes and read_iec958 callbacks are called depending on the
element type.  These callbacks have to fill the current values of the element in return.
Note that a control element can be an array.  If it contains more than one values
(i.e. the count value in get_attribute callback is more than 1), <i>all</i> values
must be filled on the given value pointer as an array.  Also, note that the boolean type
is handled as integer here (although boolean type doesn't need to define the corresponding
info callback since it's obvious).  These callbacks return 0 if successful, or
a negative error code.

For writing the current values, write_integer, write_integer64, write_bytes, and
write_iec958 callbacks are called as well as for read.  The callbacks should check the
current values and compare with the given values.  If they are identical, the callbacks
should do nothing and return 0.  If they differ, update the current values and return 1,
instead.  For any errors, return a negative error code.

The subscribe_events callback is called when the application subscribes or cancels
the event notifications (e.g. through mixer API).  The current value of event
subscription is kept in the subscribed field.
The read_event callback is called for reading a pending notification event.
The callback needs to fill the event_mask value, a bit-field defined as SND_CTL_EVENT_MASK_XXX.
If no event is pending, return -EAGAIN.  These two callbacks are optional.

The poll_descriptors_count and poll_descriptors callbacks are used to return
the poll descriptor(s) via callbacks.  As already mentioned, if the callback cannot
set the static poll_fd, you can define these callbacks to return dynamically.
Also, when multiple poll descriptors are required, use these callbacks.
The poll_revents callback is used for handle poll revents.

*/

/**
 * \brief Create an external control plugin instance
 * \param ext the plugin handle
 * \param name name of control
 * \param mode control open mode
 * \return 0 if successful, or a negative error code
 *
 * Creates the external control instance.
 *
 */
int snd_ctl_ext_create(snd_ctl_ext_t *ext, const char *name, int mode)
{
	snd_ctl_t *ctl;
	int err;

	if (ext->version != SND_CTL_EXT_VERSION) {
		SNDERR("ctl_ext: Plugin version mismatch\n");
		return -ENXIO;
	}

	err = snd_ctl_new(&ctl, SND_CTL_TYPE_EXT, name);
	if (err < 0)
		return err;

	ext->handle = ctl;

	ctl->ops = &snd_ctl_ext_ops;
	ctl->private_data = ext;
	ctl->poll_fd = ext->poll_fd;
	if (mode & SND_CTL_NONBLOCK)
		ext->nonblock = 1;

	return 0;
}

/**
 * \brief Delete the external control plugin
 * \param ext the plugin handle
 * \return 0 if successful, or a negative error code
 */
int snd_ctl_ext_delete(snd_ctl_ext_t *ext)
{
	return snd_ctl_close(ext->handle);
}
