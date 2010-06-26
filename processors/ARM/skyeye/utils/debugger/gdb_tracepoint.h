/*
	debugger.h - necessary definition for skyeye debugger
	Copyright (C) 2003 Skyeye Develop Group
	for help please send mail to <skyeye-developer@lists.sf.linuxforum.net>

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

#ifndef _GDB_TRACEPOINT_H_
#define _GDB_TRACEPOINT_H_

typedef enum
{
    ACTION_UNASSIGNED=0,
    ACTION_COLLECT =1,
    ACTION_WHILE 
}action_type;

typedef enum
{
    COLLECT_UNASSIGNED=0,
    COLLECT_REGISTERS =1,
    COLLECT_MEMORY,
    COLLECT_EXPRESSION 
}collect_action_type;  


typedef struct
{
    unsigned int mask;
}register_collect;

typedef struct
{
    int base_reg;
    unsigned int offset;
    unsigned int length;
}memory_collect;

typedef struct
{
    int exp; //dummmy implementation
}expression_collect;

typedef struct
{
    collect_action_type type;
    union 
    {
        register_collect rc;
        memory_collect mc;
        expression_collect ec;
    } description;
     
}collect_action;


typedef struct
{
    unsigned int step_count;
    unsigned int remaining_steps;
}while_action;

typedef struct t_action
{
    action_type type;  
    union 
    {
        collect_action   ca;
        while_action     wa;
    } action_data;
    struct t_action *sibling;
    struct t_action *child;
     
}action;

typedef struct t_collect_record
{
    collect_action  *ca;
    char            *collect_data;
    unsigned int    collect_data_length;
     
    struct t_collect_record * next;
     
}collect_record;

typedef struct t_frame_buffer
{
    unsigned int   tp_number;
    unsigned int   frame_number;
    collect_record *head_record;
    struct t_frame_buffer *next;
}frame_buffer;

typedef enum
{
    TRACEPOINT_DISABLED =0,
    TRACEPOINT_ENABLED,
    TRACEPOINT_STEPPING,
}tracepoint_status;

typedef enum
{
    TRACE_STARTED=0,
    TRACE_STOPPED,
    TRACE_FOCUSING,
}trace_status;

typedef struct
{
    unsigned int         tp_address;  //address of the trace point
    unsigned int         number;      //the number assigned to the trace point
    action               *actions;    //tree of the actions to be executed
    tracepoint_status    status;      //
    unsigned int         pass_count;  //count of the total pass bey the tracepoint
    unsigned int         remaining_pass;// remainig passes
    unsigned int         remaining_step; //should'nt be in the while action ?
}tracepoint_def;

typedef struct t_ro_region
{
    unsigned int  start;
    unsigned int  end;
    struct t_ro_region *next;
}ro_region;

int add_tracepoint (unsigned int tp_number,unsigned int tp_address);
int find_tp_id (unsigned int tp_number,unsigned int tp_address);

void set_tracepoint_address(int tp_id, unsigned int address );
void set_tracepoint_number(int tp_id, unsigned int number );
void set_tracepoint_status(int tp_id, tracepoint_status status);
void set_tracepoint_pass_count(int tp_id, unsigned int pass_count );
void set_tracepoint_remaining_pass(int tp_id, unsigned int remaining_pass );
void set_tracepoint_remaining_step(int tp_id, unsigned int remaining_step );
unsigned int get_tracepoint_remaining_step(int tp_id);


action* prepare_action(int tp_id, action *parent_action);
void set_action_type (action *action_p, action_type type);
void set_action_data_type(action *action_p, collect_action_type type );
void set_rc_action_mask( action *action_p, unsigned int mask);
void set_wa_step_count (action *action_p, unsigned int step_count);


void add_ro_region(unsigned int start, unsigned int end);
int is_in_ro_region(unsigned int addr, int length);

void trace_fetch_registers(int regno, unsigned char *memory);
int trace_read (unsigned int addr, unsigned char *buffer, int size);
int select_frame_buffer_by_tpn (int tracepoint_number, int *frame_number);
int select_frame_buffer_by_fn  (int *tracepoint_number, int frame_number);

void handle_tracepoint(int i);

void init_tracepoints ();
void start_trace_recording ();
void stop_trace_recording ();
void start_trace_focusing ();
void stop_trace_focusing ();

#endif  //_GDB_TRACEPOINT_H_

