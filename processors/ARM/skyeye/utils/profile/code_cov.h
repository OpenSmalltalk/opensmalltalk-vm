/*
        cov_prof.h - some defination for code coverage
        Copyright (C) 2008 Skyeye Develop Group
        for help please send mail to <skyeye-developer@lists.gro.clinux.org>

        This program is free software; you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation; either version 2 of the License, or
        (at your option) any later version.

        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program; if not, write to the Free Software
        Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/
/*
 * 03/08/2008   Michael.Kang  <blackfin.kang@gmail.com>
 */

#ifndef __CODE_COV_H__
#define __CODE_COV_H__

#define READ_FLAG 0x4
#define WRITE_FLAG 0x2
#define EXEC_FLAG 0x1

void cov_init(int start_addr, int end_addr);
void cov_prof(int flags, WORD addr);
void cov_fini(char * filename);

#endif
