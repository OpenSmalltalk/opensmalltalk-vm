/////////////////////////////////////////////////////////////////////////
// $Id: pci2isa.h,v 1.15 2007/09/28 19:52:03 sshwarts Exp $
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


#ifndef BX_IODEV_PIC2ISA_H
#define BX_IODEV_PIC2ISA_H

#if BX_USE_P2I_SMF
#  define BX_P2I_SMF  static
#  define BX_P2I_THIS thePci2IsaBridge->
#else
#  define BX_P2I_SMF
#  define BX_P2I_THIS this->
#endif


class bx_piix3_c : public bx_pci2isa_stub_c {
public:
  bx_piix3_c();
  virtual ~bx_piix3_c();
  virtual void init(void);
  virtual void reset(unsigned type);
  virtual void pci_set_irq(Bit8u devfunc, unsigned line, bx_bool level);
  virtual void register_state(void);
  virtual void after_restore_state(void);

  virtual Bit32u pci_read_handler(Bit8u address, unsigned io_len);
  virtual void   pci_write_handler(Bit8u address, Bit32u value, unsigned io_len);

private:

  struct {
    Bit8u pci_conf[256];
    Bit8u elcr1;
    Bit8u elcr2;
    Bit8u apmc;
    Bit8u apms;
    Bit8u irq_registry[16];
    Bit32u irq_level[16];
    Bit8u pci_reset;
  } s;

  static void pci_register_irq(unsigned pirq, unsigned irq);
  static void pci_unregister_irq(unsigned pirq);

  static Bit32u read_handler(void *this_ptr, Bit32u address, unsigned io_len);
  static void   write_handler(void *this_ptr, Bit32u address, Bit32u value, unsigned io_len);
#if !BX_USE_P2I_SMF
  Bit32u read(Bit32u address, unsigned io_len);
  void   write(Bit32u address, Bit32u value, unsigned io_len);
#endif
};

#endif
