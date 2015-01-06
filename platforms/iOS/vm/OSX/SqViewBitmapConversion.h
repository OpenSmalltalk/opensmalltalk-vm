/* SqViewBitmapConversion.h created by marcel on Fri 04-Dec-1998 */
//  CocoaSqueak

// John Notes: Waste not want not. 

/*
From: Marcel Weiher <marcel.weiher@gmail.com>
To: johnmci@smalltalkconsulting.com
In-Reply-To: <BEB4569D-C606-4FF4-9B1B-A95570E38B94@smalltalkconsulting.com>
Subject: Re: [squeak-dev] Squeak and the iPhone
References: <998FEB36-B9FC-427D-AA74-8A9F517432AB@smalltalkconsulting.com> <1f426d6e0806110542l4fa971bi50f429dbf9ba0809@mail.gmail.com> <FB804A64-E03C-4B68-B8F1-8FF135227F3B@gmail.com> <4D79AAD3-1CFC-431B-AB6B-7E230B0DC5A7@mac.com> <BEB4569D-C606-4FF4-9B1B-A95570E38B94@smalltalkconsulting.com>
Message-Id: <CCD6C9FE-483B-4A64-86B9-8D2647E54139@gmail.com>
Content-Type: text/plain; charset=US-ASCII; format=flowed; delsp=yes
Content-Transfer-Encoding: 7bit
Reply-To: Marcel Weiher <marcel.weiher@gmail.com>,
The general-purpose Squeak developers list <squeak-dev@lists.squeakfoundation.org>
Mime-Version: 1.0 (Apple Message framework v924)
Date: Wed, 18 Jun 2008 12:00:05 -0700
Cc: The general-purpose Squeak developers list <squeak-dev@lists.squeakfoundation.org>
X-Mailer: Apple Mail (2.924)
X-Brightmail-Tracker: AAAAAA==

The source code has been made available again at

http://www.metaobject.com/downloads/Squeak/
...
In the meantime, you have my express  
permission to use it under an MIT license.
 
*/



#import "sqSqueakOSXOpenGLView.h"
#import "BitMapConversionLogicFromX11.h"

@interface sqSqueakOSXOpenGLView(BitmapConversion)

-(CGImageRef)extractPixels_1_to_32:(void*)srcBits 
					 srcPixelWidth:(int)srcPixelWidth height: (int) height
							  left:(int)left right:(int)right
							   top:(int)top bottom:(int)bottom
						  colorMap: (unsigned int *) colorMap
						tempMemory: (void **) tempMemory;

-(CGImageRef)extractPixels_2_to_32:(void*)srcBits 
					 srcPixelWidth:(int)srcPixelWidth height: (int) height
							  left:(int)left right:(int)right
							   top:(int)top bottom:(int)bottom
						  colorMap: (unsigned int *) colorMap
						tempMemory: (void **) tempMemory;

-(CGImageRef)extractPixels_4_to_32:(void*)srcBits 
					 srcPixelWidth:(int)srcPixelWidth height: (int) height
							  left:(int)left right:(int)right
							   top:(int)top bottom:(int)bottom
						  colorMap: (unsigned int *) colorMap
						tempMemory: (void **) tempMemory;


-(CGImageRef)extractPixels_8_to_32:(void*)srcBits 
        srcPixelWidth:(int)srcPixelWidth height: (int) height
        left:(int)left right:(int)right
        top:(int)top bottom:(int)bottom
						  colorMap: (unsigned int *) colorMap
						tempMemory: (void **) tempMemory;


-(CGImageRef)extractPixels_16_to_32:(void*)srcBits
		srcPixelWidth:(int)srcPixelWidth height: (int) height
        left:(int)left right:(int)right
								top:(int)top bottom:(int)bottom
						 tempMemory: (void **) tempMemory;

-(CGImageRef)computeBitmapFromBitsIndex:(void*)srcBits
                width:(int)width height:(int)height depth:(int)depth
                left:(int)left right:(int)right
                top:(int)top bottom:(int)bottom
							 tempMemory: (void**) tempMemory;

@end
