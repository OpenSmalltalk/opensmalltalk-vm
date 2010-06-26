#include "emul.h"

/* Deliver external events. The (events) bitset is consulted synchronously at
 * appropriate places in the fetch-execute loop.
 */

void deliver_cold_reset(MIPS_State* mstate)
{
    	mstate->events |= cold_reset_event;
}

void deliver_soft_reset(MIPS_State* mstate)
{
    	mstate->events |= soft_reset_event;
}

