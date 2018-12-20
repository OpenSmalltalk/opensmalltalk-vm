/* Based on code contributed by Tom Rushworth.
 * Mutilated beyond recognition by Ian Piumarta.
 * 
 * last edited: 2006-04-24 15:38:40 by piumarta on emilia.local
 */

#include <CoreServices/CoreServices.h>		/* see sqGetFilenameFromString() */

/* Answer nonzero if path describes an OS X alias file. */

static sqInt isMacAlias(char *path)
{
  Boolean  isAlias=  false;
  Boolean  isFolder= false;
  FSRef	   fileRef;		/* No need to dispose of this. */
  FSRef	  *frp= &fileRef;

  return (noErr == FSPathMakeRef((UInt8 *)path, frp, &isFolder))	/* POSIX path -> OS X FSRef */
    &&   (noErr == FSIsAliasFile(frp, &isAlias, &isFolder))		/* test for alias */
    &&   isAlias;
}


/* Resolve aliases in the src path leaving the result in dst.
   Answer nonzero if successful.
   Note: dst and src may refer to the same buffer. */

static sqInt resolveMacAlias(char *dst, char *src, sqInt max_length)
{
  Boolean wasAlias= false;
  Boolean isFolder= false;
  FSRef	  fileRef;	/* No need to dispose of this. */
  FSRef	 *frp= &fileRef;

  return (noErr == FSPathMakeRef((UInt8 *)src, frp, &isFolder))			/* POSIX path -> OS X FSRef */
    &&   (noErr == FSResolveAliasFileWithMountFlags(frp, true,			/* resolve */
						    &isFolder, &wasAlias,
						    kResolveAliasFileNoUI))
    &&   (noErr == FSRefMakePath(frp, (UInt8 *)dst, PATH_MAX));			/* resolved FSRef -> POSIX path */
}
