/* sqaio -- asynchronous I/O support */


#ifndef SQAIO_H
#define SQAIO_H


/* a handler for asynchronous IO */
typedef void (*AioHandler)(void *data, int readFlag, int writeFlag, int exceptionFlag) ;


/* events a handler can be woken on */
#define AIO_EX	(1<<0)    /* always watched for, actually */
#define AIO_RD	(1<<1)
#define AIO_WR	(1<<2)
#define AIO_RW	(AIO_RD | AIO_WR)



/* register a handler for events on a particular descriptor.  flags
   specifies which events should be watched for; 0 will disable
   watching this descriptor. */
void aioHandle(int fd, AioHandler handlerFn, void *data, int flags);


/* stop watching a particular descriptor */
void aioStopHandling(int fd);




/* check all registered descriptors and call handlers as necessary.
   If no activity is immediately present, wait up to 'waitTime'
   microseconds */
void aioPoll(int waitMicros);



/* initialize the AIO module.  This function should be called before
   any other functions in the module are called */
void aioInitialize(void);

#endif /* SQAIO_H */
