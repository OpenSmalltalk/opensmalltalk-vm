/* sqUnixFBDevUtil.c -- sundries used in more than one place
 * 
 * Author: Ian Piumarta  <ian.piumarta@inria.fr>
 * 
 * Last edited: 2003-08-20 01:11:12 by piumarta on felina.inria.fr
 */


static int fdReadable(int fd, int usecs)
{
  fd_set fds;
  struct timeval tv;
  FD_ZERO(&fds);
  FD_SET(fd, &fds);
  tv.tv_sec=  usecs / 1000000;
  tv.tv_usec= usecs % 1000000;
  for (;;)
    {
      int err= select(fd + 1, &fds, 0, 0, &tv);
      if ((err < 0) && (errno == EINTR))
	continue;
      return (err > 0);
    }
}
