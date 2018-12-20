/////////////////////////////////////////////////////////////////////////
// $Id: floppy.h,v 1.31 2007/09/28 19:51:59 sshwarts Exp $
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

#ifndef BX_IODEV_FLOPPY_H
#define BX_IODEV_FLOPPY_H

#define FROM_FLOPPY 10
#define TO_FLOPPY   11

#if BX_USE_FD_SMF
#  define BX_FD_SMF  static
#  define BX_FD_THIS theFloppyController->
#else
#  define BX_FD_SMF
#  define BX_FD_THIS this->
#endif

typedef struct {
  int      fd;         /* file descriptor of floppy image file */
  unsigned sectors_per_track;    /* number of sectors/track */
  unsigned sectors;    /* number of formatted sectors on diskette */
  unsigned tracks;      /* number of tracks */
  unsigned heads;      /* number of heads */
  unsigned type;
  unsigned write_protected;
  unsigned char raw_floppy_win95;
#ifdef WIN32
  unsigned char raw_floppy_win95_drv;
#endif
  } floppy_t;

class bx_floppy_ctrl_c : public bx_floppy_stub_c {
public:
  bx_floppy_ctrl_c();
  virtual ~bx_floppy_ctrl_c();
  virtual void init(void);
  virtual void reset(unsigned type);
  virtual unsigned set_media_status(unsigned drive, unsigned status);
  virtual unsigned get_media_status(unsigned drive);
  virtual void register_state(void);

private:

  struct {
    Bit8u   data_rate;

    Bit8u   command[10]; /* largest command size ??? */
    Bit8u   command_index;
    Bit8u   command_size;
    bx_bool command_complete;
    Bit8u   pending_command;

    bx_bool multi_track;
    bx_bool pending_irq;
    Bit8u   reset_sensei;
    Bit8u   format_count;
    Bit8u   format_fillbyte;

    Bit8u   result[10];
    Bit8u   result_index;
    Bit8u   result_size;

    Bit8u   DOR; // Digital Ouput Register
    Bit8u   TDR; // Tape Drive Register
    Bit8u   cylinder[4]; // really only using 2 drives
    Bit8u   head[4];     // really only using 2 drives
    Bit8u   sector[4];   // really only using 2 drives
    Bit8u   eot[4];      // really only using 2 drives
    bx_bool TC;          // Terminal Count status from DMA controller

    /* MAIN STATUS REGISTER
     * b7: MRQ: main request 1=data register ready     0=data register not ready
     * b6: DIO: data input/output:
     *     1=controller->CPU (ready for data read)
     *     0=CPU->controller (ready for data write)
     * b5: NDMA: non-DMA mode: 1=controller not in DMA modes
     *                         0=controller in DMA mode
     * b4: BUSY: instruction(device busy) 1=active 0=not active
     * b3-0: ACTD, ACTC, ACTB, ACTA:
     *       drive D,C,B,A in positioning mode 1=active 0=not active
     */
    Bit8u   main_status_reg;

    Bit8u   status_reg0;
    Bit8u   status_reg1;
    Bit8u   status_reg2;
    Bit8u   status_reg3;

    // drive field allows up to 4 drives, even though probably only 2 will
    // ever be used.
    floppy_t media[4];
    unsigned num_supported_floppies;
    Bit8u    floppy_buffer[512+2]; // 2 extra for good measure
    unsigned floppy_buffer_index;
    int      floppy_timer_index;
    bx_bool  media_present[4];
    Bit8u    device_type[4];
    Bit8u    DIR[4]; // Digital Input Register:
                  // b7: 0=diskette is present and has not been changed
                  //     1=diskette missing or changed
    bx_bool  lock;      // FDC lock status
    Bit8u    SRT;       // step rate time
    Bit8u    HUT;       // head unload time
    Bit8u    HLT;       // head load time
    Bit8u    config;    // configure byte #1
    Bit8u    pretrk;    // precompensation track
    Bit8u    perp_mode; // perpendicular mode

    int      statusbar_id[2]; // IDs of the status LEDs
  } s;  // state information

  static Bit32u read_handler(void *this_ptr, Bit32u address, unsigned io_len);
  static void   write_handler(void *this_ptr, Bit32u address, Bit32u value, unsigned io_len);
#if !BX_USE_FD_SMF
  Bit32u read(Bit32u address, unsigned io_len);
  void   write(Bit32u address, Bit32u value, unsigned io_len);
#endif
  BX_FD_SMF void   dma_write(Bit8u *data_byte);
  BX_FD_SMF void   dma_read(Bit8u *data_byte);
  BX_FD_SMF void   floppy_command(void);
  BX_FD_SMF void   floppy_xfer(Bit8u drive, Bit32u offset, Bit8u *buffer, Bit32u bytes, Bit8u direction);
  BX_FD_SMF void   raise_interrupt(void);
  BX_FD_SMF void   lower_interrupt(void);
  BX_FD_SMF void   enter_idle_phase(void);
  BX_FD_SMF void   enter_result_phase(void);
  BX_FD_SMF Bit32u calculate_step_delay(Bit8u drive, Bit8u new_cylinder);
  BX_FD_SMF void   reset_changeline(void);
  BX_FD_SMF bx_bool get_tc(void);
  static void      timer_handler(void *);

public:
  BX_FD_SMF void   timer(void);
  BX_FD_SMF void   increment_sector(void);
  BX_FD_SMF bx_bool evaluate_media(Bit8u devtype, Bit8u type, char *path, floppy_t *floppy);
};


#ifdef WIN32

// used for direct floppy access in Win95
#define  VWIN32_DIOC_DOS_IOCTL  1
#define  VWIN32_DIOC_DOS_INT25  2
#define  VWIN32_DIOC_DOS_INT26  3

typedef struct _DIOC_REGISTERS {
    DWORD reg_EBX;
    DWORD reg_EDX;
    DWORD reg_ECX;
    DWORD reg_EAX;
    DWORD reg_EDI;
    DWORD reg_ESI;
    DWORD reg_Flags;
} DIOC_REGISTERS, *PDIOC_REGISTERS;

#pragma pack(push, 1)
typedef struct _BLOCK_DEV_PARAMS {
    BYTE  features;
    BYTE  dev_type;
    WORD  attribs;
    WORD  cylinders;
    BYTE  media_type;
    // BPB
    WORD  bytes_per_sector;
    BYTE  sect_per_cluster;
    WORD  reserved_sectors;
    BYTE  fats;
    WORD  root_entries;
    WORD  tot_sectors;
    BYTE  media_id;
    WORD  sects_per_fat;
    WORD  sects_per_track;
    WORD  num_heads;
    WORD  hidden_sectors;
    BYTE  remainder[5];
} BLOCK_DEV_PARAMS, *PBLOCK_DEV_PARAMS;
#pragma pack(pop)

#endif /* WIN32 */

#endif
