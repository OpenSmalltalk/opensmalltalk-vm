#ifndef _SQ_QUEUE_H_
#define _SQ_QUEUE_H_

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

#endif /*_SQ_QUEUE_H_ */
