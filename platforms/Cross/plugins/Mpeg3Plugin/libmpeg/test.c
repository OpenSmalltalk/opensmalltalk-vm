/* Lex's test program.... */

#include <libmpeg3.h>
#include <stdio.h>


int main() 
{
     mpeg3_t *file;
     int width;
     int height;
     unsigned char buf[400][400] = { {0} };
     unsigned char * rowPtrs[400];
     int i;
     int iter;
     
     
     

     file = mpeg3_open("/home/lex/piper.closeup.mpg");
     if(file == NULL) {
	  printf("couldn't open file\n");
	  return 1;
     }

     width = mpeg3_video_width(file, 0);
     height = mpeg3_video_height(file, 0);
     printf("dimensions are: %d x %d\n", width, height);


     for(i=0; i<400; i++)
	  rowPtrs[i] = buf[i];


     printf("buf = ");
     for(i=0; i<8; i++)
	  printf(" %d", buf[0][i]);
     printf("\n");

     for(iter=0; iter<100; iter++) {
	  printf("iter = %d\n", iter);
	  
	  mpeg3_read_frame(file, rowPtrs,
			   0, 0, width, height,
			   width, height,
			   MPEG3_RGBA8888,
			   0);

	  printf("buf = ");
	  for(i=0; i<8; i++)
	       printf(" %d", buf[0][i]);
	  printf("\n");
     }
     

     return 0;
     
}

