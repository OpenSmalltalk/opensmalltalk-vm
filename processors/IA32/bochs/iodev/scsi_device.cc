/////////////////////////////////////////////////////////////////////////
// $Id: scsi_device.cc,v 1.6 2008/01/26 22:24:02 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2007  Volker Ruppert
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

// SCSI emulation layer ported from the Qemu project


// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE
// is used to know when we are exporting symbols and when we are importing.
#define BX_PLUGGABLE

#define NO_DEVICE_INCLUDES
#include "iodev.h"
#if BX_SUPPORT_PCI && BX_SUPPORT_PCIUSB
#include "hdimage.h"
#include "cdrom.h"
#include "scsi_device.h"

#define LOG_THIS

static SCSIRequest *free_requests = NULL;

scsi_device_t::scsi_device_t(device_image_t *_hdimage, int _tcq,
                           scsi_completionfn _completion, void *_dev)
{
  type = SCSIDEV_TYPE_DISK;
  cdrom = NULL;
  hdimage = _hdimage;
  requests = NULL;
  sense = 0;
  tcq = _tcq;
  completion = _completion;
  dev = _dev;
  cluster_size = 1;

  put("SCSID");
  settype(PCIUSBLOG);
}

scsi_device_t::scsi_device_t(LOWLEVEL_CDROM *_cdrom, int _tcq,
                           scsi_completionfn _completion, void *_dev)
{
  type = SCSIDEV_TYPE_CDROM;
  cdrom = _cdrom;
  hdimage = NULL;
  requests = NULL;
  sense = 0;
  tcq = _tcq;
  completion = _completion;
  dev = _dev;
  cluster_size = 4;

  put("SCSIC");
  settype(PCIUSBLOG);
}

scsi_device_t::~scsi_device_t(void)
{
}

void scsi_device_t::register_state(bx_list_c *parent, const char *name)
{
  bx_list_c *list = new bx_list_c(parent, name, "", 1);
  new bx_shadow_num_c(list, "sense", &sense);
  // TODO: save/restore for SCSI requests
}

SCSIRequest* scsi_device_t::scsi_new_request(Bit32u tag)
{
  SCSIRequest *r;

  if (free_requests) {
    r = free_requests;
    free_requests = r->next;
  } else {
    r = new SCSIRequest;
  }
  r->dev = this;
  r->tag = tag;
  r->sector_count = 0;
  r->buf_len = 0;

  r->next = requests;
  requests = r;
  return r;
}

void scsi_device_t::scsi_remove_request(SCSIRequest *r)
{
  SCSIRequest *last;

  if (requests == r) {
    requests = r->next;
  } else {
    last = requests;
    while (last != NULL) {
      if (last->next != r)
        last = last->next;
      else
        break;
    }
    if (last) {
      last->next = r->next;
    } else {
      BX_ERROR(("orphaned request"));
    }
  }
  r->next = free_requests;
  free_requests = r;
}

SCSIRequest* scsi_device_t::scsi_find_request(Bit32u tag)
{
  SCSIRequest *r = requests;
  while (r != NULL) {
    if (r->tag != tag)
      r = r->next;
    else
      break;
  }
  return r;
}

void scsi_device_t::scsi_command_complete(SCSIRequest *r, int _sense)
{
  Bit32u tag;
  BX_DEBUG(("command complete tag=0x%x sense=%d", r->tag, sense));
  sense = _sense;
  tag = r->tag;
  scsi_remove_request(r);
  completion(dev, SCSI_REASON_DONE, tag, sense);
}

void scsi_device_t::scsi_cancel_io(Bit32u tag)
{
  BX_DEBUG(("cancel tag=0x%x", tag));
  SCSIRequest *r = scsi_find_request(tag);
  if (r) {
    scsi_remove_request(r);
  }
}

void scsi_device_t::scsi_read_complete(void *req, int ret)
{
  SCSIRequest *r = (SCSIRequest *)req;

  if (ret) {
    BX_ERROR(("IO error"));
    scsi_command_complete(r, SENSE_HARDWARE_ERROR);
    return;
  }
  BX_DEBUG(("data ready tag=0x%x len=%d", r->tag, r->buf_len));

  completion(dev, SCSI_REASON_DATA, r->tag, r->buf_len);
}

void scsi_device_t::scsi_read_data(Bit32u tag)
{
  Bit32u n;
  int ret;

  SCSIRequest *r = scsi_find_request(tag);
  if (!r) {
    BX_ERROR(("bad read tag 0x%x", tag));
    scsi_command_complete(r, SENSE_HARDWARE_ERROR);
    return;
  }
  if (r->sector_count == -1) {
    BX_DEBUG(("read buf_len=%d", r->buf_len));
    r->sector_count = 0;
    completion(dev, SCSI_REASON_DATA, r->tag, r->buf_len);
    return;
  }
  BX_DEBUG(("read sector_count=%d", r->sector_count));
  if (r->sector_count == 0) {
    scsi_command_complete(r, SENSE_NO_SENSE);
    return;
  }

  n = r->sector_count;
  if (n > (Bit32u)(SCSI_DMA_BUF_SIZE / (512 * cluster_size)))
    n = SCSI_DMA_BUF_SIZE / (512 * cluster_size);
  r->buf_len = n * 512 * cluster_size;
  if (type == SCSIDEV_TYPE_CDROM) {
    cdrom->read_block(r->dma_buf, r->sector, 2048);
  } else {
    ret = (int)hdimage->lseek(r->sector * 512, SEEK_SET);
    if (ret < 0) {
      BX_ERROR(("could not lseek() hard drive image file"));
      scsi_command_complete(r, SENSE_HARDWARE_ERROR);
    }
    ret = hdimage->read((bx_ptr_t)r->dma_buf, r->buf_len);
    if (ret < r->buf_len) {
      BX_ERROR(("could not read() hard drive image file"));
      scsi_command_complete(r, SENSE_HARDWARE_ERROR);
    } else {
      scsi_read_complete((void*)r, 0);
    }
  }
  r->sector += n;
  r->sector_count -= n;
}

void scsi_device_t::scsi_write_complete(void *req, int ret)
{
  SCSIRequest *r = (SCSIRequest *)req;
  Bit32u len;

  if (ret) {
    BX_ERROR(("IO error"));
    scsi_command_complete(r, SENSE_HARDWARE_ERROR);
    return;
  }

  if (r->sector_count == 0) {
    scsi_command_complete(r, SENSE_NO_SENSE);
  } else {
    len = r->sector_count * 512;
    if (len > SCSI_DMA_BUF_SIZE) {
      len = SCSI_DMA_BUF_SIZE;
    }
    r->buf_len = len;
    BX_DEBUG(("write complete tag=0x%x more=%d", r->tag, len));
    completion(dev, SCSI_REASON_DATA, r->tag, len);
  }
}

int scsi_device_t::scsi_write_data(Bit32u tag)
{
  SCSIRequest *r;
  Bit32u n;
  int ret;

  BX_DEBUG(("write data tag=0x%x", tag));
  r = scsi_find_request(tag);
  if (!r) {
    BX_ERROR(("bad write tag 0x%x", tag));
    scsi_command_complete(r, SENSE_HARDWARE_ERROR);
    return 1;
  }
  if (type == SCSIDEV_TYPE_DISK) {
    n = r->buf_len / 512;
    if (n) {
      ret = (int)hdimage->lseek(r->sector * 512, SEEK_SET);
      if (ret < 0) {
        BX_ERROR(("could not lseek() hard drive image file"));
        scsi_command_complete(r, SENSE_HARDWARE_ERROR);
      }
      ret = hdimage->write((bx_ptr_t)r->dma_buf, r->buf_len);
      if (ret < r->buf_len) {
        BX_ERROR(("could not write() hard drive image file"));
        scsi_command_complete(r, SENSE_HARDWARE_ERROR);
      } else {
        scsi_write_complete((void*)r, 0);
      }
      r->sector += n;
      r->sector_count -= n;
    } else {
      scsi_write_complete(r, 0);
    }
  } else {
    BX_ERROR(("CD-ROM: write not supported"));
    scsi_command_complete(r, SENSE_HARDWARE_ERROR);
  }
  return 0;
}

Bit8u* scsi_device_t::scsi_get_buf(Bit32u tag)
{
  SCSIRequest *r = scsi_find_request(tag);
  if (!r) {
    BX_ERROR(("bad buffer tag 0x%x", tag));
    return NULL;
  }
  return r->dma_buf;
}

Bit32s scsi_device_t::scsi_send_command(Bit32u tag, Bit8u *buf, int lun)
{
  Bit64u nb_sectors;
  Bit32u lba;
  Bit32s len;
  int cmdlen;
  int is_write;
  Bit8u command;
  Bit8u *outbuf;
  SCSIRequest *r;

  command = buf[0];
  r = scsi_find_request(tag);
  if (r) {
    BX_ERROR(("tag 0x%x already in use", tag));
    scsi_cancel_io(tag);
  }
  r = scsi_new_request(tag);
  outbuf = r->dma_buf;
  is_write = 0;
  BX_DEBUG(("command: lun=%d tag=0x%x data=0x%02x", lun, tag, buf[0]));
  switch (command >> 5) {
    case 0:
        lba = buf[3] | (buf[2] << 8) | ((buf[1] & 0x1f) << 16);
        len = buf[4];
        cmdlen = 6;
        break;
    case 1:
    case 2:
        lba = buf[5] | (buf[4] << 8) | (buf[3] << 16) | (buf[2] << 24);
        len = buf[8] | (buf[7] << 8);
        cmdlen = 10;
        break;
    case 4:
        lba = buf[5] | (buf[4] << 8) | (buf[3] << 16) | (buf[2] << 24);
        len = buf[13] | (buf[12] << 8) | (buf[11] << 16) | (buf[10] << 24);
        cmdlen = 16;
        break;
    case 5:
        lba = buf[5] | (buf[4] << 8) | (buf[3] << 16) | (buf[2] << 24);
        len = buf[9] | (buf[8] << 8) | (buf[7] << 16) | (buf[6] << 24);
        cmdlen = 12;
        break;
    default:
        BX_ERROR(("Unsupported command length, command %x", command));
        goto fail;
  }
  if (lun || buf[1] >> 5) {
    BX_ERROR(("unimplemented LUN %d", lun ? lun : buf[1] >> 5));
    goto fail;
  }
  switch (command) {
    case 0x0:
      BX_DEBUG(("Test Unit Ready"));
      break;
    case 0x03:
      BX_DEBUG(("request Sense (len %d)", len));
      if (len < 4)
        goto fail;
      memset(outbuf, 0, 4);
      outbuf[0] = 0xf0;
      outbuf[1] = 0;
      outbuf[2] = sense;
      r->buf_len = 4;
      break;
    case 0x12:
      BX_DEBUG(("inquiry (len %d)", len));
      if (len < 36) {
        BX_ERROR(("inquiry buffer too small (%d)", len));
      }
      memset(outbuf, 0, 36);
      if (type == SCSIDEV_TYPE_CDROM) {
        outbuf[0] = 5;
        outbuf[1] = 0x80;
        memcpy(&outbuf[16], "BOCHS CD-ROM   ", 16);
      } else {
        outbuf[0] = 0;
        memcpy(&outbuf[16], "BOCHS HARDDISK ", 16);
      }
      memcpy(&outbuf[8], "BOCHS  ", 8);
      memcpy(&outbuf[32], "1.0", 4);
      outbuf[2] = 3;
      outbuf[3] = 2;
      outbuf[4] = 31;
      outbuf[7] = 0x10 | (tcq ? 0x02 : 0);
      r->buf_len = 36;
      break;
    case 0x16:
      BX_INFO(("Reserve(6)"));
      if (buf[1] & 1)
        goto fail;
      break;
    case 0x17:
      BX_INFO(("Release(6)"));
      if (buf[1] & 1)
        goto fail;
      break;
    case 0x1a:
    case 0x5a:
      {
        Bit8u *p;
        int page;

        page = buf[2] & 0x3f;
        BX_DEBUG(("mode sense (page %d, len %d)", page, len));
        p = outbuf;
        memset(p, 0, 4);
        outbuf[1] = 0; /* Default media type.  */
        outbuf[3] = 0; /* Block descriptor length.  */
        if (type == SCSIDEV_TYPE_CDROM) {
          outbuf[2] = 0x80; /* Readonly.  */
        }
        p += 4;
        if ((page == 8 || page == 0x3f)) {
          /* Caching page.  */
          memset(p, 0, 20);
          p[0] = 8;
          p[1] = 0x12;
          p[2] = 4; /* WCE */
          p += 20;
        }
        if ((page == 0x3f || page == 0x2a)
            && (type == SCSIDEV_TYPE_CDROM)) {
          /* CD Capabilities and Mechanical Status page. */
          p[0] = 0x2a;
          p[1] = 0x14;
          p[2] = 3; // CD-R & CD-RW read
          p[3] = 0; // Writing not supported
          p[4] = 0x7f; /* Audio, composite, digital out,
                          mode 2 form 1&2, multi session */
          p[5] = 0xff; /* CD DA, DA accurate, RW supported,
                          RW corrected, C2 errors, ISRC,
                          UPC, Bar code */
          p[6] = 0x2d; // TODO: | (bdrv_is_locked(s->bdrv)? 2 : 0);
          /* Locking supported, jumper present, eject, tray */
          p[7] = 0; /* no volume & mute control, no changer */
          p[8] = (50 * 176) >> 8; // 50x read speed
          p[9] = (50 * 176) & 0xff;
          p[10] = 0 >> 8; // No volume
          p[11] = 0 & 0xff;
          p[12] = 2048 >> 8; // 2M buffer
          p[13] = 2048 & 0xff;
          p[14] = (16 * 176) >> 8; // 16x read speed current
          p[15] = (16 * 176) & 0xff;
          p[18] = (16 * 176) >> 8; // 16x write speed
          p[19] = (16 * 176) & 0xff;
          p[20] = (16 * 176) >> 8; // 16x write speed current
          p[21] = (16 * 176) & 0xff;
          p += 22;
        }
        r->buf_len = p - outbuf;
        outbuf[0] = r->buf_len - 4;
        if (r->buf_len > (int)len)
          r->buf_len = len;
      }
      break;
    case 0x1b:
      BX_INFO(("Start Stop Unit"));
      break;
    case 0x1e:
      BX_INFO(("Prevent Allow Medium Removal (prevent = %d)", buf[4] & 3));
      break;
    case 0x25:
      BX_DEBUG(("Read Capacity"));
      // The normal LEN field for this command is zero
      memset(outbuf, 0, 8);
      if (type == SCSIDEV_TYPE_CDROM) {
        nb_sectors = cdrom->capacity();
      } else {
        nb_sectors = hdimage->hd_size / 512;
      }
      /* Returned value is the address of the last sector.  */
      if (nb_sectors) {
        nb_sectors--;
        outbuf[0] = (Bit8u)((nb_sectors >> 24) & 0xff);
        outbuf[1] = (Bit8u)((nb_sectors >> 16) & 0xff);
        outbuf[2] = (Bit8u)((nb_sectors >> 8) & 0xff);
        outbuf[3] = (Bit8u)(nb_sectors & 0xff);
        outbuf[4] = 0;
        outbuf[5] = 0;
        outbuf[6] = cluster_size * 2;
        outbuf[7] = 0;
        r->buf_len = 8;
      } else {
        scsi_command_complete(r, SENSE_NOT_READY);
        return 0;
      }
      break;
    case 0x08:
    case 0x28:
      BX_DEBUG(("Read (sector %d, count %d)", lba, len));
      r->sector = lba;
      r->sector_count = len;
      break;
    case 0x0a:
    case 0x2a:
      BX_DEBUG(("Write (sector %d, count %d)", lba, len));
      r->sector = lba;
      r->sector_count = len;
      is_write = 1;
      break;
    case 0x35:
      BX_DEBUG(("Syncronise cache (sector %d, count %d)", lba, len));
      // TODO: flush cache
      break;
    case 0x43:
      {
        int start_track, format, msf, toclen;

        if (type == SCSIDEV_TYPE_CDROM) {
          msf = buf[1] & 2;
          format = buf[2] & 0xf;
          start_track = buf[6];
          BX_DEBUG(("Read TOC (track %d format %d msf %d)", start_track, format, msf >> 1));
          cdrom->read_toc(outbuf, &toclen, msf, start_track, format);
          if (toclen > 0) {
            if (len > toclen)
              len = toclen;
            r->buf_len = len;
            break;
          }
          BX_ERROR(("Read TOC error"));
          goto fail;
        } else {
          goto fail;
        }
      }
    case 0x46:
      BX_DEBUG(("Get Configuration (rt %d, maxlen %d)", buf[1] & 3, len));
      memset(outbuf, 0, 8);
      /* ??? This shoud probably return much more information.  For now
         just return the basic header indicating the CD-ROM profile.  */
      outbuf[7] = 8; // CD-ROM
      r->buf_len = 8;
      break;
    case 0x56:
      BX_INFO(("Reserve(10)"));
      if (buf[1] & 3)
        goto fail;
      break;
    case 0x57:
      BX_INFO(("Release(10)"));
      if (buf[1] & 3)
        goto fail;
      break;
    case 0xa0:
      BX_INFO(("Report LUNs (len %d)", len));
      if (len < 16)
        goto fail;
      memset(outbuf, 0, 16);
      outbuf[3] = 8;
      r->buf_len = 16;
      break;
    default:
      BX_ERROR(("Unknown SCSI command (%2.2x)", buf[0]));
    fail:
      scsi_command_complete(r, SENSE_ILLEGAL_REQUEST);
      return 0;
  }
  if (r->sector_count == 0 && r->buf_len == 0) {
    scsi_command_complete(r, SENSE_NO_SENSE);
  }
  len = r->sector_count * 512 * cluster_size + r->buf_len;
  if (is_write) {
    return -len;
  } else {
    if (!r->sector_count)
      r->sector_count = -1;
    return len;
  }
}

#endif // BX_SUPPORT_PCI && BX_SUPPORT_PCIUSB
