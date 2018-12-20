//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCFileDirectory.c
// It provides the Squeak directory related low-level calls

/* debugging stuff; uncommnet for debugging trace */
//#define DEBUG
#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osgbpb.h"
#include "oslib/osfile.h"
#include "oslib/osfscontrol.h"
#include "oslib/scsifs.h"
#include "oslib/adfs.h"
#include "oslib/ramfs.h"
#include "oslib/cdfs.h"
#include "oslib/territory.h"
#include "sq.h"
#include <kernel.h>


/*** Constants ***/
#define ENTRY_FOUND     0
#define NO_MORE_ENTRIES 1
#define BAD_PATH        2
#define DELIMITOR '.'


extern struct VirtualMachine * interpreterProxy;
char name[MAXDIRNAMELENGTH];
extern void sqStringFromFilename( char * sqString, char*fileName, int sqSize);


/*** Functions ***/

int convertToSqueakTime(os_date_and_time fileTime) {
/* Squeak epoch is Jan 1, 1901, one year later than the RiscOS
 * one @ 1/1/1900. fileTime is stored as 5 bytes of the centiseconds
 * since then. Use territory call to get timezone & DST offset  */
unsigned int high, low, tc;
char *tzname;
int tzoffset;
	low =  *(unsigned int*)fileTime;
	high = *(unsigned int*)(fileTime+4);

	high = high & 0xff; /* clear all but bottom byte */

	/* Firstly, subtract 365 * 24 *60 * 60 * 100 = 3153600000 = 0xBBF81E00
	 * centiseconds from the RISC OS time */
	tc = 0xBBF81E00;
	/* now use the territory to find the timezone/dst offset */
	xterritory_read_current_time_zone(&tzname, &tzoffset);
	if (low < tc) /* check for a carry */
		high--;
	low -= tc;

	/* Remove the centiseconds from the time.
	 * 0x1000000000 / 100 = 42949672.96 */
	low = (low / 100) + (high * 42949673U);
	low -= (high / 25); /* compensate for that 0.04 error.  */

	return (int)low + (tzoffset/100);
}

sqInt dir_Create(char *pathString, sqInt pathStringLength) {
	/* Create a new directory with the given path. By default, this
	   directory is created in the current directory. Use
	   a full path name to create directories elsewhere. */
	os_error *e;

	if (!canonicalizeFilenameToString(pathString, pathStringLength, name))
		return false;

	if ( (e = xosfile_create_dir( name, 0)) != NULL) {
		PRINTF(("\\t dir_Create: failed\n"));
		return false;
	}
	return true;
}

sqInt dir_Delete(char *pathString, sqInt pathStringLength) {
	/* Delete the existing directory with the given path. */
	/* For now replicate the normal sqFileDeleteNameSize, since that appears to be adequate, except for returning true if all is well - essential ! */

	if (!canonicalizeFilenameToString(pathString, pathStringLength, name))
		return false;

	if (remove(name) != 0) {
		PRINTF(("\\t dir_Delete error\n"));
		return false;
	}
	return true;
}

sqInt dir_Delimitor(void) {
	return DELIMITOR;
}

sqInt dir_LookupRoot(int context, char *fname, sqInt *fnameLength, sqInt *creationDate, sqInt *modificationDate, sqInt *isDirectory, sqInt *sizeIfFile) {
#define F2HJump 4
	int junk, run_total, adfs_flop=0, adfs_hard=0, scsifs_flop=0, scsifs_hard=0, ramfs_flop=0, ramfs_hard=0, cdfs_hard=0;
	char discid[20];
	char discname[MAXDIRNAMELENGTH];
	os_error * e;

	PRINTF(("\\t dir_Lookup:null pathname, scanning disc %d\n", context));
	/* no path, so try to enumerate all the attached discs */
	run_total = 0;
	xadfs_drives  (&junk, &adfs_flop,   &adfs_hard);
	if ( context < adfs_flop + run_total) {
		// it's an adfs floppy
		sprintf( discid, "ADFS::%d", context);
		goto decode_disc_id;
	}
	run_total += adfs_flop;
	if ( context < (adfs_flop + adfs_hard) ) {
		// it's an adfs hard disc
		sprintf( discid, "ADFS::%d", context - run_total + F2HJump);
		goto decode_disc_id;
	}
	run_total += adfs_hard;

	xscsifs_drives(&junk, &scsifs_flop, &scsifs_hard);
	if (  context < ( run_total + scsifs_flop) ) {
		// it's a scsifs floppy disc
		sprintf( discid, "SCSI::%d", context - run_total);
		goto decode_disc_id;
	}
	run_total += scsifs_flop;

	if (  context < (run_total + scsifs_hard) ) {
		// it's a scsifs hard disc
		sprintf( discid, "SCSI::%d", context - run_total + F2HJump);
		goto decode_disc_id;
	}
	run_total += scsifs_hard;

	xramfs_drives (&junk, &ramfs_flop,  &ramfs_hard);
	if (  context < ( run_total + ramfs_flop) ) {
		// it's a ramfs floppy disc
		sprintf( discid, "RAM::%d", context - run_total);
		goto decode_disc_id;
	}
	run_total += ramfs_flop;
	if (  context < (run_total + ramfs_hard) ) {
		// it's a ramfs hard disc
		sprintf( discid, "RAM::%d", context - run_total + F2HJump);
		goto decode_disc_id;
	}
	run_total += ramfs_hard;

	xcdfs_get_number_of_drives( &cdfs_hard);
	if (  context < (run_total + cdfs_hard) ) {
		// it's a cdfs hard disc
		sprintf( discid, "CDFS::%d", context - run_total);
		goto decode_disc_id;
	}
	return NO_MORE_ENTRIES;
decode_disc_id:
	PRINTF(("\\t dir_Lookup:found %s\n", discid));
	if ((e = xosfscontrol_canonicalise_path (discid, discname, (char const *) NULL, (char const *)NULL, MAXDIRNAMELENGTH, &junk)) != null) {
		// for any error, it seems best to copy the instring
		// to the outstring.
		// we shouldn't get too many types of error here since
		// the names have come from the OS anyway
		strcpy (discname, discid);
	}

	*fnameLength       = strlen(discname);
	sqStringFromFilename( fname, discname, *fnameLength);
	*creationDate     = 0;
	*modificationDate = 0;
	*isDirectory      = true;
	*sizeIfFile       = 0;
	return ENTRY_FOUND;
}

sqInt dir_Lookup(char *pathString, sqInt pathStringLength, sqInt index,
  /* outputs: */
  char *fname, sqInt *fnameLength, sqInt *creationDate, sqInt *modificationDate,
  sqInt *isDirectory, sqInt *sizeIfFile) {
/* Lookup the index-th entry of the directory with the given path, starting
   at the root of the file system. Set the name, name length, creation date,
   creation time, directory flag, and file size (if the entry is a file).
   Return:	ENTRY_FOUND	if a entry is found at the given index
   		NO_MORE_ENTRIES	if the directory has fewer than index entries
   		BAD_PATH	if the given path has bad syntax or does not reach a directory
	*/
	osgbpb_SYSTEM_INFO( MAXDIRNAMELENGTH + 4 ) buffer;
	int i, count, context;
	os_error * e;
	/* default return values */
	*fname             = 0;
	*fnameLength       = 0;
	*creationDate     = 0;
	*modificationDate = 0;
	*isDirectory      = false;
	*sizeIfFile       = 0;

	context = index - 1;
	PRINTF(("\\t dir_Lookup:raw pathname %s\n", pathString));

	if ( pathStringLength == 0) {
		// empty string for path implies find the mounted roots.
		return dir_LookupRoot(context, fname, fnameLength, creationDate, modificationDate, isDirectory, sizeIfFile);
	}

	if (!canonicalizeFilenameToString(pathString, pathStringLength, name))
		return BAD_PATH;

	PRINTF(("\\t dir_Lookup:pathName = %s\n", name));

	/* lookup indexth entry in the directory */
	count = 1;
	i = /* osgbpb_SIZEOF_SYSTEM_INFO(MAXDIRNAMELENGTH + 4)*/ 28 +MAXDIRNAMELENGTH + 4;

	e = xosgbpb_dir_entries_system_info(name,(osgbpb_system_info_list *)&buffer, count, context, i, (char const *)0, &count, &context);
	if ( e != NULL ) {
		int errnumber;
		errnumber = e->errnum & 0xFF;
		if ( errnumber >= 0xD3 && errnumber<= 0xD5 )  return NO_MORE_ENTRIES;
		return  BAD_PATH;
	}
	if ( count != 1 ) return NO_MORE_ENTRIES;

	*fnameLength = strlen(buffer.name);
	sqStringFromFilename( fname, buffer.name, *fnameLength);
	if (buffer.obj_type ==  fileswitch_IS_DIR
		|| buffer.obj_type == fileswitch_IS_IMAGE) {
		*isDirectory = true;
	} else {
		*isDirectory = false;
		*sizeIfFile =  buffer.size;
	}
	*creationDate = convertToSqueakTime(buffer.stamp);
	*modificationDate = *creationDate;
	return ENTRY_FOUND;
}


/* TPR addition to attempt to improve portability */
sqInt dir_SetMacFileTypeAndCreator(char * filename, sqInt filenamesize, char* type, char * owner) {
/* set the type and owner of the named file.
 * return true if ok, false otherwise.
 * filename is a Squeak filename string, so convert it to a C filename
 */

	bits ftype=0xFFD;
	if (strcmp(type, "TEXT")==0) ftype = (bits)0xFFF;
	if (strcmp(type, "STim") ==0) {
		/* this is likely to be a settype on the image file, so see if
		 * the name is already canonicalized. Copy it to the name buffer
		 * to make sure we have the terminator, find the first $ and see
		 * if it is surrounded by /  or .
		 */
		strncpy(name, filename, filenamesize);
		name[filenamesize] = null;
		PRINTF(("\\tsettype of %s \n", name));
		if (strstr(name, ".$.") ) {
			/* .$. is a strong hint that the name is already in RISC OS form */
			xosfile_set_type(name, (bits)0xFAA);
			return true;
		}
	}

	if (!canonicalizeFilenameToString(filename, filenamesize, name))
		return false;

	xosfile_set_type(name, (bits)ftype);

	return true;
}

sqInt dir_GetMacFileTypeAndCreator(char * filename, sqInt filenamesize, char* type, char * owner) {
/* tacky, tacky. Why this ridiculous dependence on Mac idiocies? */
	return false;
}

void dir_SetImageFileType(void) {
/* do whatever file type/creator/permission setting is needed for
 * the image file */
char * imageName = getImageName();
		xosfile_set_type(imageName, (bits)0xFAA);
}

/* extended protocol */

fileswitch_object_type fsobject_Exists(char* fname) {
bits load_addr, exec_addr, file_type;
fileswitch_attr attr;
fileswitch_object_type obj_type;
int length;
	xosfile_read_stamped_no_path(name,
		&obj_type, &load_addr, &exec_addr, &length, &attr, &file_type);
	/* if the obj_type is not-found, clear the buffer and return */
	return obj_type;
}

sqInt dir_DirectoryExists(char *pathString, sqInt pathStringLength) {
	/* Is there an existing directory with the given path? */

	/* copy the file name into a null-terminated C string */
	if (!canonicalizeFilenameToString(pathString, pathStringLength, name))
		return false;

	return (fsobject_Exists(name) == fileswitch_IS_DIR);
}

sqInt dir_FileExists(char *pathString, sqInt pathStringLength) {
	/* Is there an existing file with the given path? */

	/* copy the file name into a null-terminated C string */
	if (!canonicalizeFilenameToString(pathString, pathStringLength, name))
		return false;

	return (fsobject_Exists(name) == fileswitch_IS_FILE);
}
