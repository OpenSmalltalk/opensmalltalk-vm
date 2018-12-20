/////////////////////////////////////////////////////////////////////////
// $Id: symbols.cc,v 1.12 2008/06/16 17:09:52 sshwarts Exp $
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
/////////////////////////////////////////////////////////////////////////

#include "bochs.h"
#include "cpu/cpu.h"

#if BX_DEBUGGER
#if !((BX_HAVE_HASH_MAP || BX_HAVE_HASH_MAP_H) && (BX_HAVE_SET || BX_HAVE_SET_H))

static char *BX_HAVE_HASH_MAP_ERR = "context not implemented because BX_HAVE_HASH_MAP=0\n";

char* bx_dbg_symbolic_address(Bit32u context, Bit32u eip, Bit32u base)
{
  static bx_bool first = true;
  if (first) {
    dbg_printf(BX_HAVE_HASH_MAP_ERR);
    first = false;
  }
  return "unk. ctxt";
}

char* bx_dbg_symbolic_address_16bit(Bit32u eip, Bit32u cs)
{
  // just prints an error anyway
  return bx_dbg_symbolic_address (0,0,0);
}

int bx_dbg_symbol_command(char* filename, bx_bool global, Bit32u offset)
{
  dbg_printf(BX_HAVE_HASH_MAP_ERR);
  return -1;
}

void bx_dbg_info_symbols_command(char *Symbol)
{
  dbg_printf(BX_HAVE_HASH_MAP_ERR);
}

int bx_dbg_lbreakpoint_symbol_command(char *Symbol)
{
  dbg_printf(BX_HAVE_HASH_MAP_ERR);
  return -1;
}

Bit32u bx_dbg_get_symbol_value(char *Symbol)
{
  return 0;
}

char* bx_dbg_disasm_symbolic_address(Bit32u eip, Bit32u base)
{
  return 0;
}

#else   /* if BX_HAVE_HASH_MAP == 1 */

/* Haven't figured out how to port this code to OSF1 cxx compiler.
   Until a more portable solution is found, at least make it easy
   to disable the template code:  just set BX_HAVE_HASH_MAP=0
   in config.h */
#if BX_HAVE_HASH_MAP
#include <hash_map>
#elif BX_HAVE_HASH_MAP_H
#include <hash_map.h>
#endif

#if BX_HAVE_SET
#include <set>
#elif BX_HAVE_SET_H
#include <set.h>
#endif

using namespace std;
#ifdef __GNUC__
using namespace __gnu_cxx;
#endif

struct symbol_entry_t
{
  symbol_entry_t (Bit32u _start = 0, char* _name = 0)
  {
    start = _start;
    name = _name;
  }

  char* name;
  Bit32u start;
};

struct lt_symbol_entry_t
{
  bool operator()(const symbol_entry_t* s1, const symbol_entry_t* s2) const
  {
    return s1->start < s2->start;
  }
};

struct lt_rsymbol_entry_t
{
  bool operator()(const symbol_entry_t* s1, const symbol_entry_t* s2) const
  {
    return strcoll(s1->name, s2->name) < 0;
  }
};

struct context_t
{
  typedef set<symbol_entry_t*,lt_symbol_entry_t>  sym_set_t;
  typedef set<symbol_entry_t*,lt_rsymbol_entry_t> rsym_set_t;

  context_t (Bit32u);
 ~context_t();

  static context_t* get_context(Bit32u);
  symbol_entry_t* get_symbol_entry(Bit32u);
  symbol_entry_t* get_symbol_entry(const char *Symbol) const;
  void add_symbol(symbol_entry_t*);
  const sym_set_t* get_all_symbols() const {return syms;}
  const rsym_set_t* get_all_rsymbols() const {return rsyms;}

private:
  static hash_map<int,context_t*>* map;
  // Forvard references (find name by address)
  sym_set_t* syms;
  // Reverse references (find address by name)
  rsym_set_t* rsyms;
  Bit32u id;
};

hash_map<int,context_t*>* context_t::map = new hash_map<int,context_t*>;

context_t::context_t (Bit32u _id)
{
  id = _id;
  syms = new sym_set_t;
  rsyms = new rsym_set_t;
  (*map)[id] = this;
}

context_t::~context_t()
{
  if(syms) {
    sym_set_t::iterator iter;
    for(iter=syms->begin();iter!=syms->end();++iter)
    if(*iter)
      delete *iter;
  }

  if(rsyms) {
    rsym_set_t::iterator iter;
    for(iter=rsyms->begin();iter!=rsyms->end();++iter)
      if(*iter)
        delete *iter;
  }
}

context_t* context_t::get_context(Bit32u i)
{
  return (*map)[i];
}

symbol_entry_t* context_t::get_symbol_entry(Bit32u ip)
{
  symbol_entry_t probe;
  probe.start = ip;
  // find the first symbol whose address is greater than ip.
  if (syms->empty ()) return 0;
  sym_set_t::iterator iter = syms->upper_bound(&probe);

  if (iter == syms->end()) { // No symbol found
    return 0;
  }

  return *(--iter);
}

symbol_entry_t* context_t::get_symbol_entry(const char *Symbol) const
{
  symbol_entry_t probe;
  probe.name=(char *)Symbol;

  if (rsyms->empty())
    return 0;

  rsym_set_t::const_iterator iter;
  iter=rsyms->find(&probe);
  if(iter==rsyms->end()) // No symbol found
    return 0;
  return *iter;
}

void context_t::add_symbol(symbol_entry_t* sym)
{
  syms->insert(sym);
  rsyms->insert(sym);
}

Bit32u bx_dbg_get_symbol_value(char *Symbol)
{
  context_t* cntx = context_t::get_context(0);
  if(!cntx) // Context not found
    return 0;

  if (Symbol[0]=='\"') Symbol++;
  int len = strlen(Symbol);
  if (Symbol[len - 1] == '\"') Symbol[len - 1] = '\0';

  symbol_entry_t* sym=cntx->get_symbol_entry(Symbol);
  if(!sym) // Symbol not found
    return 0;

  return sym->start;
}

char* bx_dbg_symbolic_address(Bit32u context, Bit32u eip, Bit32u base)
{
  static char buf[80];
#if 0
  // bbd: I don't see why we shouldn't allow symbol lookups on
  // segments with a nonzero base.  I need to trace user
  // processes in Linux, which have a base of 0xc0000000.
  if (base != 0) {
    snprintf (buf, 80, "non-zero base");
    return buf;
  }
#endif
  // Look up this context
  context_t* cntx = context_t::get_context(context);
  if (!cntx) {
    // Try global context
    cntx = context_t::get_context(0);
    if (!cntx) {
      snprintf (buf, 80, "unk. ctxt");
      return buf;
    }
  }
  // full linear address not only eip (for nonzero based segments)
  symbol_entry_t* entr = cntx->get_symbol_entry(base+eip);
  if (!entr) {
    snprintf (buf, 80, "no symbol");
    return buf;
  }
  snprintf (buf, 80, "%s+%x", entr->name, (base+eip) - entr->start);
  return buf;
}

char* bx_dbg_disasm_symbolic_address(Bit32u eip, Bit32u base)
{
  static char buf[80];

  // Try global context
  context_t* cntx = context_t::get_context(0);
  if (!cntx) {
    return 0;
  }

  // full linear address not only eip (for nonzero based segments)
  symbol_entry_t* entr = cntx->get_symbol_entry(base+eip);
  if (!entr) {
    return 0;
  }
  snprintf (buf, 80, "%s+%x", entr->name, (base+eip) - entr->start);
  return buf;
}

char* bx_dbg_symbolic_address_16bit(Bit32u eip, Bit32u cs)
{
  // in 16-bit code, the segment selector and offset are combined into a
  // 20-bit linear address = (segment selector<<4) + offset.
  eip &= 0xffff;
  cs &= 0xffff;
  return bx_dbg_symbolic_address (0, eip+(cs<<4), 0);
}

int bx_dbg_symbol_command(char* filename, bx_bool global, Bit32u offset)
{
  if (filename[0] == '"')
    filename++;
  int len = strlen(filename);
  if (filename[len - 1] == '"')
    filename[len - 1] = '\0';

  // Install symbols in correct context (page table)
  // The file format should be
  // address symbol (example '00002afe _StartLoseNT')

  context_t* cntx = (global) ? context_t::get_context(0)
      : context_t::get_context((BX_CPU(dbg_cpu)->cr3) >> 12);

  if (!cntx) {
    cntx = (global) ? new context_t(0)
       : new context_t((BX_CPU(dbg_cpu)->cr3) >> 12);
  }

  FILE* fp = fopen(filename, "rt"); // 't' is need for win32, unixes simply ignore it
  if (!fp) {
    dbg_printf ("Could not open symbol file '%s'\n", filename);
    return -1;
  }

  // C++/C# symbols can be long
  char buf[512];
  int  line_num = 1;

  while (fgets(buf, sizeof(buf), fp)) {
    // handle end of line (before error messages)
    len = strlen(buf);
    bool whole_line = (buf[len - 1] == '\n');
    if (whole_line)
      buf[len - 1] = 0;

    // parse
    char* sym_name;
    Bit32u addr = strtoul(buf, &sym_name, 16);

    if (!isspace(*sym_name)) {
      if (*sym_name == 0)
        dbg_printf("%s:%d: missing symbol name\n", filename, line_num);
      else
        dbg_printf("%s:%d: syntax error near '%s'\n", filename, line_num, sym_name);
      return -1;
    }
    ++sym_name;

    symbol_entry_t* sym = new symbol_entry_t(addr + offset, strdup(sym_name));
    cntx->add_symbol(sym);

    // skip the rest of long line
    while (!whole_line) {
      if (!fgets(buf, sizeof(buf), fp))
        break;
      // actually, last line can end without newline, but then
      // we'll just break at the next iteration because of EOF
      whole_line = (buf[strlen(buf)-1] == '\n');
    }
    ++line_num;
  }
  return 0;
}

// chack if s1 is prefix of s2
static bool bx_dbg_strprefix(const char *s1, const char *s2)
{
  if(!s1 || !s2)
    return false;

  size_t len=strlen(s1);

  if(len>strlen(s2))
    return false;
  return strncmp(s1, s2, len)==0;
}

void bx_dbg_info_symbols_command(char *Symbol)
{
  context_t* cntx = context_t::get_context(0);

  if(!cntx) {
    dbg_printf ("Global context not available\n");
    return;
  }

  if(Symbol) {
    const context_t::rsym_set_t* rsyms;

    rsyms=cntx->get_all_rsymbols();
    if (rsyms->empty ()) {
      dbg_printf ("Symbols not loaded\n");
      return;
    }
    // remove leading and trailing quotas
    if (Symbol[0]=='\"') Symbol++;
    int len = strlen(Symbol);
    if (Symbol[len - 1] == '\"') Symbol[len - 1] = '\0';

    symbol_entry_t probe;
    probe.name=Symbol;
    context_t::rsym_set_t::const_iterator iter;
    iter=rsyms->lower_bound(&probe);

    if(iter==rsyms->end() || !bx_dbg_strprefix(Symbol, (*iter)->name))
      dbg_printf ("No symbols found\n");
    else {
      for(;iter!=rsyms->end() && bx_dbg_strprefix(Symbol, (*iter)->name);++iter) {
        dbg_printf ("%08x: %s\n", (*iter)->start, (*iter)->name);
      }
    }
  }
  else {
    const context_t::sym_set_t* syms;

    syms=cntx->get_all_symbols();
    if (syms->empty ()) {
      dbg_printf ("Symbols not loaded\n");
      return;
    }

    context_t::sym_set_t::const_iterator iter;
    for(iter = syms->begin();iter!=syms->end();++iter) {
      dbg_printf ("%08x: %s\n", (*iter)->start, (*iter)->name);
    }
  }
}

int bx_dbg_lbreakpoint_symbol_command(char *Symbol)
{
  context_t* cntx = context_t::get_context(0);
  if(!cntx) {
    dbg_printf ("Global context not available\n");
    return -1;
  }
  if (Symbol[0]=='\"') Symbol++;
  int len = strlen(Symbol);
  if (Symbol[len - 1] == '\"') Symbol[len - 1] = '\0';

  const symbol_entry_t* sym=cntx->get_symbol_entry(Symbol);
  if(sym)
    return bx_dbg_lbreakpoint_command(bkRegular, sym->start);
  dbg_printf ("Symbol not found\n");
  return -1;
}

#endif
#endif
