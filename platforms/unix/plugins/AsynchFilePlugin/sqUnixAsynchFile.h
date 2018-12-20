/* private file data */

typedef struct
{
  int  fd;			/* descriptor */
  int  sema;			/* completion semaphore */
  struct {
    int   pos;			/* file position */
    int   status;		/* number of bytes transferred, or: */
#   define	Busy	-1	/* operation in progress */
#   define	Error	-2	/* operation aborted */
  }    rd, wr;			/* one each for read and write */
  struct FileBuf {
    char *bytes;		/* write buffer */
    int   capacity;		/* capacity */
    int   size;			/* contents size */
    int	  pos;			/* position */
  }    buf;
} FileRec, *FilePtr;


extern int sqUnixAsyncFileSessionID;

extern FilePtr asyncFileAttach(AsyncFile *f, int fd, int semaIndex);
