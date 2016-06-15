/* Lex's test program.... */

#include <libmpeg3.h>
#include <stdio.h>


int main() 
{
     mpeg3_t *file;
     int width;
     int height;
     unsigned char buf[100000] = { 0 };
     int i;
     int iter;
     
     
     

     file = mpeg3_open("/home/lex/mp3/bach/lilfug.mp3");
     if(file == NULL) {
	  printf("couldn't open file\n");
	  return 1;
     }



     printf("buf = ");
     for(i=0; i<8; i++)
	  printf(" %d", buf[i]);
     printf("\n");

     for(iter=0; iter<100; iter++) {
	  printf("iter = %d\n", iter);

	  mpeg3_read_audio(file, NULL,
			   (short *) buf,
			   1,
			   1000,
			   0);

	  printf("buf = ");
	  for(i=0; i<8; i++)
	       printf(" %d", buf[i]);
	  printf("\n");
     }
     

     return 0;
     
}

