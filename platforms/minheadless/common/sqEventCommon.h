/* sqEventCommon.h -- Common support functions used by legacy display API
 *
 *   Copyright (C) 2016 by Ronie Salgado
 *   All rights reserved.
 *
 *   This file is part of Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 * Author: roniesalg@gmail.com
 */

#ifndef SQ_EVENT_COMMON_H
#define SQ_EVENT_COMMON_H

#include "sqCircularQueue.h"
#include "sq.h"

#ifndef SQ_EVENT_QUEUE_SIZE
#define SQ_EVENT_QUEUE_SIZE 256
#endif

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
