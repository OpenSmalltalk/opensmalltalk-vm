///////////////////////////////////////////////////////////////////////
// $Id: pit_wrap.cc,v 1.69 2008/02/15 22:05:43 sshwarts Exp $
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


#include "iodev.h"

#include "speaker.h"

//Important constant #defines:
#define USEC_PER_SECOND (1000000)
//1.193181MHz Clock
#define TICKS_PER_SECOND (1193181)


// define a macro to convert floating point numbers into 64-bit integers.
// In MSVC++ you can convert a 64-bit float into a 64-bit signed integer,
// but it will not convert a 64-bit float into a 64-bit unsigned integer.
// This macro works around that.
#define F2I(x)  ((Bit64u)(Bit64s) (x))
#define I2F(x)  ((double)(Bit64s) (x))

//DEBUG configuration:

//Set up Logging.
#define LOG_THIS bx_pit.

//A single instance.
bx_pit_c bx_pit;
#if BX_USE_PIT_SMF
#define this (&bx_pit)
#endif

//Workaround for environments where OUT is defined.
#ifdef OUT
#  undef OUT
#endif


//Generic MAX and MIN Functions
#define BX_MAX(a,b) ( ((a)>(b))?(a):(b) )
#define BX_MIN(a,b) ( ((a)>(b))?(b):(a) )


//USEC_ALPHA is multiplier for the past.
//USEC_ALPHA_B is 1-USEC_ALPHA, or multiplier for the present.
#define USEC_ALPHA ((double)(.8))
#define USEC_ALPHA_B ((double)(((double)1)-USEC_ALPHA))
#define USEC_ALPHA2 ((double)(.5))
#define USEC_ALPHA2_B ((double)(((double)1)-USEC_ALPHA2))
#define ALPHA_LOWER(old,new) ((Bit64u)((old<new)?((USEC_ALPHA*(I2F(old)))+(USEC_ALPHA_B*(I2F(new)))):((USEC_ALPHA2*(I2F(old)))+(USEC_ALPHA2_B*(I2F(new))))))


//PIT tick to usec conversion functions:
//Direct conversions:
#define TICKS_TO_USEC(a) (((a)*USEC_PER_SECOND)/TICKS_PER_SECOND)
#define USEC_TO_TICKS(a) (((a)*TICKS_PER_SECOND)/USEC_PER_SECOND)

bx_pit_c::bx_pit_c()
{
  put("PIT");
  settype(PITLOG);
  s.speaker_data_on=0;

  /* 8254 PIT (Programmable Interval Timer) */

  BX_PIT_THIS s.timer_handle[1] = BX_NULL_TIMER_HANDLE;
  BX_PIT_THIS s.timer_handle[2] = BX_NULL_TIMER_HANDLE;
  BX_PIT_THIS s.timer_handle[0] = BX_NULL_TIMER_HANDLE;
}

int bx_pit_c::init(void)
{
  DEV_register_irq(0, "8254 PIT");
  DEV_register_ioread_handler(this, read_handler, 0x0040, "8254 PIT", 1);
  DEV_register_ioread_handler(this, read_handler, 0x0041, "8254 PIT", 1);
  DEV_register_ioread_handler(this, read_handler, 0x0042, "8254 PIT", 1);
  DEV_register_ioread_handler(this, read_handler, 0x0043, "8254 PIT", 1);
  DEV_register_ioread_handler(this, read_handler, 0x0061, "8254 PIT", 1);

  DEV_register_iowrite_handler(this, write_handler, 0x0040, "8254 PIT", 1);
  DEV_register_iowrite_handler(this, write_handler, 0x0041, "8254 PIT", 1);
  DEV_register_iowrite_handler(this, write_handler, 0x0042, "8254 PIT", 1);
  DEV_register_iowrite_handler(this, write_handler, 0x0043, "8254 PIT", 1);
  DEV_register_iowrite_handler(this, write_handler, 0x0061, "8254 PIT", 1);

  BX_DEBUG(("pit: starting init"));

  BX_PIT_THIS s.speaker_data_on = 0;
  BX_PIT_THIS s.refresh_clock_div2 = 0;

  BX_PIT_THIS s.timer.init();
  BX_PIT_THIS s.timer.set_OUT_handler(0, irq_handler);

  Bit64u my_time_usec = bx_virt_timer.time_usec();

  if (BX_PIT_THIS s.timer_handle[0] == BX_NULL_TIMER_HANDLE) {
    BX_PIT_THIS s.timer_handle[0] = bx_virt_timer.register_timer(this, timer_handler, (unsigned) 100 , 1, 1, "pit_wrap");
  }
  BX_DEBUG(("pit: RESETting timer."));
  bx_virt_timer.deactivate_timer(BX_PIT_THIS s.timer_handle[0]);
  BX_DEBUG(("deactivated timer."));
  if (BX_PIT_THIS s.timer.get_next_event_time()) {
    bx_virt_timer.activate_timer(BX_PIT_THIS s.timer_handle[0],
				(Bit32u)BX_MAX(1,TICKS_TO_USEC(BX_PIT_THIS s.timer.get_next_event_time())),
				0);
    BX_DEBUG(("activated timer."));
  }
  BX_PIT_THIS s.last_next_event_time = BX_PIT_THIS s.timer.get_next_event_time();
  BX_PIT_THIS s.last_usec=my_time_usec;

  BX_PIT_THIS s.total_ticks=0;
  BX_PIT_THIS s.total_usec=0;

  BX_DEBUG(("pit: finished init"));

  BX_DEBUG(("s.last_usec="FMT_LL"d",BX_PIT_THIS s.last_usec));
  BX_DEBUG(("s.timer_id=%d",BX_PIT_THIS s.timer_handle[0]));
  BX_DEBUG(("s.timer.get_next_event_time=%d",BX_PIT_THIS s.timer.get_next_event_time()));
  BX_DEBUG(("s.last_next_event_time=%d",BX_PIT_THIS s.last_next_event_time));

  return(1);
}

void bx_pit_c::exit(void)
{
  BX_PIT_THIS s.timer_handle[0] = BX_NULL_TIMER_HANDLE;
  BX_PIT_THIS s.timer.init();
}

void bx_pit_c::reset(unsigned type)
{
  BX_PIT_THIS s.timer.reset(type);
}

void bx_pit_c::register_state(void)
{
  bx_list_c *list = new bx_list_c(SIM->get_bochs_root(), "pit", "8254 PIT State", 7);
  new bx_shadow_num_c(list, "speaker_data_on", &BX_PIT_THIS s.speaker_data_on, BASE_HEX);
  new bx_shadow_bool_c(list, "refresh_clock_div2", &BX_PIT_THIS s.refresh_clock_div2);
  new bx_shadow_num_c(list, "last_usec", &BX_PIT_THIS s.last_usec);
  new bx_shadow_num_c(list, "last_next_event_time", &BX_PIT_THIS s.last_next_event_time);
  new bx_shadow_num_c(list, "total_ticks", &BX_PIT_THIS s.total_ticks);
  new bx_shadow_num_c(list, "total_usec", &BX_PIT_THIS s.total_usec);
  bx_list_c *counter = new bx_list_c(list, "counter", 4);
  BX_PIT_THIS s.timer.register_state(counter);
}

void bx_pit_c::timer_handler(void *this_ptr)
{
  bx_pit_c * class_ptr = (bx_pit_c *) this_ptr;
  class_ptr->handle_timer();
}

void bx_pit_c::handle_timer()
{
  Bit64u my_time_usec = bx_virt_timer.time_usec();
  Bit64u time_passed = my_time_usec-BX_PIT_THIS s.last_usec;
  Bit32u time_passed32 = (Bit32u)time_passed;

  BX_DEBUG(("pit: entering timer handler"));

  if(time_passed32) {
    periodic(time_passed32);
  }
  BX_PIT_THIS s.last_usec=BX_PIT_THIS s.last_usec + time_passed;
  if(time_passed || (BX_PIT_THIS s.last_next_event_time != BX_PIT_THIS s.timer.get_next_event_time()))
  {
    BX_DEBUG(("pit: RESETting timer"));
    bx_virt_timer.deactivate_timer(BX_PIT_THIS s.timer_handle[0]);
    BX_DEBUG(("deactivated timer"));
    if(BX_PIT_THIS s.timer.get_next_event_time()) {
      bx_virt_timer.activate_timer(BX_PIT_THIS s.timer_handle[0],
				  (Bit32u)BX_MAX(1,TICKS_TO_USEC(BX_PIT_THIS s.timer.get_next_event_time())),
				  0);
      BX_DEBUG(("activated timer"));
    }
    BX_PIT_THIS s.last_next_event_time = BX_PIT_THIS s.timer.get_next_event_time();
  }
  BX_DEBUG(("s.last_usec="FMT_LL"d",BX_PIT_THIS s.last_usec));
  BX_DEBUG(("s.timer_id=%d",BX_PIT_THIS s.timer_handle[0]));
  BX_DEBUG(("s.timer.get_next_event_time=%x",BX_PIT_THIS s.timer.get_next_event_time()));
  BX_DEBUG(("s.last_next_event_time=%d",BX_PIT_THIS s.last_next_event_time));
}

// static IO port read callback handler
// redirects to non-static class handler to avoid virtual functions

Bit32u bx_pit_c::read_handler(void *this_ptr, Bit32u address, unsigned io_len)
{
#if !BX_USE_PIT_SMF
  bx_pit_c *class_ptr = (bx_pit_c *) this_ptr;
  return class_ptr->read(address, io_len);
}

Bit32u bx_pit_c::read(Bit32u address, unsigned io_len)
{
#else
  UNUSED(this_ptr);
#endif  // !BX_USE_PIT_SMF
  BX_DEBUG(("pit: entering read handler"));

  handle_timer();

  Bit64u my_time_usec = bx_virt_timer.time_usec();

  if (bx_dbg.pit)
    BX_INFO(("pit: io read from port %04x", (unsigned) address));

  switch (address) {

    case 0x40: /* timer 0 - system ticks */
      return(BX_PIT_THIS s.timer.read(0));
      break;
    case 0x41: /* timer 1 read */
      return(BX_PIT_THIS s.timer.read(1));
      break;
    case 0x42: /* timer 2 read */
      return(BX_PIT_THIS s.timer.read(2));
      break;
    case 0x43: /* timer 1 read */
      return(BX_PIT_THIS s.timer.read(3));
      break;

    case 0x61:
      /* AT, port 61h */
      BX_PIT_THIS s.refresh_clock_div2 = (bx_bool)((my_time_usec / 15) & 1);
      return (BX_PIT_THIS s.timer.read_OUT(2)<<5) |
             (BX_PIT_THIS s.refresh_clock_div2<<4) |
             (BX_PIT_THIS s.speaker_data_on<<1) |
             (BX_PIT_THIS s.timer.read_GATE(2)?1:0);
      break;

    default:
      BX_PANIC(("pit: unsupported io read from port %04x", address));
  }
  return(0); /* keep compiler happy */
}

// static IO port write callback handler
// redirects to non-static class handler to avoid virtual functions

void bx_pit_c::write_handler(void *this_ptr, Bit32u address, Bit32u dvalue, unsigned io_len)
{
#if !BX_USE_PIT_SMF
  bx_pit_c *class_ptr = (bx_pit_c *) this_ptr;
  class_ptr->write(address, dvalue, io_len);
}

void bx_pit_c::write(Bit32u address, Bit32u dvalue, unsigned io_len)
{
#else
  UNUSED(this_ptr);
#endif  // !BX_USE_PIT_SMF
  Bit8u   value;
  Bit64u my_time_usec = bx_virt_timer.time_usec();
  Bit64u time_passed = my_time_usec-BX_PIT_THIS s.last_usec;
  Bit32u time_passed32 = (Bit32u)time_passed;

  BX_DEBUG(("pit: entering write handler"));

  if(time_passed32) {
    periodic(time_passed32);
  }
  BX_PIT_THIS s.last_usec=BX_PIT_THIS s.last_usec + time_passed;

  value = (Bit8u) dvalue;

  if (bx_dbg.pit)
    BX_INFO(("pit: write to port %04x = %02x",
      (unsigned) address, (unsigned) value));

  switch (address) {
    case 0x40: /* timer 0: write count register */
      BX_PIT_THIS s.timer.write(0, value);
      break;

    case 0x41: /* timer 1: write count register */
      BX_PIT_THIS s.timer.write(1, value);
      break;

    case 0x42: /* timer 2: write count register */
      BX_PIT_THIS s.timer.write(2, value);
      break;

    case 0x43: /* timer 0-2 mode control */
      BX_PIT_THIS s.timer.write(3, value);
      break;

    case 0x61:
      BX_PIT_THIS s.speaker_data_on = (value >> 1) & 0x01;
      if (BX_PIT_THIS s.speaker_data_on) {
	  DEV_speaker_beep_on((float)(1193180.0 / this->get_timer(2)));
      } else {
	  DEV_speaker_beep_off();
      }
      /* ??? only on AT+ */
      BX_PIT_THIS s.timer.set_GATE(2, value & 0x01);
      break;

    default:
      BX_PANIC(("pit: unsupported io write to port %04x = %02x",
        (unsigned) address, (unsigned) value));
  }

  if(time_passed || (BX_PIT_THIS s.last_next_event_time != BX_PIT_THIS s.timer.get_next_event_time()))
  {
    BX_DEBUG(("pit: RESETting timer"));
    bx_virt_timer.deactivate_timer(BX_PIT_THIS s.timer_handle[0]);
    BX_DEBUG(("deactivated timer"));
    if(BX_PIT_THIS s.timer.get_next_event_time()) {
      bx_virt_timer.activate_timer(BX_PIT_THIS s.timer_handle[0],
				  (Bit32u)BX_MAX(1,TICKS_TO_USEC(BX_PIT_THIS s.timer.get_next_event_time())),
				  0);
      BX_DEBUG(("activated timer"));
    }
    BX_PIT_THIS s.last_next_event_time = BX_PIT_THIS s.timer.get_next_event_time();
  }
  BX_DEBUG(("s.last_usec="FMT_LL"d",BX_PIT_THIS s.last_usec));
  BX_DEBUG(("s.timer_id=%d",BX_PIT_THIS s.timer_handle[0]));
  BX_DEBUG(("s.timer.get_next_event_time=%x",BX_PIT_THIS s.timer.get_next_event_time()));
  BX_DEBUG(("s.last_next_event_time=%d",BX_PIT_THIS s.last_next_event_time));

}

bx_bool bx_pit_c::periodic(Bit32u usec_delta)
{
  Bit32u ticks_delta = 0;

  BX_PIT_THIS s.total_usec += usec_delta;
  ticks_delta=(Bit32u)((USEC_TO_TICKS((Bit64u)(BX_PIT_THIS s.total_usec)))-BX_PIT_THIS s.total_ticks);
  BX_PIT_THIS s.total_ticks += ticks_delta;

  while ((BX_PIT_THIS s.total_ticks >= TICKS_PER_SECOND) && (BX_PIT_THIS s.total_usec >= USEC_PER_SECOND)) {
    BX_PIT_THIS s.total_ticks -= TICKS_PER_SECOND;
    BX_PIT_THIS s.total_usec  -= USEC_PER_SECOND;
  }

  while(ticks_delta>0) {
    Bit32u maxchange=BX_PIT_THIS s.timer.get_next_event_time();
    Bit32u timedelta=maxchange;
    if((maxchange==0) || (maxchange>ticks_delta)) {
      timedelta=ticks_delta;
    }
    BX_PIT_THIS s.timer.clock_all(timedelta);
    ticks_delta-=timedelta;
  }

  return 0;
}

void bx_pit_c::irq_handler(bx_bool value)
{
  if (value == 1) {
    DEV_pic_raise_irq(0);
  } else {
    DEV_pic_lower_irq(0);
  }
}
