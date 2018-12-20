/////////////////////////////////////////////////////////////////////////
// $Id: gameport.h,v 1.6 2007/09/28 19:52:00 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2003  MandrakeSoft S.A.
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

#ifndef BX_IODEV_GAMEPORT_H
#define BX_IODEV_GAMEPORT_H

#if BX_USE_GAMEPORT_SMF
#  define BX_GAMEPORT_SMF  static
#  define BX_GAMEPORT_THIS theGameport->
#else
#  define BX_GAMEPORT_SMF
#  define BX_GAMEPORT_THIS this->
#endif


class bx_gameport_c : public bx_devmodel_c {
public:
  bx_gameport_c();
  virtual ~bx_gameport_c();
  virtual void init(void);
  virtual void reset(unsigned type);
  virtual void register_state(void);

private:

  int     joyfd;
  Bit8u   port;
  Bit16u  delay_x;
  Bit16u  delay_y;
  bx_bool timer_x;
  bx_bool timer_y;
  Bit64u  write_usec;

  BX_GAMEPORT_SMF void poll_joydev(void);

  static Bit32u read_handler(void *this_ptr, Bit32u address, unsigned io_len);
  static void   write_handler(void *this_ptr, Bit32u address, Bit32u value, unsigned io_len);
#if !BX_USE_GAMEPORT_SMF
  Bit32u read(Bit32u address, unsigned io_len);
  void   write(Bit32u address, Bit32u value, unsigned io_len);
#endif
};

#endif
