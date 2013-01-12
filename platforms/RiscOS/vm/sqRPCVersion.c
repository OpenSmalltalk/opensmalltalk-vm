/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  with Raspberry Pi in testing. Other machines not yet tested.          */
/*                       sqRPCVersion.c                                   */
/* A trivial file to recompile every time a VM is built so as to track    */
/* the exact time and date of build                                       */
/**************************************************************************/

char	VMVersion[] = "3.9 of "__DATE__"@"__TIME__;
