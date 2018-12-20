/////////////////////////////////////////////////////////////////////////
// $Id: icache.cc,v 1.16 2008/08/12 19:25:42 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
//   Copyright (c) 2007 Stanislav Shwartsman
//          Written by Stanislav Shwartsman [sshwarts at sourceforge net]
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
//
/////////////////////////////////////////////////////////////////////////

#define NEED_CPU_REG_SHORTCUTS 1
#include "bochs.h"
#include "cpu.h"
#define LOG_THIS BX_CPU_THIS_PTR

bx_bool BX_CPU_C::fetchInstruction(bxInstruction_c *iStorage, Bit32u eipBiased)
{
  unsigned remainingInPage = BX_CPU_THIS_PTR eipPageWindowSize - eipBiased;
  const Bit8u *fetchPtr = BX_CPU_THIS_PTR eipFetchPtr + eipBiased;
  unsigned ret;

#if BX_SUPPORT_X86_64
  if (BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64)
    ret = fetchDecode64(fetchPtr, iStorage, remainingInPage);
  else
#endif
    ret = fetchDecode32(fetchPtr, iStorage, remainingInPage);

  if (ret==0) {
    // handle instrumentation callback inside boundaryFetch
    boundaryFetch(fetchPtr, remainingInPage, iStorage);
    return 0;
  }

#if BX_INSTRUMENTATION
  BX_INSTR_OPCODE(BX_CPU_ID, fetchPtr, iStorage->ilen(),
       BX_CPU_THIS_PTR sregs[BX_SEG_REG_CS].cache.u.segment.d_b, Is64BitMode());
#endif

  return 1;
}

#if BX_SUPPORT_ICACHE

bxPageWriteStampTable pageWriteStampTable;

void purgeICaches(void)
{
  for (unsigned i=0; i<BX_SMP_PROCESSORS; i++)
    BX_CPU(i)->iCache.purgeICacheEntries();

  pageWriteStampTable.purgeWriteStamps();
}

void flushICaches(void)
{
  for (unsigned i=0; i<BX_SMP_PROCESSORS; i++)
    BX_CPU(i)->iCache.flushICacheEntries();

  pageWriteStampTable.resetWriteStamps();
}

#if BX_SUPPORT_TRACE_CACHE

void handleSMC(void)
{
  for (unsigned i=0; i<BX_SMP_PROCESSORS; i++)
    BX_CPU(i)->async_event |= BX_ASYNC_EVENT_STOP_TRACE;
}

void BX_CPU_C::serveICacheMiss(bxICacheEntry_c *cache_entry, Bit32u eipBiased, bx_phy_address pAddr)
{
  BX_CPU_THIS_PTR iCache.alloc_trace(cache_entry);

  // Cache miss. We weren't so lucky, but let's be optimistic - try to build 
  // trace from incoming instruction bytes stream !
  cache_entry->pAddr = pAddr;
  cache_entry->writeStamp = *(BX_CPU_THIS_PTR currPageWriteStampPtr);

  unsigned remainingInPage = BX_CPU_THIS_PTR eipPageWindowSize - eipBiased;
  const Bit8u *fetchPtr = BX_CPU_THIS_PTR eipFetchPtr + eipBiased;
  unsigned ret, max_length = BX_MAX_TRACE_LENGTH;

  bxInstruction_c *i = cache_entry->i;

  for (unsigned n=0;n<max_length;n++)
  {
#if BX_SUPPORT_X86_64
    if (BX_CPU_THIS_PTR cpu_mode == BX_MODE_LONG_64)
      ret = fetchDecode64(fetchPtr, i, remainingInPage);
    else
#endif
      ret = fetchDecode32(fetchPtr, i, remainingInPage);

    if (ret==0) {
      // Fetching instruction on segment/page boundary
      if (n > 0) {
         // The trace is already valid, it has several instructions inside,
         // in this case just drop the boundary instruction and stop
         // tracing.
         break;
      }
      // First instruction is boundary fetch, leave the trace cache entry 
      // invalid and do not cache the instruction.
      cache_entry->writeStamp = ICacheWriteStampInvalid;
      cache_entry->ilen = 1;
      boundaryFetch(fetchPtr, remainingInPage, i);
      return;
    }

    // add instruction to the trace
    unsigned iLen = i->ilen();
    cache_entry->ilen++;

    // continue to the next instruction
    remainingInPage -= iLen;
    if (i->getStopTraceAttr() || remainingInPage == 0) break;
    pAddr += iLen;
    fetchPtr += iLen;
    i++;

    // try to find a trace starting from current pAddr and merge
    if (mergeTraces(cache_entry, i, pAddr)) break;
  }

  BX_CPU_THIS_PTR iCache.commit_trace(cache_entry->ilen);
}

bx_bool BX_CPU_C::mergeTraces(bxICacheEntry_c *entry, bxInstruction_c *i, bx_phy_address pAddr)
{
  bxICacheEntry_c *e = BX_CPU_THIS_PTR iCache.get_entry(pAddr);

  if ((e->pAddr == pAddr) && (e->writeStamp == entry->writeStamp))
  {
    // determine max amount of instruction to take from another entry
    unsigned max_length = e->ilen;
    if (max_length + entry->ilen > BX_MAX_TRACE_LENGTH)
        max_length = BX_MAX_TRACE_LENGTH - entry->ilen;
    if(max_length == 0) return 0;

    memcpy(i, e->i, sizeof(bxInstruction_c)*max_length);
    entry->ilen += max_length;
    BX_ASSERT(entry->ilen <= BX_MAX_TRACE_LENGTH);

    return 1;
  }

  return 0;
}

#else // BX_SUPPORT_TRACE_CACHE == 0

void BX_CPU_C::serveICacheMiss(bxICacheEntry_c *cache_entry, Bit32u eipBiased, bx_phy_address pAddr)
{
  // The entry will be marked valid if fetchdecode will succeed
  cache_entry->writeStamp = ICacheWriteStampInvalid;

  if (fetchInstruction(cache_entry->i, eipBiased)) {
    cache_entry->pAddr = pAddr;
    cache_entry->writeStamp = *(BX_CPU_THIS_PTR currPageWriteStampPtr);
  }
}

#endif

#endif // BX_SUPPORT_ICACHE
