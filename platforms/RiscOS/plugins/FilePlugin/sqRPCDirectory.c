/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@sumeru.stanford.edu & http://sumeru.stanford.edu/tim              */
/*  Known to work on RiscOS 3.7 for StrongARM RPCs, other machines        */
/*  not yet tested.                                                       */
/*                       sqRPCDirec.c                                     */
/*  Directory reading etc                                                 */
/**************************************************************************/
#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osgbpb.h"
#include "oslib/osfile.h"
#include "oslib/osfscontrol.h"
#include "oslib/scsifs.h"
#include "oslib/adfs.h"
#include "oslib/ramfs.h"
#include "oslib/cdfs.h"
#include "sq.h"
#include <kernel.h>


/*** Constants ***/
#define ENTRY_FOUND     0
#define NO_MORE_ENTRIES 1
#define BAD_PATH        2
#define MAXDIRNAMELENGTH 1024

#define DELIMITOR '.'

/* debugging stuff; can probably be deleted */
//#define DEBUG

#ifdef DEBUG
#define FPRINTF(s)\
if(1){\
	extern os_error privateErr;\
	extern void platReportError( os_error * e);\
	privateErr.errnum = (bits)0;\
	sprintf s;\
	platReportError((os_error *)&privateErr);\
};
#else
# define FPRINTF(X)
#endif


extern struct VirtualMachine * interpreterProxy;
extern void sqStringFromFilename( int sqString, char*fileName, int sqSize);
/*** Functions ***/
int convertToSqueakTime(os_date_and_time fileTime);

int convertToSqueakTime(os_date_and_time fileTime) {
	/* Squeak epoch is Jan 1, 1901, one year later than RiscOS one @ 1/1/1900. fileTime is stored as 5 bytes of the centiseconds since then !  Arithmetic on 5byte numbers is simpler to do in float.... */
	float theTime;
	theTime  = 0.0;
	theTime = theTime + (int)*(fileTime++)*0.01;
	theTime = theTime + (int)*(fileTime++)*2.560;
	theTime = theTime + (int)*(fileTime++)*655.360;
	theTime = theTime + (int)*(fileTime++)*167772.160;
	theTime = theTime + (int)*(fileTime++)*42949672.960;
	theTime = theTime - (365.0  * 24 * 60 * 60);
	return (int)(unsigned long)theTime ;
}

void dirReportError( os_error * e) {
/* Use the RiscOS Error dialogue to notify users of some problem */
	extern void platReportError( os_error * e);
	platReportError(e);
}

int dir_Create(char *pathString, int pathStringLength) {
	/* Create a new directory with the given path. By default, this
	   directory is created in the current directory. Use
	   a full path name to create directories elsewhere. */
	char name[MAXDIRNAMELENGTH];
	os_error *e;

	if( pathStringLength > MAXDIRNAMELENGTH) return false;

	sqFilenameFromString( name, (int)pathString, pathStringLength);
	/* mkdir(name) */
	if ( (e = xosfile_create_dir( name, 0)) != NULL) {
		return false;
	}
	return true;
}

int dir_Delete(char *pathString, int pathStringLength) {
	/* Delete the existing directory with the given path. */
	/* For now replicate the normal sqFileDeleteNameSize, since that appears to be adequate, except for returning true if all is well - essential ! */
	char cFileName[MAXDIRNAMELENGTH];

	if (pathStringLength >= MAXDIRNAMELENGTH) {
		return interpreterProxy->success(false);
	}

	/* copy the file name into a null-terminated C string */
	sqFilenameFromString(cFileName, (int)pathString, pathStringLength);
	if (remove(cFileName) != 0) {
		FPRINTF((privateErr.errmess, "dir delete error\n"));
		return interpreterProxy->success(false);
	}
	return true;
}

int dir_Delimitor(void) {
	return DELIMITOR;
}

int dir_Lookup(char *pathString, int pathStringLength, int index,
  /* outputs: */
  char *name, int *nameLength, int *creationDate, int *modificationDate,
  int *isDirectory, int *sizeIfFile) {
/* Lookup the index-th entry of the directory with the given path, starting
   at the root of the file system. Set the name, name length, creation date,
   creation time, directory flag, and file size (if the entry is a file).
   Return:	ENTRY_FOUND	if a entry is found at the given index
   		NO_MORE_ENTRIES	if the directory has fewer than index entries
   		BAD_PATH	if the given path has bad syntax or does not reach a directory
	*/
	char dirname[MAXDIRNAMELENGTH];
	osgbpb_SYSTEM_INFO( MAXDIRNAMELENGTH + 4 ) buffer;
	int i, count, context;
	os_error * e;
	/* default return values */
	*name             = 0;
	*nameLength       = 0;
	*creationDate     = 0;
	*modificationDate = 0;
	*isDirectory      = false;
	*sizeIfFile       = 0;

	if( pathStringLength > MAXDIRNAMELENGTH) return BAD_PATH;
	context = index-1;
	FPRINTF((privateErr.errmess, "dir_Lookup:raw pathname %s\n", pathString));

	if ( pathStringLength == 0) {
#define F2HJump 4
int junk, run_total, adfs_flop=0, adfs_hard=0, scsifs_flop=0, scsifs_hard=0, ramfs_flop=0, ramfs_hard=0, cdfs_hard=0;
char discid[20];
		FPRINTF((privateErr.errmess, "dir_Lookup:null pathname, scanning disc %d\n", context));
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
		if ((e = xosfscontrol_canonicalise_path (discid, dirname, (char const *) NULL, (char const *)NULL, MAXDIRNAMELENGTH, &junk)) != null) {
			// for any error, it seems best to copy the instring
			// to the outstring.
			// we shouldn't get too many types of error here since
			// the names have come from the OS anyway
			strcpy (dirname, discid);
			// debugging -> dirReportError(e);
		}

		*nameLength       = strlen(dirname);
		sqStringFromFilename( (int)name, dirname, *nameLength);
		*creationDate     = 0;
		*modificationDate = 0;
		*isDirectory      = true;
		*sizeIfFile       = 0;
		return ENTRY_FOUND;
	}

	sqFilenameFromString(dirname, (int)pathString, pathStringLength);
	FPRINTF((privateErr.errmess, "dir_Lookup:pathName = %s\n", dirname));

	/* lookup indexth entry in the directory */
	count = 1;
	i = /* osgbpb_SIZEOF_SYSTEM_INFO(MAXDIRNAMELENGTH + 4)*/ 28 +MAXDIRNAMELENGTH + 4;

	e = xosgbpb_dir_entries_system_info(dirname,(osgbpb_system_info_list *)&buffer, count, context, i, (char const *)0, &count, &context);
	if ( e != NULL ) {
		// debugging-> dirReportError(e);
		i = e->errnum & 0xFF;
		if ( i >= 0xD3 && i<= 0xD5 )  return NO_MORE_ENTRIES;
		return  BAD_PATH;
	}
	if ( count != 1 ) return NO_MORE_ENTRIES;

	*nameLength = strlen(buffer.name);
	sqStringFromFilename( (int)name, buffer.name, *nameLength);
	if (buffer.obj_type ==2 || buffer.obj_type == 3) {
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
int dir_SetMacFileTypeAndCreator(char * filename, int filenamesize, char* type, char * owner) {
/* set the type and owner of  the named file. return true if ok, false otherwise. Arg MUST be a Squeak filename string, not a C filename string - it will end up mis-converting it to wrong dirseps! */

	bits ftype=0;
	char name[MAXDIRNAMELENGTH];
	if( filenamesize > MAXDIRNAMELENGTH) return false;
	if (strcmp(type, "TEXT")==0) ftype = (bits)0xFFF;

	if (strcmp(type, "STim")==0) {
		// if its for STim type, assume it was called from imagesave
		// and the filename was already correct format so use a
		// simple copy instead of the convertor
		copyNCharsFromTo( filenamesize, filename, name);
		ftype = (bits)0xFAA;
	} else {
		// for any other type, convert the filename
		sqFilenameFromString( name, (int)filename, filenamesize);
	}
	xosfile_set_type(name, (bits)ftype);

	return true;
}

int dir_GetMacFileTypeAndCreator(char * filename, int filenamesize, char* type, char * owner) {
/* tacky, tacky. Why this ridiculous dependence on Mac idiocies? */
	return false;
}




