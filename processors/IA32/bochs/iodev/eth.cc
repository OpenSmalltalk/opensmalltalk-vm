/////////////////////////////////////////////////////////////////////////
// $Id: eth.cc,v 1.26 2008/02/15 22:05:42 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2001  MandrakeSoft S.A.
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

// eth.cc  - helper code to find and create pktmover classes

// Peter Grehan (grehan@iprg.nokia.com) coded all of this
// NE2000/ether stuff.

// Define BX_PLUGGABLE in files that can be compiled into plugins.  For
// platforms that require a special tag on exported symbols, BX_PLUGGABLE
// is used to know when we are exporting symbols and when we are importing.
#define BX_PLUGGABLE

#define NO_DEVICE_INCLUDES
#include "iodev.h"

#if BX_NETWORKING

#include "eth.h"

#define LOG_THIS /* not needed */

eth_locator_c *eth_locator_c::all;

//
// Each pktmover module has a static locator class that registers
// here
//
eth_locator_c::eth_locator_c(const char *type)
{
  next = all;
  all  = this;
  this->type = type;
}

#ifdef ETH_NULL
extern class bx_null_locator_c bx_null_match;
#endif
#ifdef ETH_FBSD
extern class bx_fbsd_locator_c bx_fbsd_match;
#endif
#ifdef ETH_LINUX
extern class bx_linux_locator_c bx_linux_match;
#endif
#ifdef ETH_WIN32
extern class bx_win32_locator_c bx_win32_match;
#endif
#if HAVE_ETHERTAP
extern class bx_tap_locator_c bx_tap_match;
#endif
#if HAVE_TUNTAP
extern class bx_tuntap_locator_c bx_tuntap_match;
#endif
#if HAVE_VDE
extern class bx_vde_locator_c bx_vde_match;
#endif
#ifdef ETH_ARPBACK
extern class bx_arpback_locator_c bx_arpback_match;
#endif
extern class bx_vnet_locator_c bx_vnet_match;

//
// Called by ethernet chip emulations to locate and create a pktmover
// object
//
eth_pktmover_c *
eth_locator_c::create(const char *type, const char *netif,
		      const char *macaddr,
		      eth_rx_handler_t rxh, void *rxarg, char *script)
{
#ifdef eth_static_constructors
  for (eth_locator_c *p = all; p != NULL; p = p->next) {
    if (strcmp(type, p->type) == 0)
      return (p->allocate(netif, macaddr, rxh, rxarg, script));
  }
#else
  eth_locator_c *ptr = 0;

#ifdef ETH_ARPBACK
  {
    if (!strcmp(type, "arpback"))
      ptr = (eth_locator_c *) &bx_arpback_match;
  }
#endif
#ifdef ETH_NULL
  {
    if (!strcmp(type, "null"))
      ptr = (eth_locator_c *) &bx_null_match;
  }
#endif
#ifdef ETH_FBSD
  {
    if (!strcmp(type, "fbsd"))
      ptr = (eth_locator_c *) &bx_fbsd_match;
  }
#endif
#ifdef ETH_LINUX
  {
    if (!strcmp(type, "linux"))
      ptr = (eth_locator_c *) &bx_linux_match;
  }
#endif
#if HAVE_TUNTAP
  {
    if (!strcmp(type, "tuntap"))
      ptr = (eth_locator_c *) &bx_tuntap_match;
  }
#endif
#if HAVE_VDE
  {
    if (!strcmp(type, "vde"))
      ptr = (eth_locator_c *) &bx_vde_match;
  }
#endif
#if HAVE_ETHERTAP
  {
    if (!strcmp(type, "tap"))
      ptr = (eth_locator_c *) &bx_tap_match;
  }
#endif
#ifdef ETH_WIN32
  {
    if(!strcmp(type, "win32"))
      ptr = (eth_locator_c *) &bx_win32_match;
  }
#endif
  {
    if (!strcmp(type, "vnet"))
      ptr = (eth_locator_c *) &bx_vnet_match;
  }
  if (ptr)
    return (ptr->allocate(netif, macaddr, rxh, rxarg, script));
#endif

  return (NULL);
}

#if (HAVE_ETHERTAP==1) || (HAVE_TUNTAP==1) || (HAVE_VDE==1)

extern "C" {
#include <sys/wait.h>
};

#undef LOG_THIS
#define LOG_THIS bx_devices.pluginNE2kDevice->

// This is a utility script used for tuntap or ethertap
int execute_script(char* scriptname, char* arg1)
{
  int pid,status;

  if (!(pid=fork())) {
    char filename[BX_PATHNAME_LEN];
    if (scriptname[0]=='/') {
      strcpy(filename, scriptname);
    }
    else {
      getcwd(filename, BX_PATHNAME_LEN);
      strcat(filename, "/");
      strcat(filename, scriptname);
    }

    // execute the script
    BX_INFO(("Executing script '%s %s'",filename,arg1));
    execle(filename, scriptname, arg1, NULL, NULL);

    // if we get here there has been a problem
    exit(-1);
  }

  wait (&status);
  if (!WIFEXITED(status)) {
    return -1;
  }
  return WEXITSTATUS(status);
}

#endif // (HAVE_ETHERTAP==1) || (HAVE_TUNTAP==1)

#endif /* if BX_NETWORKING */
