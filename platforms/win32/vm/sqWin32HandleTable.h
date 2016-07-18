/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32HandleTable.h
*   CONTENT: Handle table
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: 
*   EMAIL:   andreas.raab@gmx.de
*
*   NOTES:
*     1) This is a simple handle table which can be used to verify whether
*     a HANDLE is genuine (e.g., created by a plugin) or not. Useful to
*     ensure that operations are only defined over handles that were
*     originally created by a plugin and wasn't fabricated in some other way.
*     Used (for example) by the file plugin to ensure integrity of file
*     operations. See sqWin32FilePrims.c for an example.
*     2) The HandleTable is used by merely including it and then defining
*         HandleTable *myTable;
*        to use it. Again, see sqWin32FilePrims.c for an example.
*****************************************************************************/

#ifndef SQ_WIN32_HANDLE_TABLE
#define SQ_WIN32_HANDLE_TABLE

typedef struct {
  int count;    /* number of elements in table */
  int size;     /* size of data array */
  HANDLE *data; /* actual data */
} HandleTable;

/* Private. Scan table for the slot containing either NULL or the item */
static int FindHandleInTable(HandleTable *table, HANDLE item) {
  int start, index;
  HANDLE element, *data = table->data;

  if(0 == table->size) return -1; /* so we don't explode below */
  /* Compute initial index */
  start  = ((usqIntptr_t)item) % table->size;
  /* search from (hash mod size) to end */
  for(index = start; index < table->size; index++) {
    element = data[index];
    if(NULL == element || item == element) return index;
  }
  /* search from 0 to where we started */
  for(index = 0; index < start; index++) {
    element = data[index];
    if(NULL == element || item == element) return index;
  }
  return -1; /* no match and no empty slot */
}

/* Private. Grow table to specified size. */
static void GrowTableToSize(HandleTable *table, int newSize) {
  HANDLE *oldData = table->data;
  int i, oldSize = table->size;
  /* grow table size */
  table->size = newSize;
  /* allocate new table array */
  table->data = (HANDLE*) calloc(newSize,sizeof(HANDLE));
  /* copy elements from old to new */
  for(i = 0; i < oldSize; i++) {
    HANDLE element = oldData[i];
    int index = FindHandleInTable(table, element);
    table->data[index] = element;
  }
  /* free old data */
  if(oldData) free(oldData);
}

/* Private. Fix a collision chain after removing an element */
static void FixCollisionsInTable(HandleTable *table, int index) {
  HANDLE element, *data = table->data;
  int newIndex, oldIndex = index;
  int length = table->size;
  while(1) {
    if(++oldIndex == length) oldIndex = 0;
    element = data[oldIndex];
    if(NULL == element) break; /* we're done here */
    newIndex = FindHandleInTable(table, element);
    if(newIndex != oldIndex) {
      HANDLE tmp = data[oldIndex];
      data[oldIndex] = data[newIndex];
      data[newIndex] = tmp;
    }
  }
}

/* Public. Add a handle to an existing table */
static void AddHandleToTable(HandleTable *table, HANDLE item) {
  int index;

  if(NULL == item) return; /* silently ignore NULL handles */
  index = FindHandleInTable(table, item);
  if(index == -1) { /* grow and retry */
    GrowTableToSize(table, table->size > 1 ? table->size*2-1 : 5);
    index = FindHandleInTable(table, item);
  }
  table->data[index] = item;
  table->count++;
}

/* Public. Remove a handle from some table */
static void RemoveHandleFromTable(HandleTable *table, HANDLE item) {
  int index;
  if(NULL == item) return; /* silently ignore NULL handles */
  index = FindHandleInTable(table, item);
  if(index == -1) return; /* not in table */
  if(NULL == table->data[index]) return; /* not in table */
  table->data[index] = NULL; /* clear entry */
  table->count--;
  FixCollisionsInTable(table, index); /* fix collision chain */
  /* Shrink table by half if 75% free but allow no less than 5 entries*/
  if(table->size > 5 && table->count*4 < table->size ) {
    GrowTableToSize(table, (table->size + 1) / 2);
  }
}

/* Public. Test if a handle is in this table */
static int  IsHandleInTable(HandleTable *table, HANDLE item) {
  int index;
  if(NULL == item) return 0; /* silently ignore NULL handles */
  index = FindHandleInTable(table, item);
  if(index == -1) return 0;
  return table->data[index] == item;
}

#endif /* SQ_WIN32_HANDLE_TABLE */
