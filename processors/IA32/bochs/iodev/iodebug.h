/////////////////////////////////////////////////////////////////////////
// $Id: iodebug.h,v 1.12 2008/06/04 16:28:16 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
#ifndef _BX_IODEBUG_H
#define _BX_IODEBUG_H

#include "config.h"

#if BX_SUPPORT_IODEBUG

#define BX_IODEBUG_MAX_AREAS 30

class bx_iodebug_c : public bx_devmodel_c {
public:
  bx_iodebug_c();
  virtual ~bx_iodebug_c() {}
  virtual void init(void);
  virtual void reset (unsigned type) {}
  static void mem_write(BX_CPU_C *cpu, bx_phy_address addr, unsigned len, void *data);
  static void mem_read(BX_CPU_C *cpu, bx_phy_address addr, unsigned len, void *data);

private:
  static Bit32u read_handler(void *this_ptr, Bit32u address, unsigned io_len);
  static void write_handler(void *this_ptr, Bit32u address, Bit32u value, unsigned io_len);
  Bit32u read(Bit32u addr, unsigned io_len);
  void write(Bit32u addr, Bit32u dvalue, unsigned io_len);
  static unsigned range_test(bx_phy_address addr, unsigned len);
  static void add_range(bx_phy_address addr_start, bx_phy_address addr_end);
};

extern bx_iodebug_c bx_iodebug;

#endif

#endif
