/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       sqConfig.h                                       */
/*  platform identification and configuration                             */
/**************************************************************************/



#if defined(ACORN)
# if defined(SQ_CONFIG_DONE)
#   error configuration conflict
# endif
# define SQ_CONFIG_DONE
#endif
