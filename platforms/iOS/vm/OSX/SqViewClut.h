/* SqViewClut.h created by marcel on Sat 23-Dec-2000 */

#import "sqSqueakOSXOpenGLView.h"
@class sqSqueakOSXOpenGLView;

@interface sqSqueakOSXOpenGLView(Clut)
	
-(void)initializeSqueakColorMap;
-(void)setColorEntry:(int)i red:(int)r green:(int)g blue:(int)b;
@end
