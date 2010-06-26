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

#include "skyeye2gdb.h" 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void fetch_inferior_registers (int regno, unsigned char *memory);
extern register_defs_t *current_reg_type;

int add_tracepoint (unsigned int tp_number,unsigned int tp_address)
{
    if (skyeye_ice.num_tps<MAX_TRACEPOINTS)
    { 
        skyeye_ice.tps[skyeye_ice.num_tps].tp_address=tp_address;
        skyeye_ice.tps[skyeye_ice.num_tps].number=tp_number;     
        set_tracepoint_status(skyeye_ice.num_tps, TRACEPOINT_DISABLED);
        skyeye_ice.tps[skyeye_ice.num_tps].pass_count=0;
        skyeye_ice.tps[skyeye_ice.num_tps].remaining_pass=0;
        skyeye_ice.tps[skyeye_ice.num_tps].remaining_step=0;
        skyeye_ice.num_tps++;
        return(skyeye_ice.num_tps-1);
    } 
    else 
    { 
        return (-1);
    } 
}

int find_tp_id (unsigned int tp_number,unsigned int tp_address)
{
    int i;
    for (i=0;i<skyeye_ice.num_tps;i++)
    { 
        if ((skyeye_ice.tps[i].number==tp_number)&&(skyeye_ice.tps[i].tp_address==tp_address))
            return(i);
    } 
    return(-1);
}


void set_tracepoint_status(int tp_id, tracepoint_status status)
{
    skyeye_ice.tps[tp_id].status=status;
}

tracepoint_status get_tracepoint_status(int tp_id)
{
    return (skyeye_ice.tps[tp_id].status);
}

void set_tracepoint_address(int tp_id, unsigned int address )
{
    skyeye_ice.tps[tp_id].tp_address=address;
}

unsigned int get_tracepoint_address(int tp_id)
{
    return (skyeye_ice.tps[tp_id].tp_address);
}

void set_tracepoint_number(int tp_id, unsigned int number )
{
    skyeye_ice.tps[tp_id].number=number;
}

unsigned int get_tracepoint_number(int tp_id)
{
    return (skyeye_ice.tps[tp_id].number);
}

void set_tracepoint_pass_count(int tp_id, unsigned int pass_count )
{
    skyeye_ice.tps[tp_id].pass_count=pass_count;
}

unsigned int get_tracepoint_pass_count(int tp_id)
{
    return (skyeye_ice.tps[tp_id].pass_count);
}

void set_tracepoint_remaining_pass(int tp_id, unsigned int remaining_pass )
{
    skyeye_ice.tps[tp_id].remaining_pass=remaining_pass;
}

unsigned int get_tracepoint_remaining_pass(int tp_id)
{
    return (skyeye_ice.tps[tp_id].remaining_pass);
}

void set_tracepoint_remaining_step(int tp_id, unsigned int remaining_step )
{
    skyeye_ice.tps[tp_id].remaining_step=remaining_step;
}

unsigned int get_tracepoint_remaining_step(int tp_id)
{
    return (skyeye_ice.tps[tp_id].remaining_step);
}

void populate_default_action(action * current_action)
{
    current_action->type=ACTION_UNASSIGNED;
    current_action->sibling=NULL;
    current_action->child=NULL;
}



action* prepare_action(int tp_id, action *parent_action)
{
    action * current;
    if (parent_action==NULL) //we are not in a while-stepping case 
    { 
        if(skyeye_ice.tps[tp_id].actions ==NULL)
        { 
            skyeye_ice.tps[tp_id].actions=(action *)malloc(sizeof(action));
            populate_default_action(skyeye_ice.tps[tp_id].actions);
            return(skyeye_ice.tps[tp_id].actions);
        }  
        else  
        { 
            current =skyeye_ice.tps[tp_id].actions;
        }  
    } 
    else 
    { 
        if(parent_action->child ==NULL)
        { 
            parent_action->child=(action *)malloc(sizeof(action));
            populate_default_action(parent_action->child);
            return(parent_action->child);
        }  
        else 
        { 
            current =parent_action->child;
        } 
    } 
    while (current->sibling!=NULL)
    { 
        current=current->sibling;
    } 
    current->sibling=(action *)malloc(sizeof(action));
    populate_default_action(current->sibling);
    return(current->sibling);
}




void set_action_type (action *action_p, action_type type)
{
    action_p->type=type;
}

action_type get_action_type (action *action_p)
{
    return (action_p->type);
}

void set_action_data_type(action *action_p, collect_action_type type )
{
    action_p->action_data.ca.type=type;
}

collect_action_type get_action_data_type(action *action_p)
{
    return (action_p->action_data.ca.type);
}

void set_wa_step_count (action *action_p, unsigned int step_count)
{
    action_p->action_data.wa.step_count=step_count;
}

unsigned int get_wa_step_count (action *action_p)
{
    return (action_p->action_data.wa.step_count);
}

void set_wa_remaining_steps (action *action_p, unsigned int remaining_steps)
{
    action_p->action_data.wa.remaining_steps=remaining_steps;
}

void set_rc_action_mask( action *action_p, unsigned int mask)
{
    action_p->action_data.ca.description.rc.mask=mask;
}

void set_mc_action_base_reg(action *action_p, unsigned int base_reg)
{
    action_p->action_data.ca.description.mc.base_reg=base_reg;
}

void set_mc_action_offset(action *action_p, unsigned int offset)
{
    action_p->action_data.ca.description.mc.offset=offset;
}

void set_mc_action_length(action *action_p, unsigned int length)
{
    action_p->action_data.ca.description.mc.length=length;
}

void delete_action (action * current_action)
{
    //post fix iteration in a binary tree 
    if (current_action->sibling!=NULL)
    { 
        delete_action(current_action->sibling);
        current_action->sibling=NULL;
    } 
    if (current_action->child!=NULL)
    { 
        delete_action(current_action->child);
        current_action->child=NULL;
    } 
    if ((current_action->sibling==NULL)&&(current_action->child==NULL))
    { 
        free(current_action);
    } 
     
}


void clear_ro_regions(void)
{
    ro_region * previous_ro_region ,*next_ro_region;
     
    if (skyeye_ice.ro_region_head!=NULL)
    { 
        next_ro_region = skyeye_ice.ro_region_head;
        while(next_ro_region!=NULL)
        { 
            previous_ro_region=next_ro_region;
            next_ro_region=next_ro_region->next;
            free(previous_ro_region);
        } 
        skyeye_ice.ro_region_head=NULL;   
    }   
}


int is_in_ro_region(unsigned int addr, int length)
{
    ro_region *current_ro_region;
    if (skyeye_ice.ro_region_head==NULL)
    { 
        return 0;
    } 
    current_ro_region=skyeye_ice.ro_region_head;
    while(current_ro_region!=NULL)
    { 
        if ((current_ro_region->start <=addr)&&(current_ro_region->end >=addr+length))
        { 
            return (1);
        } 
        current_ro_region=current_ro_region->next;
    } 
    return (0);       
}



void add_ro_region(unsigned int start, unsigned int end)
{
    ro_region *current_ro_region;
    if (skyeye_ice.ro_region_head!=NULL)
    { 
        current_ro_region=skyeye_ice.ro_region_head;
        while(current_ro_region->next !=NULL)
        { 
            current_ro_region=current_ro_region->next;
        } 
        current_ro_region->next=(ro_region *)malloc (sizeof(ro_region));
        current_ro_region=current_ro_region->next;
    } 
    else 
    { 
        skyeye_ice.ro_region_head=(ro_region *)malloc (sizeof(ro_region));
        current_ro_region=skyeye_ice.ro_region_head;
    } 
    current_ro_region->start=start;
    current_ro_region->end=end;
    current_ro_region->next=NULL;
}

void clear_collect_records(collect_record *head_record)
{
    collect_record * previous_collect_record ,*next_collect_record;
     
    if (head_record!=NULL)
    { 
        next_collect_record = head_record;
        while(next_collect_record!=NULL)
        { 
            previous_collect_record=next_collect_record;
            next_collect_record=next_collect_record->next;
            free(previous_collect_record);
        }        
    }     
}
     

void clear_frame_buffers(void)
{
    frame_buffer * previous_frame_buffer ,*next_frame_buffer;
     
    if (skyeye_ice.fb!=NULL)
    { 
        next_frame_buffer = skyeye_ice.fb;
        while(next_frame_buffer!=NULL)
        { 
            previous_frame_buffer=next_frame_buffer;
            next_frame_buffer=next_frame_buffer->next;
            clear_collect_records(previous_frame_buffer->head_record);
            free(previous_frame_buffer);
        } 
        skyeye_ice.fb=NULL;
        skyeye_ice.num_fb =0;
    }  
}



frame_buffer * add_frame_buffer ( void )
{
    frame_buffer * current_frame_buffer;
     
    current_frame_buffer = skyeye_ice.fb;
    if (skyeye_ice.fb ==NULL)
    { 
        skyeye_ice.fb= (frame_buffer *)malloc (sizeof(frame_buffer));
        current_frame_buffer=skyeye_ice.fb;
    } 
    else  
    { 
        while  (current_frame_buffer ->next !=NULL)
        { 
            current_frame_buffer = current_frame_buffer ->next;
        } 
        current_frame_buffer ->next =(frame_buffer *)malloc (sizeof(frame_buffer));
        current_frame_buffer=current_frame_buffer ->next;
    } 
    // set every thing to default 
    current_frame_buffer->tp_number=0;
    current_frame_buffer->frame_number=skyeye_ice.num_fb;
    current_frame_buffer->head_record=NULL;
    current_frame_buffer->next=NULL;
    skyeye_ice.num_fb++;
    return (current_frame_buffer);
}


void trace_fetch_registers(int regno, unsigned char *memory)
{
    collect_record *current_record;
    if(skyeye_ice.selected_fb!=NULL)
    { 
        current_record=skyeye_ice.selected_fb->head_record;
        while (current_record!=NULL)
        { 
            if (current_record->ca->type ==COLLECT_REGISTERS)
            { 
                memcpy (memory,current_record->collect_data,current_record->collect_data_length);
                return;
            } 
            else 
            { 
                current_record=current_record->next;
            }  
        } 
    }      
}

int trace_read (unsigned int addr, unsigned char *buffer, int size)
{
    collect_record *current_record;
    if(skyeye_ice.selected_fb!=NULL)
    { 
        current_record=skyeye_ice.selected_fb->head_record;
        while (current_record!=NULL)
        { 
            if (current_record->ca->type ==COLLECT_MEMORY)
            { 
                if ((addr >=current_record->ca->description.mc.offset)&&(addr+size<=current_record->ca->description.mc.offset+current_record->ca->description.mc.length))
                { 
                  memcpy (buffer,(current_record->collect_data)+(addr-current_record->ca->description.mc.offset),size);
                  return (size);
                } 
                else  
                { 
                    current_record=current_record->next;
                } 
            } 
            else 
            { 
                current_record=current_record->next;
            }  
        } 
    }  
    return (-1)    ;
}
     

int select_frame_buffer_by_fn (int *tracepoint_number,int frame_number)
{
    frame_buffer * current_fb;
    if ( frame_number >skyeye_ice.num_fb)
    { 
        //the frame couldn't be found 
        return (0);
    } 
    else 
    { 
        skyeye_ice.selected_fb=skyeye_ice.fb;
        current_fb=skyeye_ice.selected_fb;
        while (current_fb !=NULL)
        {  
            if (current_fb->frame_number==frame_number)
            { 
                skyeye_ice.selected_fb=current_fb;
                *tracepoint_number=skyeye_ice.selected_fb->tp_number;
                return(1);
            } 
            else  
            { 
                current_fb=current_fb->next;
            } 
        } 
    } 
    return (0);
}

int select_frame_buffer_by_tpn (int tracepoint_number, int *frame_number)
{
    frame_buffer * current_fb;
    if (skyeye_ice.selected_fb==NULL)
    { 
        skyeye_ice.selected_fb=skyeye_ice.fb;
    } 
    if (skyeye_ice.selected_fb ==NULL) return (0);
     
    current_fb=skyeye_ice.selected_fb->next;
    while (current_fb !=NULL)
    {  
        if (current_fb->tp_number==tracepoint_number)
        { 
            skyeye_ice.selected_fb=current_fb;
            *frame_number=skyeye_ice.selected_fb->frame_number;
            return(1);
        } 
        else  
        { 
            current_fb=current_fb->next;
        } 
    } 
     
    return (0);
}


void do_action (unsigned int tp_id, action * current_action, frame_buffer * record_fb)
{
    int size;
    unsigned char * buffer ;
    collect_record * current_collect_record;
    unsigned int base_reg_val;
    unsigned char *registers;
     
    //point to the lase record in the frame buffer 
    if (record_fb==NULL) return;
    if (record_fb->head_record !=NULL)
    { 
        current_collect_record =record_fb->head_record;
        while (current_collect_record->next !=NULL)  
        { 
            current_collect_record = current_collect_record->next;
        } 
        current_collect_record->next = (collect_record *) malloc (sizeof (collect_record));
        current_collect_record=current_collect_record->next;
    } 
    else 
    { 
        record_fb->head_record = (collect_record *) malloc (sizeof (collect_record));
        current_collect_record=record_fb->head_record;
    } 
   
    if (current_action!=NULL)
    { 
       switch (current_action->type)
       { 
        case ACTION_COLLECT : 
            { 
                switch (current_action->action_data.ca.type)
                { 
                    case COLLECT_REGISTERS: 
                        { 
                            current_collect_record->collect_data= (char *)malloc (current_reg_type->register_bytes);
                            fetch_inferior_registers (-1, current_collect_record ->collect_data);
                            current_collect_record->collect_data_length=current_reg_type->register_bytes;
                            current_collect_record->ca=&(current_action->action_data.ca);
                            current_collect_record->next=NULL;
                        } 
                        break;
                    case COLLECT_MEMORY:  
                        { 
                              current_collect_record->collect_data= (char *)malloc(current_action->action_data.ca.description.mc.length);
                              //should be the content of basereg  
                              if (current_action->action_data.ca.description.mc.base_reg == -1)
                              { 
                                   base_reg_val=0;
                              } 
                              else 
                              { 
                                      registers = (unsigned char *)malloc(current_reg_type->register_bytes);

                                  fetch_inferior_registers (current_action->action_data.ca.description.mc.base_reg, registers);
                                  base_reg_val=registers[current_reg_type->register_byte (current_action->action_data.ca.description.mc.base_reg)];
                                  free (registers);
                                   
                              } 
                              current_collect_record->collect_data_length=sim_read (base_reg_val+current_action->action_data.ca.description.mc.offset, current_collect_record->collect_data, current_action->action_data.ca.description.mc.length);
                              current_collect_record->ca=&(current_action->action_data.ca);
                              current_collect_record->next=NULL;
                        } 
                        break;;
                    case COLLECT_EXPRESSION : ;
                    default : break;
                     
                } 
            } 
            break;
         
        case ACTION_WHILE :;
        default : break;
             
       } 
    }   
}


void do_action_list (unsigned int tp_id, action* actions, frame_buffer * fb)  
{
    frame_buffer *current_frame_buffer;
    action * current_action;
   
    current_frame_buffer =fb;
    current_action =actions;
    while (current_action !=NULL)
    { 
        switch (current_action->type)  
        { 
            case ACTION_COLLECT: 
                { 
                    do_action(tp_id,current_action,current_frame_buffer);
                    fprintf (stderr," tracepoint : %x, remaining pass : %x, action collect \n",skyeye_ice.tps[tp_id].number,skyeye_ice.tps[tp_id].remaining_pass);
                    current_action=current_action->sibling;
                } 
            break;
            case ACTION_WHILE: 
                { 
                    if (current_action->action_data.wa.remaining_steps !=0)
                    { 
                         set_tracepoint_status(tp_id, TRACEPOINT_STEPPING);
                         current_action->action_data.wa.remaining_steps--;
                         do_action_list(tp_id,current_action->child,current_frame_buffer);
                          
                         fprintf (stderr," tracepoint : %x, remaining pass : %x, action stepping \n",skyeye_ice.tps[tp_id].number,skyeye_ice.tps[tp_id].remaining_pass);
                        
                    } 
                    if (current_action->action_data.wa.remaining_steps ==0)
                    { 
                          set_tracepoint_status(tp_id, TRACEPOINT_ENABLED);
                          current_action->action_data.wa.remaining_steps=current_action->action_data.wa.step_count;
                          fprintf (stderr," tracepoint : %x, action stepping end \n",skyeye_ice.tps[tp_id].number);
                    } 
                    current_action=current_action->sibling;
                }  
            break;
        } 
    } 
}  

void handle_tracepoint(int tp_id)
{
    action * current_action;
    frame_buffer *current_frame_buffer;
   
    if (get_tracepoint_status(tp_id)==TRACEPOINT_STEPPING)
    { 
        //find the while stepping action 
        current_action=skyeye_ice.tps[tp_id].actions;
        while (current_action->type!=ACTION_WHILE)
        { 
            if (current_action->sibling !=NULL)
            {  
                current_action=current_action->sibling;
            }else 
            { 
                return;
            } 
        } 
        current_frame_buffer= add_frame_buffer();
        current_frame_buffer->tp_number=skyeye_ice.tps[tp_id].number;  
        //current action is a while action 
        do_action_list (tp_id,current_action,current_frame_buffer);
        return;       
    } 
    if (get_tracepoint_status(tp_id)==TRACEPOINT_ENABLED)
    {  
        if (skyeye_ice.tps[tp_id].pass_count!=0)
        { 
            if (skyeye_ice.tps[tp_id].remaining_pass!=0)
            { 
                //decrease the remaining_pass 
                skyeye_ice.tps[tp_id].remaining_pass--;
            } 
            else  
            { 
                //remaining_pass ==0, don't collect tracess 
                return;
            } 
        } 
        current_frame_buffer= add_frame_buffer();
        current_frame_buffer->tp_number=skyeye_ice.tps[tp_id].number;
        do_action_list (tp_id,skyeye_ice.tps[tp_id].actions,current_frame_buffer);
    } 
}

void clear_tracepoints(void)
{
    int i;

    skyeye_ice.num_tps=0;

    for (i=0;i<MAX_TRACEPOINTS;i++)
    { 
        if (skyeye_ice.tps[i].actions!=NULL)
            delete_action(skyeye_ice.tps[i].actions);
        skyeye_ice.tps[i].actions=NULL;
    } 
}



void init_tracepoints ()
{
    clear_tracepoints();
    skyeye_ice.tps_status=TRACE_STOPPED;
     
    clear_frame_buffers();

    skyeye_ice.selected_fb=NULL;
     
    clear_ro_regions();
     
    return;
}

void start_trace_recording ()
{
    skyeye_ice.tps_status=TRACE_STARTED;
}

void stop_trace_recording ()
{
    skyeye_ice.tps_status=TRACE_STOPPED;
}

void start_trace_focusing ()
{
    skyeye_ice.tps_status=TRACE_FOCUSING;     
}

void stop_trace_focusing ()
{
    skyeye_ice.tps_status=TRACE_STARTED;
    skyeye_ice.selected_fb=NULL;
}

trace_status get_trace_status()
{
    return(skyeye_ice.tps_status);
}

