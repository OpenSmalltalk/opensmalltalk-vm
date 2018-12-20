/////////////////////////////////////////////////////////////////////////
// $Id: hdimage.cc,v 1.16 2008/02/15 22:05:42 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2002  MandrakeSoft S.A.
//
//    MandrakeSoft S.A.
//    43, rue d'Aboukir
//    75002 Paris - France
//    http://www.linux-mandrake.com/
//    http://www.mandrakesoft.com/
//
//  This library is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2 of the License, or (at your option) any later version.
//
//  This library is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this library; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
/////////////////////////////////////////////////////////////////////////

// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE
// is used to know when we are exporting symbols and when we are importing.
#define BX_PLUGGABLE

#define NO_DEVICE_INCLUDES
#include "iodev.h"
#include "hdimage.h"

#if BX_HAVE_SYS_MMAN_H
#include <sys/mman.h>
#endif

#define LOG_THIS bx_devices.pluginHardDrive->

/*** base class device_image_t ***/

device_image_t::device_image_t()
{
  hd_size = 0;
}

/*** default_image_t function definitions ***/

int default_image_t::open(const char* pathname)
{
  return open(pathname, O_RDWR);
}

int default_image_t::open(const char* pathname, int flags)
{
#ifdef WIN32
  HANDLE hFile = CreateFile(pathname, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_FLAG_RANDOM_ACCESS, NULL);
  if (hFile != INVALID_HANDLE_VALUE) {
    ULARGE_INTEGER FileSize;
    FileSize.LowPart = GetFileSize(hFile, &FileSize.HighPart);
    CloseHandle(hFile);
    if ((FileSize.LowPart != INVALID_FILE_SIZE) || (GetLastError() == NO_ERROR)) {
      hd_size = FileSize.QuadPart;
    } else {
      return -1;
    }
  } else {
    return -1;
  }
#endif

  fd = ::open(pathname, flags
#ifdef O_BINARY
              | O_BINARY
#endif
              );

  if (fd < 0) {
    return fd;
  }

#ifndef WIN32
  /* look at size of image file to calculate disk geometry */
  struct stat stat_buf;
  int ret = fstat(fd, &stat_buf);
  if (ret) {
    BX_PANIC(("fstat() returns error!"));
  }
  hd_size = (Bit64u)stat_buf.st_size;
#endif
  if ((hd_size % 512) != 0) {
    BX_PANIC(("size of disk image must be multiple of 512 bytes"));
  }

  return fd;
}

void default_image_t::close()
{
  if (fd > -1) {
    ::close(fd);
  }
}

Bit64s default_image_t::lseek(Bit64s offset, int whence)
{
  return (Bit64s)::lseek(fd, (off_t)offset, whence);
}

ssize_t default_image_t::read(void* buf, size_t count)
{
  return ::read(fd, (char*) buf, count);
}

ssize_t default_image_t::write(const void* buf, size_t count)
{
  return ::write(fd, (char*) buf, count);
}

char increment_string(char *str, int diff)
{
  // find the last character of the string, and increment it.
  char *p = str;
  while (*p != 0) p++;
  BX_ASSERT(p>str);  // choke on zero length strings
  p--;  // point to last character of the string
  (*p) += diff;  // increment to next/previous ascii code.
  BX_DEBUG(("increment string returning '%s'", str));
 return (*p);
}

/*** concat_image_t function definitions ***/

concat_image_t::concat_image_t()
{
  fd = -1;
}

void concat_image_t::increment_string(char *str)
{
 ::increment_string(str, +1);
}

int concat_image_t::open(const char* pathname0)
{
  char *pathname = strdup(pathname0);
  BX_DEBUG(("concat_image_t.open"));
  Bit64s start_offset = 0;
  for (int i=0; i<BX_CONCAT_MAX_IMAGES; i++) {
    fd_table[i] = ::open(pathname, O_RDWR
#ifdef O_BINARY
		| O_BINARY
#endif
	  );
    if (fd_table[i] < 0) {
      // open failed.
      // if no FD was opened successfully, return -1 (fail).
      if (i==0) return -1;
      // otherwise, it only means that all images in the series have
      // been opened.  Record the number of fds opened successfully.
      maxfd = i;
      break;
    }
    BX_DEBUG(("concat_image: open image %s, fd[%d] = %d", pathname, i, fd_table[i]));
    /* look at size of image file to calculate disk geometry */
    struct stat stat_buf;
    int ret = fstat(fd_table[i], &stat_buf);
    if (ret) {
      BX_PANIC(("fstat() returns error!"));
    }
#ifdef S_ISBLK
    if (S_ISBLK(stat_buf.st_mode)) {
      BX_PANIC(("block devices should REALLY NOT be used as concat images"));
    }
#endif
    if ((stat_buf.st_size % 512) != 0) {
      BX_PANIC(("size of disk image must be multiple of 512 bytes"));
    }
    length_table[i] = stat_buf.st_size;
    start_offset_table[i] = start_offset;
    start_offset += stat_buf.st_size;
    increment_string(pathname);
  }
  // start up with first image selected
  index = 0;
  fd = fd_table[0];
  thismin = 0;
  thismax = length_table[0]-1;
  seek_was_last_op = 0;
  hd_size = start_offset;
  return 0; // success.
}

void concat_image_t::close()
{
  BX_DEBUG(("concat_image_t.close"));
  if (fd > -1) {
    ::close(fd);
  }
}

Bit64s concat_image_t::lseek(Bit64s offset, int whence)
{
  if ((offset % 512) != 0)
    BX_PANIC(("lseek HD with offset not multiple of 512"));
  BX_DEBUG(("concat_image_t.lseek(%d)", whence));
  // is this offset in this disk image?
  if (offset < thismin) {
    // no, look at previous images
    for (int i=index-1; i>=0; i--) {
      if (offset >= start_offset_table[i]) {
	index = i;
	fd = fd_table[i];
	thismin = start_offset_table[i];
	thismax = thismin + length_table[i] - 1;
	BX_DEBUG(("concat_image_t.lseek to earlier image, index=%d", index));
	break;
      }
    }
  } else if (offset > thismax) {
    // no, look at later images
    for (int i=index+1; i<maxfd; i++) {
      if (offset < start_offset_table[i] + length_table[i]) {
	index = i;
	fd = fd_table[i];
	thismin = start_offset_table[i];
	thismax = thismin + length_table[i] - 1;
	BX_DEBUG(("concat_image_t.lseek to earlier image, index=%d", index));
	break;
      }
    }
  }
  // now offset should be within the current image.
  offset -= start_offset_table[index];
  if (offset < 0 || offset >= length_table[index]) {
    BX_PANIC(("concat_image_t.lseek to byte %ld failed", (long)offset));
    return -1;
  }

  seek_was_last_op = 1;
  return (Bit64s)::lseek(fd, (off_t)offset, whence);
}

ssize_t concat_image_t::read(void* buf, size_t count)
{
  if (bx_dbg.disk)
    BX_DEBUG(("concat_image_t.read %ld bytes", (long)count));
  // notice if anyone does sequential read or write without seek in between.
  // This can be supported pretty easily, but needs additional checks for
  // end of a partial image.
  if (!seek_was_last_op)
    BX_PANIC(("no seek before read"));
  return ::read(fd, (char*) buf, count);
}

ssize_t concat_image_t::write(const void* buf, size_t count)
{
  BX_DEBUG(("concat_image_t.write %ld bytes", (long)count));
  // notice if anyone does sequential read or write without seek in between.
  // This can be supported pretty easily, but needs additional checks for
  // end of a partial image.
  if (!seek_was_last_op)
    BX_PANIC(("no seek before write"));
  return ::write(fd, (char*) buf, count);
}

/*** sparse_image_t function definitions ***/

sparse_image_t::sparse_image_t ()
{
  fd = -1;
  pathname = NULL;
#ifdef _POSIX_MAPPED_FILES
  mmap_header = NULL;
#endif
  pagetable = NULL;
}

/*
void showpagetable(Bit32u * pagetable, size_t numpages)
{
 printf("Non null pages: ");
 for (int i = 0; i < numpages; i++)
 {
   if (pagetable[i] != 0xffffffff)
   {
     printf("%d ", i);
   }
 }
 printf("\n");
}
*/

void sparse_image_t::read_header()
{
 BX_ASSERT(sizeof(header) == SPARSE_HEADER_SIZE);

 int ret = ::read(fd, &header, sizeof(header));

 if (-1 == ret)
 {
     panic(strerror(errno));
 }

 if (sizeof(header) != ret)
 {
   panic("could not read entire header");
 }

 if (dtoh32(header.magic) != SPARSE_HEADER_MAGIC)
 {
   panic("failed header magic check");
 }

 if ((dtoh32(header.version) != SPARSE_HEADER_VERSION) &&
     (dtoh32(header.version) != SPARSE_HEADER_V1))
 {
   panic("unknown version in header");
 }

 pagesize = dtoh32(header.pagesize);
 Bit32u numpages = dtoh32(header.numpages);

 total_size = pagesize;
 total_size *= numpages;

 pagesize_shift = 0;
 while ((pagesize >> pagesize_shift) > 1) pagesize_shift++;

 if ((Bit32u)(1 << pagesize_shift) != pagesize)
 {
   panic("failed block size header check");
 }

 pagesize_mask = pagesize - 1;

 size_t  preamble_size = (sizeof(Bit32u) * numpages) + sizeof(header);
 data_start = 0;
 while ((size_t)data_start < preamble_size) data_start += pagesize;

 bx_bool did_mmap = 0;

#ifdef _POSIX_MAPPED_FILES
// Try to memory map from the beginning of the file (0 is trivially a page multiple)
 void * mmap_header = mmap(NULL, preamble_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
 if (mmap_header == MAP_FAILED)
 {
   BX_INFO(("failed to mmap sparse disk file - using conventional file access"));
   mmap_header = NULL;
 }
 else
 {
   mmap_length = preamble_size;
   did_mmap = 1;
   pagetable = ((Bit32u *) (((Bit8u *) mmap_header) + sizeof(header)));
   system_pagesize_mask = getpagesize() - 1;
 }
#endif

 if (!did_mmap)
 {
   pagetable = new Bit32u[numpages];

   if (pagetable == NULL)
   {
     panic("could not allocate memory for sparse disk block table");
   }

   ret = ::read(fd, pagetable, sizeof(Bit32u) * numpages);

   if (-1 == ret)
   {
       panic(strerror(errno));
   }

   if ((int)(sizeof(Bit32u) * numpages) != ret)
   {
     panic("could not read entire block table");
   }
 }
}

int sparse_image_t::open (const char* pathname0)
{
  pathname = strdup(pathname0);
  BX_DEBUG(("sparse_image_t.open"));

  fd = ::open(pathname, O_RDWR
#ifdef O_BINARY
   | O_BINARY
#endif
   );

  if (fd < 0)
  {
    return -1; // open failed
  }
  BX_DEBUG(("sparse_image: open image %s", pathname));

  read_header();

  struct stat stat_buf;
  if (fstat(fd, &stat_buf) != 0) panic(("fstat() returns error!"));

  underlying_filesize = stat_buf.st_size;

  if ((underlying_filesize % pagesize) != 0)
    panic("size of sparse disk image is not multiple of page size");

  underlying_current_filepos = 0;
  if (-1 == ::lseek(fd, 0, SEEK_SET))
    panic("error while seeking to start of file");

  lseek(0, SEEK_SET);

  //showpagetable(pagetable, header.numpages);

  char * parentpathname = strdup(pathname);
  char lastchar = ::increment_string(parentpathname, -1);

  if ((lastchar >= '0') && (lastchar <= '9'))
  {
    struct stat stat_buf;
    if (0 == stat(parentpathname, &stat_buf))
    {
      parent_image = new sparse_image_t();
      int ret = parent_image->open(parentpathname);
      if (ret != 0) return ret;
      if (    (parent_image->pagesize != pagesize)
          ||  (parent_image->total_size != total_size))
      {
        panic("child drive image does not have same page count/page size configuration");
      }
    }
  }

  if (parentpathname != NULL) free(parentpathname);

  if (dtoh32(header.version) == SPARSE_HEADER_VERSION) {
    hd_size = dtoh64(header.disk);
  }

  return 0; // success
}

void sparse_image_t::close()
{
  BX_DEBUG(("concat_image_t.close"));
  if (pathname != NULL)
  {
    free(pathname);
  }
#ifdef _POSIX_MAPPED_FILES
  if (mmap_header != NULL)
  {
    int ret = munmap(mmap_header, mmap_length);
    if (ret != 0)
      BX_INFO(("failed to un-memory map sparse disk file"));
  }
  pagetable = NULL; // We didn't malloc it
#endif
  if (fd > -1) {
    ::close(fd);
  }
  if (pagetable != NULL)
  {
    delete [] pagetable;
  }
  if (parent_image != NULL)
  {
    delete parent_image;
  }
}

Bit64s sparse_image_t::lseek(Bit64s offset, int whence)
{
  //showpagetable(pagetable, header.numpages);

  if ((offset % 512) != 0)
    BX_PANIC(("lseek HD with offset not multiple of 512"));
  if (whence != SEEK_SET)
    BX_PANIC(("lseek HD with whence not SEEK_SET"));

  BX_DEBUG(("sparse_image_t.lseek(%d)", whence));

  if (offset > total_size)
  {
    BX_PANIC(("sparse_image_t.lseek to byte %ld failed", (long)offset));
    return -1;
  }

  //printf("Seeking to position %ld\n", (long) offset);

  set_virtual_page((Bit32u)(offset >> pagesize_shift));
  position_page_offset = (Bit32u)(offset & pagesize_mask);

  return 0;
}

inline Bit64s sparse_image_t::get_physical_offset()
{
  Bit64s physical_offset = data_start;
  physical_offset += ((Bit64s)position_physical_page << pagesize_shift);
  physical_offset += position_page_offset;
  return physical_offset;
}

void sparse_image_t::set_virtual_page(Bit32u new_virtual_page)
{
  position_virtual_page = new_virtual_page;
  position_physical_page = dtoh32(pagetable[position_virtual_page]);
}

ssize_t sparse_image_t::read_page_fragment(Bit32u read_virtual_page, Bit32u read_page_offset, size_t read_size, void * buf)
{
  if (read_virtual_page != position_virtual_page)
  {
    set_virtual_page(read_virtual_page);
  }

  position_page_offset = read_page_offset;

  if (position_physical_page == SPARSE_PAGE_NOT_ALLOCATED)
  {
    if (parent_image != NULL)
    {
      return parent_image->read_page_fragment(read_virtual_page, read_page_offset, read_size, buf);
    }
    else
    {
      memset(buf, 0, read_size);
    }
  }
  else
  {
    Bit64s physical_offset = get_physical_offset();

    if (physical_offset != underlying_current_filepos)
    {
      off_t ret = ::lseek(fd, (off_t)physical_offset, SEEK_SET);
      // underlying_current_filepos update deferred
      if (ret == -1)
        panic(strerror(errno));
    }

    //printf("Reading %s at position %ld size %d\n", pathname, (long) physical_offset, (long) read_size);
    ssize_t readret = ::read(fd, buf, read_size);

    if (readret == -1)
    {
      panic(strerror(errno));
    }

    if ((size_t)readret != read_size)
    {
      panic("could not read block contents from file");
    }

    underlying_current_filepos = physical_offset + read_size;
  }

  return read_size;
}

ssize_t sparse_image_t::read(void* buf, size_t count)
{
  //showpagetable(pagetable, header.numpages);
  ssize_t total_read = 0;

  if (bx_dbg.disk)
    BX_DEBUG(("sparse_image_t.read %ld bytes", (long)count));

  while (count != 0)
  {
    size_t can_read = pagesize - position_page_offset;
    if (count < can_read) can_read = count;

    BX_ASSERT (can_read != 0);

    size_t was_read = read_page_fragment(position_virtual_page, position_page_offset, can_read, buf);

    BX_ASSERT(was_read == can_read);

    total_read += can_read;

    position_page_offset += can_read;
    if (position_page_offset == pagesize)
    {
      position_page_offset = 0;
      set_virtual_page(position_virtual_page + 1);
    }

    BX_ASSERT(position_page_offset < pagesize);

    buf = (((Bit8u *) buf) + can_read);
    count -= can_read;
  }

  return total_read;
}

void sparse_image_t::panic(const char * message)
{
  char buffer[1024];
  if (message == NULL)
  {
    snprintf(buffer, sizeof(buffer), "error with sparse disk image %s", pathname);
  }
  else
  {
    snprintf(buffer, sizeof(buffer), "error with sparse disk image %s - %s", pathname, message);
  }
  BX_PANIC((buffer));
}

ssize_t sparse_image_t::write (const void* buf, size_t count)
{
  //showpagetable(pagetable, header.numpages);

  ssize_t total_written = 0;

  Bit32u update_pagetable_start = position_virtual_page;
  Bit32u update_pagetable_count = 0;

  if (bx_dbg.disk)
    BX_DEBUG(("sparse_image_t.write %ld bytes", (long)count));

  while (count != 0)
  {
    size_t can_write = pagesize - position_page_offset;
    if (count < can_write) can_write = count;

    BX_ASSERT (can_write != 0);

    if (position_physical_page == SPARSE_PAGE_NOT_ALLOCATED)
    {
      // We just add on another page at the end of the file
      // Reclamation, compaction etc should currently be done off-line

      Bit64s data_size = underlying_filesize - data_start;
      BX_ASSERT((data_size % pagesize) == 0);

      Bit32u data_size_pages = (Bit32u)(data_size / pagesize);
      Bit32u next_data_page = data_size_pages;

      pagetable[position_virtual_page] = htod32(next_data_page);
      position_physical_page = next_data_page;

      Bit64s page_file_start = data_start + ((Bit64s)position_physical_page << pagesize_shift);

      if (parent_image != NULL)
      {
        // If we have a parent, we must merge our portion with the parent
        void *writebuffer = NULL;

        if (can_write == pagesize)
        {
          writebuffer = (void *) buf;
        }
        else
        {
          writebuffer = malloc(pagesize);
          if (writebuffer == NULL)
            panic("Cannot allocate sufficient memory for page-merge in write");

          // Read entire page - could optimize, but simple for now
          parent_image->read_page_fragment(position_virtual_page, 0, pagesize, writebuffer);

          void *dest_start = ((Bit8u *) writebuffer) + position_page_offset;
          memcpy(dest_start, buf, can_write);
        }

        int ret = (int)::lseek(fd, page_file_start, SEEK_SET);
        // underlying_current_filepos update deferred
        if (ret == -1) panic(strerror(errno));

        ret = ::write(fd, writebuffer, pagesize);
        if (ret == -1) panic(strerror(errno));

        if (pagesize != (Bit32u)ret) panic("failed to write entire merged page to disk");

        if (can_write != pagesize)
        {
          free(writebuffer);
        }
      }
      else
      {
        // We need to write a zero page because read has been returning zeroes
        // We seek as close to the page end as possible, and then write a little
        // This produces a sparse file which has blanks
        // Also very quick, even when pagesize is massive
        int ret = (int)::lseek(fd, page_file_start + pagesize - 4, SEEK_SET);
        // underlying_current_filepos update deferred
        if (ret == -1) panic(strerror(errno));

        Bit32u zero = 0;
        ret = ::write(fd, &zero, 4);
        if (ret == -1) panic(strerror(errno));

        if (ret != 4) panic("failed to write entire blank page to disk");
      }

      update_pagetable_count = (position_virtual_page - update_pagetable_start) + 1;
      underlying_filesize = underlying_current_filepos = page_file_start + pagesize;
    }

    BX_ASSERT(position_physical_page != SPARSE_PAGE_NOT_ALLOCATED);

    Bit64s physical_offset = get_physical_offset();

    if (physical_offset != underlying_current_filepos)
    {
      off_t ret = ::lseek(fd, (off_t)physical_offset, SEEK_SET);
      // underlying_current_filepos update deferred
      if (ret == -1)
        panic(strerror(errno));
    }

    //printf("Writing at position %ld size %d\n", (long) physical_offset, can_write);
    ssize_t writeret = ::write(fd, buf, can_write);

    if (writeret == -1)
    {
      panic(strerror(errno));
    }

    if ((size_t)writeret != can_write)
    {
      panic("could not write block contents to file");
    }

    underlying_current_filepos = physical_offset + can_write;

    total_written += can_write;

    position_page_offset += can_write;
    if (position_page_offset == pagesize)
    {
      position_page_offset = 0;
      set_virtual_page(position_virtual_page + 1);
    }

    BX_ASSERT(position_page_offset < pagesize);

    buf = (((Bit8u *) buf) + can_write);
    count -= can_write;
  }

  if (update_pagetable_count != 0)
  {
    bx_bool done = 0;
    off_t pagetable_write_from = sizeof(header) + (sizeof(Bit32u) * update_pagetable_start);
    size_t write_bytecount = update_pagetable_count * sizeof(Bit32u);

#ifdef _POSIX_MAPPED_FILES
    if (mmap_header != NULL)
    {
      // Sync from the beginning of the page
      size_t system_page_offset = pagetable_write_from & system_pagesize_mask;
      void *start = ((Bit8u *) mmap_header + pagetable_write_from - system_page_offset);

      int ret = msync(start, system_page_offset + write_bytecount, MS_ASYNC);

      if (ret != 0)
        panic(strerror(errno));

      done = 1;
    }
#endif

    if (!done)
    {
      int ret = (int)::lseek(fd, pagetable_write_from, SEEK_SET);
      // underlying_current_filepos update deferred
      if (ret == -1) panic(strerror(errno));

      //printf("Writing header at position %ld size %ld\n", (long) pagetable_write_from, (long) write_bytecount);
      ret = ::write(fd, &pagetable[update_pagetable_start], write_bytecount);
      if (ret == -1) panic(strerror(errno));
      if ((size_t)ret != write_bytecount) panic("could not write entire updated block header");

      underlying_current_filepos = pagetable_write_from + write_bytecount;
    }
  }

  return total_written;
}

#if DLL_HD_SUPPORT

/*** dll_image_t function definitions ***/

/*
function vdisk_open(path:PChar;numclusters,clustersize:integer):integer;
procedure vdisk_read(vunit:integer;blk:integer;var buf:TBlock);
procedure vdisk_write(vunit:integer;blk:integer;var buf:TBlock);
procedure vdisk_close(vunit:integer);
*/

HINSTANCE hlib_vdisk = 0;

int (*vdisk_open)  (const char *path,int numclusters,int clustersize);
void (*vdisk_read)   (int vunit,int blk,void *buf);
void (*vdisk_write)  (int vunit,int blk,const void *buf);
void (*vdisk_close) (int vunit);

int dll_image_t::open (const char* pathname)
{
  if (hlib_vdisk == 0) {
    hlib_vdisk = LoadLibrary("vdisk.dll");
    if (hlib_vdisk != 0) {
      vdisk_read = (void (*)(int,int,void*))        GetProcAddress(hlib_vdisk,"vdisk_read");
      vdisk_write = (void (*)(int,int,const void*)) GetProcAddress(hlib_vdisk,"vdisk_write");
      vdisk_open = (int (*)(const char *,int,int))  GetProcAddress(hlib_vdisk,"vdisk_open");
      vdisk_close = (void (*)(int))                 GetProcAddress(hlib_vdisk,"vdisk_close");
    }
  }
  if (hlib_vdisk != 0) {
    vunit = vdisk_open(pathname,0x10000,64);
    vblk = 0;
  } else {
    vunit = -2;
  }
  return vunit;
}

void dll_image_t::close ()
{
  if (vunit >= 0 && hlib_vdisk != 0) {
    vdisk_close(vunit);
  }
}

Bit64s dll_image_t::lseek(Bit64s offset, int whence)
{
  vblk = (int)(offset >> 9);
  return 0;
}

ssize_t dll_image_t::read (void* buf, size_t count)
{
  if (vunit >= 0 && hlib_vdisk != 0) {
    vdisk_read(vunit,vblk,buf);
    return count;
  } else {
    return -1;
  }
}

ssize_t dll_image_t::write (const void* buf, size_t count)
{
  if (vunit >= 0 && hlib_vdisk != 0) {
    vdisk_write(vunit,vblk,buf);
    return count;
  } else {
    return -1;
  }
}
#endif // DLL_HD_SUPPORT

// redolog implementation
redolog_t::redolog_t()
{
  fd = -1;
  catalog = NULL;
  bitmap = NULL;
  extent_index = (Bit32u)0;
  extent_offset = (Bit32u)0;
  extent_next = (Bit32u)0;
}

void redolog_t::print_header()
{
  BX_INFO(("redolog : Standard Header : magic='%s', type='%s', subtype='%s', version = %d.%d",
           header.standard.magic, header.standard.type, header.standard.subtype,
           dtoh32(header.standard.version)/0x10000,
           dtoh32(header.standard.version)%0x10000));
  if (dtoh32(header.standard.version) == STANDARD_HEADER_VERSION) {
    BX_INFO(("redolog : Specific Header : #entries=%d, bitmap size=%d, exent size = %d disk size = " FMT_LL "d",
             dtoh32(header.specific.catalog),
             dtoh32(header.specific.bitmap),
             dtoh32(header.specific.extent),
             dtoh64(header.specific.disk)));
  } else if (dtoh32(header.standard.version) == STANDARD_HEADER_V1) {
    redolog_header_v1_t header_v1;
    memcpy(&header_v1, &header, STANDARD_HEADER_SIZE);
    BX_INFO(("redolog : Specific Header : #entries=%d, bitmap size=%d, exent size = %d disk size = " FMT_LL "d",
             dtoh32(header_v1.specific.catalog),
             dtoh32(header_v1.specific.bitmap),
             dtoh32(header_v1.specific.extent),
             dtoh64(header_v1.specific.disk)));
  }
}

int redolog_t::make_header(const char* type, Bit64u size)
{
  Bit32u entries, extent_size, bitmap_size;
  Bit64u maxsize;
  Bit32u flip=0;

  // Set standard header values
  strcpy((char*)header.standard.magic, STANDARD_HEADER_MAGIC);
  strcpy((char*)header.standard.type, REDOLOG_TYPE);
  strcpy((char*)header.standard.subtype, type);
  header.standard.version = htod32(STANDARD_HEADER_VERSION);
  header.standard.header = htod32(STANDARD_HEADER_SIZE);

  entries = 512;
  bitmap_size = 1;

  // Compute #entries and extent size values
  do {
    extent_size = 8 * bitmap_size * 512;

    header.specific.catalog = htod32(entries);
    header.specific.bitmap = htod32(bitmap_size);
    header.specific.extent = htod32(extent_size);

    maxsize = (Bit64u)entries * (Bit64u)extent_size;

    flip++;

    if(flip&0x01) bitmap_size *= 2;
    else entries *= 2;
  } while (maxsize < size);

  header.specific.disk = htod64(size);

  print_header();

  catalog = (Bit32u*)malloc(dtoh32(header.specific.catalog) * sizeof(Bit32u));
  bitmap = (Bit8u*)malloc(dtoh32(header.specific.bitmap));

  if ((catalog == NULL) || (bitmap==NULL))
    BX_PANIC(("redolog : could not malloc catalog or bitmap"));

  for (Bit32u i=0; i<dtoh32(header.specific.catalog); i++)
    catalog[i] = htod32(REDOLOG_PAGE_NOT_ALLOCATED);

  bitmap_blocs = 1 + (dtoh32(header.specific.bitmap) - 1) / 512;
  extent_blocs = 1 + (dtoh32(header.specific.extent) - 1) / 512;

  BX_DEBUG(("redolog : each bitmap is %d blocs", bitmap_blocs));
  BX_DEBUG(("redolog : each extent is %d blocs", extent_blocs));

  return 0;
}

int redolog_t::create(const char* filename, const char* type, Bit64u size)
{
  BX_INFO(("redolog : creating redolog %s", filename));

  int filedes = ::open(filename, O_RDWR | O_CREAT | O_TRUNC
#ifdef O_BINARY
            | O_BINARY
#endif
            , S_IWUSR | S_IRUSR | S_IRGRP | S_IWGRP);

  return create(filedes, type, size);
}

int redolog_t::create(int filedes, const char* type, Bit64u size)
{
  fd = filedes;

  if (fd < 0)
  {
    return -1; // open failed
  }

  if (make_header(type, size) < 0)
  {
    return -1;
  }

  // Write header
  ::write(fd, &header, dtoh32(header.standard.header));

  // Write catalog
  // FIXME could mmap
  ::write(fd, catalog, dtoh32(header.specific.catalog) * sizeof (Bit32u));

  return 0;
}

int redolog_t::open(const char* filename, const char *type)
{
  fd = ::open(filename, O_RDWR
#ifdef O_BINARY
              | O_BINARY
#endif
              );
  if (fd < 0)
  {
    BX_INFO(("redolog : could not open image %s", filename));
    // open failed.
    return -1;
  }
  BX_INFO(("redolog : open image %s", filename));

  int res = ::read(fd, &header, sizeof(header));
  if (res != STANDARD_HEADER_SIZE)
  {
    BX_PANIC(("redolog : could not read header"));
    return -1;
  }

  print_header();

  if (strcmp((char*)header.standard.magic, STANDARD_HEADER_MAGIC) != 0)
  {
    BX_PANIC(("redolog : Bad header magic"));
    return -1;
  }

  if (strcmp((char*)header.standard.type, REDOLOG_TYPE) != 0)
  {
    BX_PANIC(("redolog : Bad header type"));
    return -1;
  }
  if (strcmp((char*)header.standard.subtype, type) != 0)
  {
    BX_PANIC(("redolog : Bad header subtype"));
    return -1;
  }

  if ((dtoh32(header.standard.version) != STANDARD_HEADER_VERSION) &&
      (dtoh32(header.standard.version) != STANDARD_HEADER_V1))
  {
    BX_PANIC(("redolog : Bad header version"));
    return -1;
  }

  if (dtoh32(header.standard.version) == STANDARD_HEADER_V1) {
    redolog_header_v1_t header_v1;

    memcpy(&header_v1, &header, STANDARD_HEADER_SIZE);
    header.specific.disk = header_v1.specific.disk;
  }

  catalog = (Bit32u*)malloc(dtoh32(header.specific.catalog) * sizeof(Bit32u));

  // FIXME could mmap
  ::lseek(fd,dtoh32(header.standard.header),SEEK_SET);
  res = ::read(fd, catalog, dtoh32(header.specific.catalog) * sizeof(Bit32u));

  if (res !=  (ssize_t)(dtoh32(header.specific.catalog) * sizeof(Bit32u)))
  {
    BX_PANIC(("redolog : could not read catalog %d=%d",res, dtoh32(header.specific.catalog)));
    return -1;
  }

  // check last used extent
  extent_next = 0;
  for (Bit32u i=0; i < dtoh32(header.specific.catalog); i++)
  {
    if (dtoh32(catalog[i]) != REDOLOG_PAGE_NOT_ALLOCATED)
    {
      if (dtoh32(catalog[i]) >= extent_next)
        extent_next = dtoh32(catalog[i]) + 1;
    }
  }
  BX_INFO(("redolog : next extent will be at index %d",extent_next));

  // memory used for storing bitmaps
  bitmap = (Bit8u *)malloc(dtoh32(header.specific.bitmap));

  bitmap_blocs = 1 + (dtoh32(header.specific.bitmap) - 1) / 512;
  extent_blocs = 1 + (dtoh32(header.specific.extent) - 1) / 512;

  BX_DEBUG(("redolog : each bitmap is %d blocs", bitmap_blocs));
  BX_DEBUG(("redolog : each extent is %d blocs", extent_blocs));

  return 0;
}

void redolog_t::close()
{
  if (fd >= 0)
    ::close(fd);

  if (catalog != NULL)
    free(catalog);

  if (bitmap != NULL)
    free(bitmap);
}

Bit64u redolog_t::get_size()
{
  return dtoh64(header.specific.disk);
}

Bit64s redolog_t::lseek(Bit64s offset, int whence)
{
  if ((offset % 512) != 0) {
    BX_PANIC(("redolog : lseek HD with offset not multiple of 512"));
    return -1;
  }
  if (whence != SEEK_SET) {
    BX_PANIC(("redolog : lseek HD with whence not SEEK_SET"));
    return -1;
  }
  if (offset > (Bit64s)dtoh64(header.specific.disk))
  {
    BX_PANIC(("redolog : lseek to byte %ld failed", (long)offset));
    return -1;
  }

  extent_index = (Bit32u)(offset / dtoh32(header.specific.extent));
  extent_offset = (Bit32u)((offset % dtoh32(header.specific.extent)) / 512);

  BX_DEBUG(("redolog : lseeking extent index %d, offset %d",extent_index, extent_offset));

  return offset;
}

ssize_t redolog_t::read(void* buf, size_t count)
{
  Bit64s bloc_offset, bitmap_offset;

  if (count != 512)
    BX_PANIC(("redolog : read HD with count not 512"));

  BX_DEBUG(("redolog : reading index %d, mapping to %d", extent_index, dtoh32(catalog[extent_index])));

  if (dtoh32(catalog[extent_index]) == REDOLOG_PAGE_NOT_ALLOCATED)
  {
    // page not allocated
    return 0;
  }

  bitmap_offset  = (Bit64s)STANDARD_HEADER_SIZE + (dtoh32(header.specific.catalog) * sizeof(Bit32u));
  bitmap_offset += (Bit64s)512 * dtoh32(catalog[extent_index]) * (extent_blocs + bitmap_blocs);
  bloc_offset    = bitmap_offset + ((Bit64s)512 * (bitmap_blocs + extent_offset));

  BX_DEBUG(("redolog : bitmap offset is %x", (Bit32u)bitmap_offset));
  BX_DEBUG(("redolog : bloc offset is %x", (Bit32u)bloc_offset));

  // FIXME if same extent_index as before we can skip bitmap read

  ::lseek(fd, (off_t)bitmap_offset, SEEK_SET);

  if (::read(fd, bitmap,  dtoh32(header.specific.bitmap)) != (ssize_t)dtoh32(header.specific.bitmap))
  {
    BX_PANIC(("redolog : failed to read bitmap for extent %d", extent_index));
    return 0;
  }

  if (((bitmap[extent_offset/8] >> (extent_offset%8)) & 0x01) == 0x00)
  {
    BX_DEBUG(("read not in redolog"));

    // bitmap says bloc not in reloglog
    return 0;
  }

  ::lseek(fd, (off_t)bloc_offset, SEEK_SET);

  return (::read(fd, buf, count));
}

ssize_t redolog_t::write(const void* buf, size_t count)
{
  Bit32u i;
  Bit64s bloc_offset, bitmap_offset, catalog_offset;
  ssize_t written;
  bx_bool update_catalog = 0;

  if (count != 512)
    BX_PANIC(("redolog : write HD with count not 512"));

  BX_DEBUG(("redolog : writing index %d, mapping to %d", extent_index, dtoh32(catalog[extent_index])));
  if (dtoh32(catalog[extent_index]) == REDOLOG_PAGE_NOT_ALLOCATED)
  {
    if (extent_next >= dtoh32(header.specific.catalog))
    {
      BX_PANIC(("redolog : can't allocate new extent... catalog is full"));
      return 0;
    }

    BX_DEBUG(("redolog : allocating new extent at %d", extent_next));

    // Extent not allocated, allocate new
    catalog[extent_index] = htod32(extent_next);

    extent_next += 1;

    char *zerobuffer = (char*)malloc(512);
    memset(zerobuffer, 0, 512);

    // Write bitmap
    bitmap_offset  = (Bit64s)STANDARD_HEADER_SIZE + (dtoh32(header.specific.catalog) * sizeof(Bit32u));
    bitmap_offset += (Bit64s)512 * dtoh32(catalog[extent_index]) * (extent_blocs + bitmap_blocs);
    ::lseek(fd, (off_t)bitmap_offset, SEEK_SET);
    for (i=0; i<bitmap_blocs; i++)
    {
      ::write(fd, zerobuffer, 512);
    }
    // Write extent
    for (i=0; i<extent_blocs; i++)
    {
      ::write(fd, zerobuffer, 512);
    }

    free(zerobuffer);

    update_catalog = 1;
  }

  bitmap_offset  = (Bit64s)STANDARD_HEADER_SIZE + (dtoh32(header.specific.catalog) * sizeof(Bit32u));
  bitmap_offset += (Bit64s)512 * dtoh32(catalog[extent_index]) * (extent_blocs + bitmap_blocs);
  bloc_offset    = bitmap_offset + ((Bit64s)512 * (bitmap_blocs + extent_offset));

  BX_DEBUG(("redolog : bitmap offset is %x", (Bit32u)bitmap_offset));
  BX_DEBUG(("redolog : bloc offset is %x", (Bit32u)bloc_offset));

  // Write bloc
  ::lseek(fd, (off_t)bloc_offset, SEEK_SET);
  written = ::write(fd, buf, count);

  // Write bitmap
  // FIXME if same extent_index as before we can skip bitmap read
  ::lseek(fd, (off_t)bitmap_offset, SEEK_SET);
  if (::read(fd, bitmap,  dtoh32(header.specific.bitmap)) != (ssize_t)dtoh32(header.specific.bitmap))
  {
    BX_PANIC(("redolog : failed to read bitmap for extent %d", extent_index));
    return 0;
  }

  // If bloc does not belong to extent yet
  if (((bitmap[extent_offset/8] >> (extent_offset%8)) & 0x01) == 0x00)
  {
    bitmap[extent_offset/8] |= 1 << (extent_offset%8);
    ::lseek(fd, (off_t)bitmap_offset, SEEK_SET);
    ::write(fd, bitmap,  dtoh32(header.specific.bitmap));
  }

  // Write catalog
  if (update_catalog)
  {
    // FIXME if mmap
    catalog_offset  = (Bit64s)STANDARD_HEADER_SIZE + (extent_index * sizeof(Bit32u));

    BX_DEBUG(("redolog : writing catalog at offset %x", (Bit32u)catalog_offset));

    ::lseek(fd, (off_t)catalog_offset, SEEK_SET);
    ::write(fd, &catalog[extent_index], sizeof(Bit32u));
  }

  return written;
}

/*** growing_image_t function definitions ***/

growing_image_t::growing_image_t()
{
  redolog = new redolog_t();
}

growing_image_t::~growing_image_t()
{
  delete redolog;
}

int growing_image_t::open(const char* pathname)
{
  int filedes = redolog->open(pathname, REDOLOG_SUBTYPE_GROWING);
  hd_size = redolog->get_size();
  BX_INFO(("'growing' disk opened, growing file is '%s'", pathname));
  return filedes;
}

void growing_image_t::close()
{
  redolog->close();
}

Bit64s growing_image_t::lseek(Bit64s offset, int whence)
{
  return redolog->lseek(offset, whence);
}

ssize_t growing_image_t::read(void* buf, size_t count)
{
  memset(buf, 0, count);
  redolog->read((char*) buf, count);
  return count;
}

ssize_t growing_image_t::write(const void* buf, size_t count)
{
  return redolog->write((char*) buf, count);
}

/*** undoable_image_t function definitions ***/

undoable_image_t::undoable_image_t(const char* _redolog_name)
{
  redolog = new redolog_t();
  ro_disk = new default_image_t();
  redolog_name = NULL;
  if (_redolog_name != NULL) {
    if (strcmp(_redolog_name,"") != 0) {
      redolog_name = strdup(_redolog_name);
    }
  }
}

undoable_image_t::~undoable_image_t()
{
  delete redolog;
  delete ro_disk;
}

int undoable_image_t::open(const char* pathname)
{
  char *logname=NULL;

  if (ro_disk->open(pathname, O_RDONLY)<0)
    return -1;

  hd_size = ro_disk->hd_size;
  // if redolog name was set
  if (redolog_name != NULL) {
    if (strcmp(redolog_name, "") != 0) {
      logname = (char*)malloc(strlen(redolog_name) + 1);
      strcpy(logname, redolog_name);
    }
  }

  // Otherwise we make up the redolog filename from the pathname
  if (logname == NULL) {
    logname = (char*)malloc(strlen(pathname) + UNDOABLE_REDOLOG_EXTENSION_LENGTH + 1);
    sprintf(logname, "%s%s", pathname, UNDOABLE_REDOLOG_EXTENSION);
  }

  if (redolog->open(logname,REDOLOG_SUBTYPE_UNDOABLE) < 0)
  {
    if (redolog->create(logname, REDOLOG_SUBTYPE_UNDOABLE, hd_size) < 0)
    {
      BX_PANIC(("Can't open or create redolog '%s'",logname));
      return -1;
    }
    if (hd_size != redolog->get_size())
    {
      BX_PANIC(("size reported by redolog doesn't match r/o disk size"));
      free(logname);
      return -1;
    }
  }

  BX_INFO(("'undoable' disk opened: ro-file is '%s', redolog is '%s'", pathname, logname));
  free(logname);

  return 0;
}

void undoable_image_t::close ()
{
  redolog->close();
  ro_disk->close();

  if (redolog_name!=NULL)
    free(redolog_name);
}

Bit64s undoable_image_t::lseek(Bit64s offset, int whence)
{
  redolog->lseek(offset, whence);
  return ro_disk->lseek(offset, whence);
}

ssize_t undoable_image_t::read(void* buf, size_t count)
{
  // This should be fixed if count != 512
  if ((size_t)redolog->read((char*) buf, count) != count)
    return ro_disk->read((char*) buf, count);
  else
    return count;
}

ssize_t undoable_image_t::write(const void* buf, size_t count)
{
  return redolog->write((char*) buf, count);
}

/*** volatile_image_t function definitions ***/

volatile_image_t::volatile_image_t(const char* _redolog_name)
{
  redolog = new redolog_t();
  ro_disk = new default_image_t();
  redolog_temp = NULL;
  redolog_name = NULL;
  if (_redolog_name != NULL) {
    if (strcmp(_redolog_name,"") != 0) {
      redolog_name = strdup(_redolog_name);
    }
  }
}

volatile_image_t::~volatile_image_t()
{
  delete redolog;
  delete ro_disk;
}

int volatile_image_t::open(const char* pathname)
{
  int filedes;
  const char *logname=NULL;

  if (ro_disk->open(pathname, O_RDONLY)<0)
    return -1;

  hd_size = ro_disk->hd_size;
  // if redolog name was set
  if (redolog_name != NULL) {
    if (strcmp(redolog_name, "") != 0) {
      logname = redolog_name;
    }
  }

  // otherwise use pathname as template
  if (logname == NULL) {
    logname = pathname;
  }

  redolog_temp = (char*)malloc(strlen(logname) + VOLATILE_REDOLOG_EXTENSION_LENGTH + 1);
  sprintf (redolog_temp, "%s%s", logname, VOLATILE_REDOLOG_EXTENSION);

  filedes = mkstemp (redolog_temp);

  if (filedes < 0)
  {
    BX_PANIC(("Can't create volatile redolog '%s'", redolog_temp));
    return -1;
  }
  if (redolog->create(filedes, REDOLOG_SUBTYPE_VOLATILE, hd_size) < 0)
  {
    BX_PANIC(("Can't create volatile redolog '%s'", redolog_temp));
    return -1;
  }

#if (!defined(WIN32)) && !BX_WITH_MACOS
  // on unix it is legal to delete an open file
  unlink(redolog_temp);
#endif

  BX_INFO(("'volatile' disk opened: ro-file is '%s', redolog is '%s'", pathname, redolog_temp));

  return 0;
}

void volatile_image_t::close()
{
  redolog->close();
  ro_disk->close();

#if defined(WIN32) || BX_WITH_MACOS
  // on non-unix we have to wait till the file is closed to delete it
  unlink(redolog_temp);
#endif
  if (redolog_temp!=NULL)
    free(redolog_temp);

  if (redolog_name!=NULL)
    free(redolog_name);
}

Bit64s volatile_image_t::lseek(Bit64s offset, int whence)
{
  redolog->lseek(offset, whence);
  return ro_disk->lseek(offset, whence);
}

ssize_t volatile_image_t::read(void* buf, size_t count)
{
  // This should be fixed if count != 512
  if ((size_t)redolog->read((char*) buf, count) != count)
    return ro_disk->read((char*) buf, count);
  else
    return count;
}

ssize_t volatile_image_t::write(const void* buf, size_t count)
{
  return redolog->write((char*) buf, count);
}

#if BX_COMPRESSED_HD_SUPPORT

/*** z_ro_image_t function definitions ***/

z_ro_image_t::z_ro_image_t()
{
  offset = (Bit64s)0;
}

int z_ro_image_t::open(const char* pathname)
{
  fd = ::open(pathname, O_RDONLY
#ifdef O_BINARY
              | O_BINARY
#endif
             );

  if (fd < 0)
  {
    BX_PANIC(("Could not open '%s' file", pathname));
    return fd;
  }

  gzfile = gzdopen(fd, "rb");
  return 0;
}

void z_ro_image_t::close()
{
  if (fd > -1) {
    gzclose(gzfile);
    // ::close(fd);
  }
}

Bit64s z_ro_image_t::lseek(Bit64s _offset, int whence)
{
  // Only SEEK_SET supported
  if (whence != SEEK_SET)
  {
    BX_PANIC(("lseek on compressed images : only SEEK_SET supported"));
  }

  // Seeking is expensive on compressed files, so we do it
  // only when necessary, at the latest moment
  offset = _offset;

  return offset;
}

ssize_t z_ro_image_t::read(void* buf, size_t count)
{
  gzseek(gzfile, offset, SEEK_SET);
  return gzread(gzfile, buf, count);
}

ssize_t z_ro_image_t::write(const void* buf, size_t count)
{
  BX_PANIC(("z_ro_image: write not supported"));
  return 0;
}


/*** z_undoable_image_t function definitions ***/

z_undoable_image_t::z_undoable_image_t(Bit64u _size, const char* _redolog_name)
{
  redolog = new redolog_t();
  ro_disk = new z_ro_image_t();
  size = _size;

  redolog_name = NULL;
  if (_redolog_name != NULL) {
    if (strcmp(_redolog_name,"") != 0) {
      redolog_name = strdup(_redolog_name);
    }
  }
}

z_undoable_image_t::~z_undoable_image_t()
{
  delete redolog;
  delete ro_disk;
}

int z_undoable_image_t::open(const char* pathname)
{
  char *logname=NULL;

  if (ro_disk->open(pathname)<0)
    return -1;

  // If redolog name was set
  if (redolog_name != NULL) {
    if (strcmp(redolog_name, "") != 0) {
      logname = (char*)malloc(strlen(redolog_name) + 1);
      strcpy (logname, redolog_name);
    }
  }

  // Otherwise we make up the redolog filename from the pathname
  if (logname == NULL) {
    logname = (char*)malloc(strlen(pathname) + UNDOABLE_REDOLOG_EXTENSION_LENGTH + 1);
    sprintf (logname, "%s%s", pathname, UNDOABLE_REDOLOG_EXTENSION);
  }

  if (redolog->open(logname, REDOLOG_SUBTYPE_UNDOABLE) < 0)
  {
    if (redolog->create(logname, REDOLOG_SUBTYPE_UNDOABLE, size) < 0)
    {
      BX_PANIC(("Can't open or create redolog '%s'",logname));
      return -1;
    }
  }

  BX_INFO(("'z-undoable' disk opened, z-ro-file is '%s', redolog is '%s'", pathname, logname));
  free(logname);

  return 0;
}

void z_undoable_image_t::close()
{
  redolog->close();
  ro_disk->close();

  if (redolog_name!=NULL)
    free(redolog_name);
}

Bit64s z_undoable_image_t::lseek(Bit64s offset, int whence)
{
  redolog->lseek(offset, whence);
  return ro_disk->lseek(offset, whence);
}

ssize_t z_undoable_image_t::read(void* buf, size_t count)
{
  // This should be fixed if count != 512
  if (redolog->read((char*) buf, count) != count)
    return ro_disk->read((char*) buf, count);
  else
    return count;
}

ssize_t z_undoable_image_t::write(const void* buf, size_t count)
{
  return redolog->write((char*) buf, count);
}


/*** z_volatile_image_t function definitions ***/

z_volatile_image_t::z_volatile_image_t(Bit64u _size, const char* _redolog_name)
{
  redolog = new redolog_t();
  ro_disk = new z_ro_image_t();
  size = _size;

  redolog_temp = NULL;
  redolog_name = NULL;
  if (_redolog_name != NULL) {
    if (strcmp(_redolog_name,"") != 0) {
      redolog_name = strdup(_redolog_name);
    }
  }
}

z_volatile_image_t::~z_volatile_image_t()
{
  delete redolog;
  delete ro_disk;
}

int z_volatile_image_t::open(const char* pathname)
{
  int filedes;
  const char *logname=NULL;

  if (ro_disk->open(pathname)<0)
    return -1;

  // if redolog name was set
  if (redolog_name != NULL) {
    if (strcmp(redolog_name, "") != 0) {
      logname = redolog_name;
    }
  }

  // otherwise use pathname as template
  if (logname == NULL) {
    logname = pathname;
  }

  redolog_temp = (char*)malloc(strlen(logname) + VOLATILE_REDOLOG_EXTENSION_LENGTH + 1);
  sprintf (redolog_temp, "%s%s", logname, VOLATILE_REDOLOG_EXTENSION);

  filedes = mkstemp (redolog_temp);

  if (filedes < 0)
  {
    BX_PANIC(("Can't create volatile redolog '%s'", redolog_temp));
    return -1;
  }
  if (redolog->create(filedes, REDOLOG_SUBTYPE_VOLATILE, size) < 0)
  {
    BX_PANIC(("Can't create volatile redolog '%s'", redolog_temp));
    return -1;
  }

#if (!defined(WIN32)) && !BX_WITH_MACOS
  // on unix it is legal to delete an open file
  unlink(redolog_temp);
#endif

  BX_INFO(("'z-volatile' disk opened: z-ro-file is '%s', redolog is '%s'", pathname, redolog_temp));

  return 0;
}

void z_volatile_image_t::close ()
{
  redolog->close();
  ro_disk->close();

#if defined(WIN32) || BX_WITH_MACOS
  // on non-unix we have to wait till the file is closed to delete it
  unlink(redolog_temp);
#endif

  if (redolog_temp!=NULL)
    free(redolog_temp);

  if (redolog_name!=NULL)
    free(redolog_name);
}

Bit64s z_volatile_image_t::lseek(Bit64s offset, int whence)
{
  redolog->lseek(offset, whence);
  return ro_disk->lseek(offset, whence);
}

ssize_t z_volatile_image_t::read (void* buf, size_t count)
{
  // This should be fixed if count != 512
  if (redolog->read((char*) buf, count) != count)
    return ro_disk->read((char*) buf, count);
  else
    return count;
}

ssize_t z_volatile_image_t::write (const void* buf, size_t count)
{
  return redolog->write((char*) buf, count);
}

#endif
