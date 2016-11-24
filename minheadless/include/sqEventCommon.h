#ifndef SQ_EVENT_COMMON_H
#define SQ_EVENT_COMMON_H

#include "sqQueue.h"
#include "sq.h"

#define SQ_EVENT_QUEUE_SIZE 64

typedef union sqEventUnion
{
    sqIntptr_t type;
    sqInputEvent input;
    sqKeyboardEvent key;
    sqMouseEvent mouse;
    sqWindowEvent window;
    sqDragDropFilesEvent dnd;
    sqMenuEvent menu;
    sqComplexEvent complex;
}sqEventUnion;

typedef struct sqEventQueue
{
    sqCircularQueueInfo info;
    sqEventUnion elements[SQ_EVENT_QUEUE_SIZE];
} sqEventQueue;

#define sqEventQueueIsEmpty(queue) sqQueueIsEmpty(queue, SQ_EVENT_QUEUE_SIZE)
#define sqEventQueueIsFull(queue) sqQueueIsFull(queue, SQ_EVENT_QUEUE_SIZE)
#define sqEventQueuePush(queue, value) sqQueuePush(queue, SQ_EVENT_QUEUE_SIZE, value)
#define sqEventQueuePopInto(queue, result) sqQueuePopInto(queue, SQ_EVENT_QUEUE_SIZE, result)

void ioSignalInputEvent(void);

#endif /* SQ_EVENT_COMMON_H */
