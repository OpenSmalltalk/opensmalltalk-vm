/* SqViewClut.m created by marcel on Sat 23-Dec-2000 */

#import "sqSqueakOSXOpenGLView.h"

@implementation sqSqueakOSXOpenGLView(Clut)
	
	-(void)initializeSqueakColorMap
	{
		colorMap32=(unsigned int*)malloc(sizeof(unsigned int)*256);
				
#define SetColorEntry(i,r,g,b)	[self setColorEntry:i red:r green:g blue:b]
		
		/* 1-bit colors (monochrome) */
		SetColorEntry(0, 65535, 65535, 65535);    /* white or transparent */
		SetColorEntry(1,     0,     0,     0);    /* black */
		
		/* additional colors for 2-bit color */
		SetColorEntry(2, 65535, 65535, 65535);    /* opaque white */
		SetColorEntry(3, 32768, 32768, 32768);    /* 1/2 gray */
		/* additional colors for 4-bit color */
		SetColorEntry( 4, 65535,     0,     0);   /* red */
		SetColorEntry( 5,     0, 65535,     0);   /* green */
		SetColorEntry( 6,     0,     0, 65535);   /* blue */
		SetColorEntry( 7,     0, 65535, 65535);   /* cyan */
		SetColorEntry( 8, 65535, 65535,     0);   /* yellow */
		SetColorEntry( 9, 65535,     0, 65535);   /* magenta */
        
		SetColorEntry(10,  8192,  8192,  8192);   /* 1/8 gray */
		SetColorEntry(11, 16384, 16384, 16384);   /* 2/8 gray */
		SetColorEntry(12, 24576, 24576, 24576);   /* 3/8 gray */
		SetColorEntry(13, 40959, 40959, 40959);   /* 5/8 gray */
		SetColorEntry(14, 49151, 49151, 49151);   /* 6/8 gray */
		SetColorEntry(15, 57343, 57343, 57343);   /* 7/8 gray */
		
		/* additional colors for 8-bit color */
		/* 24 more shades of gray (does not repeat 1/8th increments) */
		SetColorEntry(16,  2048,  2048,  2048);   /*  1/32 gray */
		SetColorEntry(17,  4096,  4096,  4096);   /*  2/32 gray */
		SetColorEntry(18,  6144,  6144,  6144);   /*  3/32 gray */
		SetColorEntry(19, 10240, 10240, 10240);   /*  5/32 gray */
		SetColorEntry(20, 12288, 12288, 12288);   /*  6/32 gray */
		SetColorEntry(21, 14336, 14336, 14336);   /*  7/32 gray */
		SetColorEntry(22, 18432, 18432, 18432);   /*  9/32 gray */
		SetColorEntry(23, 20480, 20480, 20480);   /* 10/32 gray */
		SetColorEntry(24, 22528, 22528, 22528);   /* 11/32 gray */
		SetColorEntry(25, 26624, 26624, 26624);   /* 13/32 gray */
		SetColorEntry(26, 28672, 28672, 28672);   /* 14/32 gray */
		SetColorEntry(27, 30720, 30720, 30720);   /* 15/32 gray */
		SetColorEntry(28, 34815, 34815, 34815);   /* 17/32 gray */
		SetColorEntry(29, 36863, 36863, 36863);   /* 18/32 gray */
		SetColorEntry(30, 38911, 38911, 38911);   /* 19/32 gray */
		SetColorEntry(31, 43007, 43007, 43007);   /* 21/32 gray */
		SetColorEntry(32, 45055, 45055, 45055);   /* 22/32 gray */
		SetColorEntry(33, 47103, 47103, 47103);   /* 23/32 gray */
		SetColorEntry(34, 51199, 51199, 51199);   /* 25/32 gray */
		SetColorEntry(35, 53247, 53247, 53247);   /* 26/32 gray */
		SetColorEntry(36, 55295, 55295, 55295);   /* 27/32 gray */
		SetColorEntry(37, 59391, 59391, 59391);   /* 29/32 gray */
		SetColorEntry(38, 61439, 61439, 61439);   /* 30/32 gray */
		SetColorEntry(39, 63487, 63487, 63487);   /* 31/32 gray */
		
		/* The remainder of color table defines a color cube with six steps
			for each primary color. Note that the corners of this cube repeat
			previous colors, but simplifies the mapping between RGB colors and
			color map indices. This color cube spans indices 40 through 255.
		*/
		{
			int r,g,b;
		
			for(r=0;r<6;r++){
				for(g=0;g<6;g++){
					for(b=0;b<6;b++){
						int i=40+((36*r)+(6*b)+g);
						if(i>255){
							fprintf(stderr,"index out of range "
									"in color table compuation\n");
						}
						SetColorEntry(i,(r*65535)/5,(g*65535)/5,(b*65535)/5);
					}
				}
			}
		}
	}//initializeSqueakColorMap;


-(void)setColorEntry:(int)i red:(int)r green:(int)g blue:(int)b
{
     colorMap32[i]=NSSwapHostIntToBig((((r)&0xff00)<<16)|(((g)&0xff00)<<8)|((b)&0xff00)|0xff);
}


@end
