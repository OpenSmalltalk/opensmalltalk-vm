/* 
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

#ifndef _LIST_H_
#define _LIST_H_

struct list_head
{
	struct list_head *next, *prev;
};

#define LIST_HEAD_INIT(name) { &(name), &(name) }

#define LIST_HEAD(name) \
	struct list_head name = LIST_HEAD_INIT(name)

#define INIT_LIST_HEAD(ptr) do { \
	(ptr)->next = (ptr); (ptr)->prev = (ptr); \
} while (0)

#define list_for_each_safe(pos, n, head) \
	for (pos = (head)->next, n = pos->next; pos != (head); \
		pos = n, n = pos->next)

#define list_entry(ptr, type, member) \
	((type *)((char *)(ptr)-(unsigned int)(&((type *)0)->member)))

static __inline__ void
__list_add (struct list_head *new,
	    struct list_head *prev, struct list_head *next)
{
	next->prev = new;
	new->next = next;
	new->prev = prev;
	prev->next = new;
}

static __inline__ void
list_add_tail (struct list_head *new, struct list_head *head)
{
	__list_add (new, head->prev, head);
}

static __inline__ void
__list_del (struct list_head *prev, struct list_head *next)
{
	next->prev = prev;
	prev->next = next;
}

static __inline__ void
list_del_init (struct list_head *entry)
{
	__list_del (entry->prev, entry->next);
	INIT_LIST_HEAD (entry);
}

static __inline__ int
list_empty (struct list_head *head)
{
	return head->next == head;
}

#endif //_LIST_H_
