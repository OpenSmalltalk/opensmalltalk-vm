//
//  sqSqueakIPhoneApplication+attributes.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 6/19/08.
/*
Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
 and its contributors", in the same place and form as other third-party acknowledgments. 
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
 such third-party acknowledgments.
 */

//

#import "sqSqueakIPhoneApplication+attributes.h"
#import "sqSqueakMainApplication+attributes.h"
#import "sqSqueakMainApplication+vmAndImagePath.h"

extern struct VirtualMachine* interpreterProxy;

@implementation sqSqueakIPhoneApplication (attributes) 

- (const char *) getAttribute:(sqInt)indexNumber {
	//indexNumber is a postive/negative number
	
	switch (indexNumber) {
		case 1001: /* OS type: "unix", "win32", "mac", ... */
			return "iPhone";
			
		case 1002: /* OS name: "solaris2.5" on unix, "win95" on win32, ... */
			return "iPhone";
			
		case 1003: /* processor architecture: "68k", "x86", "PowerPC", ...  */
			return "iPhone";
			
		case 1006: /* vm build string */
			return "iPhone 2.2.4b1 20-Mar-10 >432619D7-FA70-4449-BEDF-68A74B3E4EF5<";
/*			return "iPhone 2.2.3b2 05-Mar-10 >9E99B1C2-0B6B-4944-8B6F-74030D14F3C6<";
			return "iPhone 2.2.2b1 17-Feb-10 >18862A37-A8AD-411D-945B-95AE2596AD89<";
			return "iPhone 2.1.1b1 06-Jan-10 >3487508B-770D-4F8D-B9FF-75B2A5657D42<";
			return "iPhone 2.1.0b1 05-Jan-10 >E33C3EE9-3038-4F83-8BE9-C6BE0C00E5B1<";
			return "iPhone 2.0.2b1 04-Jan-10 >1159F4AC-5B8A-4F56-B5E0-C792ACC9E094<";
			return "iPhone 2.0.1b1 02-Jan-10 >DE4B61C0-E36D-4F72-AE95-148A0664CC1A<";
			return "iPhone 2.0.0b1 04-Sep-09 >41158CDC-6D20-4C58-82AB-72B754757C01<";
			return "iPhone 1.0.9b2 04-Feb-09 >32DDCF17-D959-44ED-8DF8-10EE08D4DBFC<";
			return "iPhone 1.0.9b1 01-Feb-09 >9FD8E823-6E8B-4416-A9D6-8770E74F7BB1<";
			return "iPhone 1.0.7b2 03-Nov-08 >D60C0BDB-CA0F-45E1-822F-05A93C104712<";
			return "iPhone 1.0.7b1 27-Oct-08 >C2B2864E-B83D-4A6E-B8EF-CCD4AC64CFDC<";
 			return "iPhone 1.0.6b5 22-Oct-08 >BD6F8836-420A-479B-B400-70F73845A140<";
			return "iPhone 1.0.6b4 20-Oct-08 >E1936807-92EA-43AC-85A5-5BDA5755A606<";
			return "iPhone 1.0.6b3 10-Oct-08 >1EA1C0AA-BD8C-4BDD-94D7-19E021A32A66<";
			return "iPhone 1.0.6b2 10-Oct-08 >5BD0B1C3-5D5F-4E39-8EB4-2A6B75D969B0<";
			return "iPhone 1.0.6b1 09-Oct-08 >BBBBD9F3-64F7-4C86-8416-021732AAA9CB<";
			return "iPhone 1.0.5b4 03-Oct-08 >B35DA17D-2A1E-4DB6-9A3B-FEA51C5E8BEB<";
			return "iPhone 1.0.5b3 02-Oct-08 >2C04C0A4-5A5E-494E-BD49-2958E5AFA17D<";
			return "iPhone 1.0.5b1 21-Sep-08 >FF17E074-9A2F-4538-9433-BDDB87F97AD5<";
			return "iPhone 1.0.4b1 16-Sep-08 >B0574F6D-48DD-48CD-BE9F-0D197DED1A8F<";
			return "iPhone 1.0.3b2 13-Sep-08 >EB1B4D70-E96B-4F43-B2BA-B2A470E4A265<";
			return "iPhone 1.0.3b1 03-Sep-08 >721B48ED-CD8C-43A1-BE69-09FC9131E573<";
			return "iPhone 1.0.1b1 18-May-08 >1B1BAAE0-F4CA-4192-B3E5-4FE51E5BB820<";
			return "iPhone 1.0.2b1 02-Sep-08 >08F8D709-6867-4272-B18C-DBA704CB3C62<";
*/			
		case 1007: { /* vm build string also info.plist */
#if STACKVM
			extern char *__interpBuildInfo;
			return __interpBuildInfo;
#endif
			break;
		}
		case 1008: { /* vm build string also info.plist */
# if COGVM
			extern char *__cogitBuildInfo;
			return __cogitBuildInfo;
#endif
			break;
		}
		default: 
			break;
	}

	return (char *) [super getAttribute: indexNumber];
}
@end
