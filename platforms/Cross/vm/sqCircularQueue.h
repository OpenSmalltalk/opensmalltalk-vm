/* sqCircularQueue.c -- Generic circular queue data structure.
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

#ifndef _SQ_CIRCULAR_QUEUE_H_
#define _SQ_CIRCULAR_QUEUE_H_

/**
 * Generic circular queue data structure
 */
typedef struct sqCircularQueueInfo
{
    int readIndex;
    int writeIndex;
}sqCircularQueueInfo;

#define sqQueueIsEmpty(queue, queueSize) ((queue).info.readIndex == (queue).info.writeIndex)
#define sqQueueIsFull(queue, queueSize) ( (((queue).info.writeIndex + 1) & (queueSize - 1)) == (queue).info.readIndex)

#define sqQueueIncreaseWriteIndex(queue, queueSize) ((queue).info.writeIndex = (queue).info.writeIndex + 1 & (queueSize - 1))
#define sqQueueIncreaseReadIndex(queue, queueSize) ((queue).info.readIndex = (queue).info.readIndex + 1 & (queueSize - 1))

#define sqQueuePush(queue, queueSize, value) { \
    (queue).elements[(queue).info.writeIndex] = value; \
    sqQueueIncreaseWriteIndex(queue, queueSize); \
    if(sqQueueIsEmpty(queue, queueSize)) {\
        sqQueueIncreaseReadIndex(queue, queueSize); \
    } \
}

#define sqQueuePopInto(queue, queueSize, result) { \
    if(!sqQueueIsEmpty(queue, queueSize)) {\
        *(result) = (queue).elements[(queue).info.readIndex]; \
        sqQueueIncreaseReadIndex(queue, queueSize); \
    } \
}

#endif /*_SQ_CIRCULAR_QUEUE_H_ */
