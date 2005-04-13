/*
 *  sqMacUnixCommandLineInterface.h
 *  SqueakVMForCarbon
 *
 *  Created by John M McIntosh on 3/19/05 from the altered Unix File. 
 * 
 *   Copyright (C) 1996-2004 by John M McIntosh and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 
 
 *   
 *   This file was part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 
 * Much of this code comes from the unix port
 * Ian Piumarta <ian.piumarta@inria.fr>
 */

#include <Carbon/Carbon.h>
void unixArgcInterface(int argc, char **argv, char **envp);
char *unixArgcInterfaceGetParm(int n);
