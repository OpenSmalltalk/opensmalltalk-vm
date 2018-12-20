////////////////////////////////////////////////////////////////////////
// $Id: virt_timer.h,v 1.15 2008/02/15 22:05:43 sshwarts Exp $
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

#ifndef _BX_VIRT_TIMER_H
#define _BX_VIRT_TIMER_H

// should be adjusted if want to support more SMP processors
#define BX_MAX_VIRTUAL_TIMERS (32)
#define BX_NULL_VIRTUAL_TIMER_HANDLE 10000

#define BX_MAX_VIRTUAL_TIME (0x7fffffff)

class bx_virt_timer_c : public logfunctions {
private:

  struct {
    bx_bool inUse;      // Timer slot is in-use (currently registered).
    Bit64u  period;     // Timer periodocity in virtual useconds.
    Bit64u  timeToFire; // Time to fire next (in virtual useconds).
    bx_bool active;     // 0=inactive, 1=active.
    bx_bool continuous; // 0=one-shot timer, 1=continuous periodicity.
    bx_timer_handler_t funct;  // A callback function for when the
                               //   timer fires.
                               //   This function MUST return.
    void *this_ptr;            // The this-> pointer for C++ callbacks
                               //   has to be stored as well.
    char id[BxMaxTimerIDLen]; // String ID of timer.
  } timer[BX_MAX_VIRTUAL_TIMERS];

  unsigned   numTimers;  // Number of currently allocated timers.

  //Variables for the timer subsystem:
  Bit64u current_timers_time;
  Bit64u timers_next_event_time;

  Bit64u last_sequential_time;
  bx_bool in_timer_handler;

  //Variables for the time sync subsystem:
  Bit64u virtual_next_event_time;
  Bit64u current_virtual_time;

  //Real time variables:
  Bit64u last_real_time;
  Bit64u total_real_usec;
  Bit64u last_realtime_delta;
  //System time variables:
  Bit64u last_usec;
  Bit64u usec_per_second;
  Bit64u stored_delta;
  Bit64u last_system_usec;
  Bit64u em_last_realtime;
  //Virtual timer variables:
  Bit64u total_ticks;
  Bit64u last_realtime_ticks;
  Bit64u ticks_per_second;

  bx_bool init_done;

  int system_timer_id;

  //Whether or not to use virtual timers.
  bx_bool use_virtual_timers;
  bx_bool virtual_timers_realtime;

  // A special null timer is always inserted in the timer[0] slot.  This
  // make sure that at least one timer is always active, and that the
  // duration is always less than a maximum 32-bit integer, so a 32-bit
  // counter can be used for the current countdown.
  static const Bit64u NullTimerInterval;
  static void nullTimer(void* this_ptr);

  //Step the given number of cycles, optionally calling any timer handlers.
  void periodic(Bit64u time_passed);

  //Called when next_event_time changes.
  void next_event_time_update(void);

  //Called to advance the virtual time.
  // calls periodic as needed.
  void advance_virtual_time(Bit64u time_passed);

public:

  bx_virt_timer_c();
  virtual ~bx_virt_timer_c() {}

  //Get the current virtual time.
  //  This may return the same value on subsequent calls.
  Bit64u time_usec(void);

  //Get the current virtual time.
  //  This will return a monotonically increasing value.
  // MUST NOT be called from within a timer handler.
  Bit64u time_usec_sequential(void);

  //Register a timer handler to go off after a given interval.
  //Register a timer handler to go off with a periodic interval.
  int  register_timer(void *this_ptr, bx_timer_handler_t handler,
                         Bit32u useconds,
                         bx_bool continuous, bx_bool active, const char *id);

  //unregister a previously registered timer.
  bx_bool unregisterTimer(unsigned timerID);

  void start_timers(void);

  //activate a deactivated but registered timer.
  void activate_timer(unsigned timer_index, Bit32u useconds,
                         bx_bool continuous);

  //deactivate (but don't unregister) a currently registered timer.
  void deactivate_timer(unsigned timer_index);


  //Timer handler passed to pc_system
  static void pc_system_timer_handler(void* this_ptr);

  //The real timer handler.
  void timer_handler();

  //Initialization step #1 in constructor and for cleanup
  void setup(void);

  //Initialization step #2
  void init(void);

  void register_state(void);
};

extern bx_virt_timer_c bx_virt_timer;

#endif // _BX_VIRT_TIMER_H
