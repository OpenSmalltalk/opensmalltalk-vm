/*
 Copyright (c) 2009 Bert Freudenberg
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */


#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

UInt32 littleEndianUInt32(FILE *stream)
{
	UInt32 n;
	fread(&n, 4, 1, stream);
	return CFSwapInt32LittleToHost(n);
}

UInt16 littleEndianUInt16(FILE *stream)
{
	UInt16 n;
	fread(&n, 2, 1, stream);
	return CFSwapInt16LittleToHost(n);
}

/* We look for "thumbnail.png" in the zip which supposedly is a Squeak Etoys
 project file. We assume there is no comment appended (so the zip's EOCD is
 at a fixed offset from the file end) and the thumb is stored uncompressed
 (so we can pass its data directly to QuickLook) */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	char filename[FILENAME_MAX];
	CFURLGetFileSystemRepresentation (url, false, (UInt8*) filename, sizeof(filename));
	//printf("Filename: %s\n", filename);
	
	FILE *stream= fopen(filename, "r");
	
	char signature[4];
	
	/* Assuming no zip file comment, the End of Central Directory
	   signature starts 22 bytes from the end of the file */
	fseek(stream, -22, SEEK_END);
	fread(&signature, 4, 1, stream);
	
	if (0 == strncmp(signature, "PK\005\006", 4)) {
		fseek(stream, 8, SEEK_CUR);
		UInt32 centralDirectorySize= littleEndianUInt32(stream);
		/* go back to start of Central Directory */
		fseek(stream, -16-centralDirectorySize, SEEK_CUR);
		do {
			/* for each Central Directory entry */
			fread(&signature, 4, 1, stream);
			if (0 == strncmp(signature, "PK\001\002", 4)) {
				/* parse member */
				fseek(stream, 20, SEEK_CUR);
				UInt32 uncompressedSize= littleEndianUInt32(stream);
				UInt16 memberNameLength= littleEndianUInt16(stream);
				UInt16 extraFieldLength= littleEndianUInt16(stream);
				UInt16 commentLength= littleEndianUInt16(stream);
				fseek(stream, 8, SEEK_CUR);
				UInt32 memberPos= littleEndianUInt32(stream);
				char memberName[FILENAME_MAX];
				fread(&memberName, 1, memberNameLength, stream);
				memberName[memberNameLength]= '\000';
				fseek(stream, extraFieldLength + commentLength, SEEK_CUR);
				
				//printf("name: %s\n", memberName);
				//printf("offs: 0x%x\n", memberPos);
				//printf("size: %i\n", uncompressedSize);
				if (0 == strcmp(memberName, "thumbnail.png")) {
					char thumbBytes[20000];
					if (uncompressedSize > sizeof(thumbBytes))
						goto done;
					fseek(stream, memberPos+30+memberNameLength+extraFieldLength, SEEK_SET);
					/* assume thumbnail is stored unencrypted and uncompressed */
					fread(thumbBytes, uncompressedSize, 1, stream);
					if (0 == strncmp(thumbBytes, "\211PNG", 4)) {
						/* it worked! */
						//printf("PNG found!\n");
						CFDataRef thumbData= CFDataCreate(kCFAllocatorDefault, (UInt8*)thumbBytes, uncompressedSize);
						QLThumbnailRequestSetImageWithData(thumbnail, thumbData, NULL);				
					}
					/* whether it worked or not, we're done here */
					goto done;
				}
			} else {
				/* End of Central Directory */
				goto done;
			}
		} while (true);
	} else {
		//printf("End of Central Directory not found\n");
	}
	
done:
	
	fclose(stream);
	
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
}
