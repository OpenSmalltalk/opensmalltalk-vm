/* SqViewClut.h created by marcel on Sat 23-Dec-2000 */

#import "sqSqueakOSXNSView.h"
@class sqSqueakOSXNSView;

@interface sqSqueakOSXNSView(Clut)
	
-(void)initializeSqueakColorMap;
-(void)setColorEntry:(int)i red:(int)r green:(int)g blue:(int)b;
@end
