/* SqueakObjcBridge.m created by marcel on Sat 05-Dec-1998 */

#import "sqVirtualMachine.h"
#import <Foundation/Foundation.h>
//#import <AppKit/AppKit.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

static NSAutoreleasePool *pool;
static char *moduleName = "ObjectiveCPlugin";

/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void)
{
    return moduleName;
}

/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter)
{
    int ok;

    if (anInterpreter->majorVersion() != VM_PROXY_MAJOR) {
        return 0;
    }
    ok = anInterpreter->minorVersion() >= VM_PROXY_MINOR;
    return ok;
}

EXPORT(int) initialiseModule(void)
{
    pool = [[NSAutoreleasePool alloc] init];
    return TRUE;
}

EXPORT(int) shutdownModule(void)
{
    [pool release];
    return TRUE;
}

#define longAt(i) (*((int *) (i)))

@interface NSString(SqueakValue)

-(NSString*)encodeAsSqueakValue;
-(NSRect)asNSRect;

@end


static VirtualMachine *vm()
{
    static VirtualMachine *vm=NULL;
    if ( vm == NULL ) {
        vm=sqGetInterpreterProxy();
    }
    return vm;
}

static int lengthOf( unsigned int stringOop )
{
    return vm()->byteSizeOf( stringOop );
}


static unsigned char *byteOf( unsigned int strinOop )
{
    return (unsigned char*)strinOop+4;
}

extern int stackPointer;
extern int specialObjectsOop;

EXPORT(int) printString(void)
{
    int name = longAt(stackPointer);
    int length = lengthOf(name);
    char *str = byteOf(name);

    if (length>4) {
        length=4;
    }
    NSLog(@"should print string (max 4 bytes of %d): '%.*s'",lengthOf(name),length,str);
    stackPointer-=4;
    return 0;
}

NSString *stringFromSqueakString( int squeakString )
{
    int length = vm()->stSizeOf(squeakString);
    char *str = byteOf(squeakString);
    return [NSString stringWithCString:str length:length];
}

NSData *dataFromSqueakString( int squeakString )
{
    int length = vm()->stSizeOf(squeakString);
    char *str = byteOf(squeakString);
    return [NSData dataWithBytes:str length:length];
}

NSArray *NSArrayFromSqueakArray( int squeakArray )
{
    return nil;
}

EXPORT(int) getObjcClass(void)
{
    int name = longAt(stackPointer);
    int length = lengthOf(name);
    char *str = byteOf(name);
    id className=[NSString stringWithCString:str length:length];
    Class class=NSClassFromString(className);
    unsigned int intClass =(unsigned int)class;
    
    // NSLog(@"got class: %x from string %@",intClass,className);
    if ( class ) {
        // NSLog(@"class is %@",class);
    }
    intClass>>=2;
    // NSLog(@"modifed class ptr: %x/%d from string %@",intClass,intClass,className);
    stackPointer-=4;
    
    vm()->pushInteger( intClass );		//
    return 0;	
}

#if 0 
static void writeObj( id stream, int obj )
{
    if ( vm()->isIntegerObject( obj ) ) {
        [stream printf:@" %d ",vm()->integerValueOf( obj )];
    } else     if ( vm()->isFloatObject( obj ) ) {
        double temp;
        temp=vm()->floatValueOf( obj );
        [stream printf:@" %g ",temp];
    } else     if ( vm()->fetchClassOf( obj ) == vm()->classString() ) {
        [stream appendBytes:vm()->firstIndexableField( obj ) length:vm()->stSizeOf(obj)];
    } else     if ( vm()->fetchClassOf( obj ) == vm()->classCharacter() ) {
        [stream appendBytes:vm()->firstIndexableField( obj ) length:vm()->stSizeOf(obj)];
    } else {
    }
}

NSData *dataFromArrayOrString( int obj )
{
    int class = vm()->fetchClassOf( obj );
    if ( class == vm()->classString() ) {
        return dataFromSqueakString( obj );
    } else if ( class == vm()->classArray() ) {
        int i,max;
        id stream = [MPWByteStream stream];
        for (i=1, max=vm()->stSizeOf(obj); i<=max;i++ ) {
            writeObj( stream, vm()->stObjectat( obj, i ));
        }
        return [stream target];
    } else {
        NSLog(@"invalid object class for conversion");
        return [NSData data];
    }
}

void drawPS()
{
    id pool = [[NSAutoreleasePool alloc] init];
    id data = dataFromArrayOrString( longAt(stackPointer) );

//    [(id)get_sq_view() drawPS:data];
    stackPointer-=4;
    vm()->pushInteger(0);
    [pool release];
}
#endif

void flushPS()
{
#if 0
    float x = vm()->floatValueOf(longAt( stackPointer - 12 ));
    float y = vm()->floatValueOf(longAt( stackPointer - 8 ));
    float width = vm()->floatValueOf(longAt( stackPointer - 4 ));
    float height = vm()->floatValueOf(longAt( stackPointer ));
    NSRect r = { { x,y   },  { width,height   }};
    [(id)get_sq_view() flushRect:r];
#endif
}

id	objPointerFromSqueakObjectId( int obj_id )
{
    return (id)(vm()->integerValueOf( obj_id )<<2);
}

int squeakObjIdFromObjPointer( id obj_id )
{
    return (((int)obj_id)>>2);
}

EXPORT(int) convertNSData(void)
{
    unsigned int obj_id = longAt(stackPointer);
    unsigned int result=0;
	NSLog(@"convert nsdata");
    if ( vm()->isIntegerObject( obj_id )) {
        id nsdata;
		int length;
		NSLog(@"we got a proxy");
        nsdata = objPointerFromSqueakObjectId( obj_id );
		length = [nsdata length];
		NSLog(@"length: %d",length);
		result = vm()->instantiateClassindexableSize(longAt(
((((char *) specialObjectsOop)) + 4) + (6 << 2)), length );
		[nsdata getBytes:(char*)result+4 length:length];
	}
    stackPointer-=8;
    vm()->push(result);
	return 0;
}

void getSqueakView()
{
    int viewId;
    stackPointer-=4;
//    viewId = squeakObjIdFromObjPointer( get_sq_view());
    NSLog(@"view id = %x",viewId);
    vm()->pushInteger( viewId );
}

EXPORT(int) forwardNoArgMsg(void)
{
    id selectorName=stringFromSqueakString( longAt(stackPointer) );
    SEL sel=NSSelectorFromString(selectorName);
    unsigned int obj_id = longAt(stackPointer-4);
    unsigned int result=0;
    if ( vm()->isIntegerObject( obj_id )) {
        id obj;
        obj = objPointerFromSqueakObjectId( obj_id );
        // NSLog(@"sending selector %@ to obj %x, squeak obj id = %x",NSStringFromSelector(sel),obj,obj_id);
        NS_DURING
            //NSLog(@"sending selector %@ to obj %@",NSStringFromSelector(sel),obj);
        if(![NSStringFromSelector(sel) isEqualToString: @"release"])
            result = (int)[obj performSelector:sel];
        else
            NSLog(@"Faking out a release, probably non-existant.\n");
        // NSLog(@"primitive returned:%d",result);
        NS_HANDLER
            NSLog(@"exception during message construction or forwarding %@",localException);
        NS_ENDHANDLER
    } else {
        NSLog(@"handle not a SmallInteger");
    }
    stackPointer-=8;
    vm()->push(result);
    return 0;
}

EXPORT(int) forwardByteArrayArgMsg(void)
{
    id selectorName=stringFromSqueakString( longAt(stackPointer-4) );
    id arglist=stringFromSqueakString( longAt(stackPointer) );
    SEL sel=NSSelectorFromString(selectorName);
    unsigned int obj_id = longAt(stackPointer-8);
    unsigned int result=0;
    stackPointer-=12;
    //NSLog(@"bridge sends msg to object %x",obj_id);
    if ( vm()->isIntegerObject( obj_id ) ) {
        id obj,signature;
        NSInvocation *invocation;
        int i;
        obj = objPointerFromSqueakObjectId( obj_id );
        // NSLog(@"sending selector %@ to obj %x of class %@",selectorName,obj,[obj class]);
        signature = [obj methodSignatureForSelector:sel];
        if ( signature && ( invocation = [NSInvocation invocationWithMethodSignature:signature] )) {
            id argListPList; // we can't type this since it could be NSString, NSData, NSArray or NSDictionary
            NS_DURING
                // NSLog(@"arg-list %@",arglist);
            argListPList = [arglist propertyList];
            // NSLog(@"argListPList %@, count = %d\n", argListPList, [argListPList count]);
            for (i = 0; i < [argListPList count]; i++) {
                id arg = [argListPList objectAtIndex: i];
                NSRect rectarg; float floatarg; double doublearg; char chararg;
                const char *argtype=[[invocation methodSignature] getArgumentTypeAtIndex:i+2];
                // NSLog(@"arg[%d] type = %s %@\n", i, argtype, arg);
                if ( argtype && arg ) {
                    void *argbuffer=&arg;
                    switch ( *argtype ) {
                        case '@':
                            if ( [arg isKindOfClass:[NSString class]] ) {
                                if ( [arg cString][0] =='_') {
                                    arg=(id)[[arg substringFromIndex:1] intValue];
                                } else if ( [arg cString][0] =='"' && [arg cStringLength]>=2) {
                                    NSRange range = { 1,[arg cStringLength]-1 };
                                    arg = [arg substringWithRange:range];
                                } else if([arg intValue] != 0) {
                                    arg = (id) ([arg intValue] << 2);
                                    // NSLog(@"We have an id, I do believe: %x\n", arg);
                                }
                            }
                            break;
                        case '#':
                            arg=NSClassFromString( arg );
                            break;
                        case ':':
                            arg=(id)NSSelectorFromString( arg );
                            break;
                        case 'i': case 'I': case 'l': case 'L':
                            arg=(id)[arg intValue];
                            break;
                        case 'c': case 'C':
                            chararg = (char) [arg intValue];
                            argbuffer = &chararg;
                            break;
                        case 'f':
                            floatarg = [arg floatValue];
                            argbuffer = &floatarg;
                            break;
                        case 'd':
                            doublearg = [arg floatValue];
                            argbuffer = &doublearg;
                            break;
                        default:
                            if ( !strcmp( argtype, "{?={?=ff}{?=ff}}") ) {
                                rectarg=[arg asNSRect];
                                argbuffer=&rectarg;
                            } else {
                                NSLog(@"unsupported argument type: '%s'",argtype);
                            }
                    }
                    [invocation setArgument:argbuffer atIndex:i+2];
                } else {

                }
            }
            [invocation setTarget:obj];
            [invocation setSelector:sel];
            [invocation invoke];
            {
                const char *argtype = [[invocation methodSignature] methodReturnType];
                // NSLog(@"return argtype = %s\n", argtype);

                if ( argtype ) {
                    if (*argtype != 'v' ) {
                        char resultbuf[200];
                        id	encoded=nil;
//                        char *secondaryResult;
//                        int resultLen = [[invocation methodSignature] methodReturnLength];
                        id temp=nil;
                        [invocation getReturnValue:resultbuf];
                        switch (  argtype[strlen(argtype)-1])
                        {
                            case 'i': case 'I': case 'l': case 'L': case 'c': case 'C':
                                result = ((*(int*)resultbuf)<<1) + 1;
                                break;
                            case '*':
                                temp = [NSString stringWithCString:*(char**)resultbuf];
                                break;
                            case '@':
                                temp = *(id*)resultbuf;
                                break;
                            case 'd':
                                temp = [NSNumber numberWithDouble:*(double*)resultbuf];
                                break;
                            case 'f':
                                temp = [NSNumber numberWithFloat:*(float*)resultbuf];
                                break;
                            default:
                                if ( !strcmp( argtype, "{?={?=ff}{?=ff}}") ) {
                                    NSRect r=*(NSRect*)resultbuf;
                                    encoded=temp=[@"R" stringByAppendingString:[NSString stringWithFormat:@"%g @ %g extent:%g @ %g",
                                        r.origin.x,r.origin.y,r.size.width,r.size.height]];
                                } else {
                                    NSLog(@"unsupported return type: '%s'",argtype);
                                }
                                
                        }
                        if ( temp ) {
                            if (!encoded) {
                                encoded = [temp encodeAsSqueakValue];
                            }
                            result = vm()->instantiateClassindexableSize( vm()->classString(), [encoded cStringLength] );
                            [encoded getCString:(char*)result+4 maxLength:[encoded cStringLength]];
                        }
                    }
                }
            }

            NS_HANDLER
                NSLog(@"exception during message construction or forwarding %@",localException);
            NS_ENDHANDLER
        } else {
            NSLog(@"couldn't get message signature or invocation");
        }
    } else {
        NSLog(@"address passed is not an integer!");
    }
    if ( result == 0 ) {
        result=1;	// SmallInteger 0
    }
    vm()->push(result);
    return 0;
}

void forwardDirectArgMsg( )
{
    id selectorName=stringFromSqueakString( longAt(stackPointer-4) );
    id arglist=NSArrayFromSqueakArray( longAt(stackPointer) );
    SEL sel=NSSelectorFromString(selectorName);
    unsigned int obj_id = longAt(stackPointer-8);
    unsigned int result=0;
    stackPointer-=12;
    if ( vm()->isIntegerObject( obj_id ) ) {
        id obj,signature,invocation;
        int i;
        obj = objPointerFromSqueakObjectId( obj_id );
        NSLog(@"sending selector %@ to obj %x of class %@",selectorName,obj,[obj class]);
        signature = [obj methodSignatureForSelector:sel];
        if ( signature && ( invocation = [NSInvocation invocationWithMethodSignature:signature] )) {
            NS_DURING
                // NSLog(@"arg-list %@",arglist);
            arglist = [arglist propertyList];
            for (i=0;i<[arglist count];i++) {
                id arg = [arglist objectAtIndex:i];
                NSRect rectarg; float floatarg; double doublearg;
                const char *argtype=[[invocation methodSignature] getArgumentTypeAtIndex:i+2];
                if ( argtype && arg  ) {
                    void *argbuffer=&arg;
                    switch ( *argtype ) {
                        case '@':
                            if ( [arg isKindOfClass:[NSString class]] ) {
                                if ( [arg cString][0] =='_') {
                                    arg=(id)[[arg substringFromIndex:1] intValue];
                                } else if ( [arg cString][0] =='"' && [arg cStringLength]>=2) {
                                    NSRange range = { 1,[arg cStringLength]-1 };
                                    arg = [arg substringWithRange:range];
                                }
                            }
                            break;
                        case '#':
                            arg=NSClassFromString( arg );
                            break;
                        case ':':
                            arg=(id)NSSelectorFromString( arg );
                            break;
                        case 'i': case 'I': case 'l': case 'L': case 'c': case 'C':
                            arg=(id)[arg intValue];
                            break;
                        case 'f':
                            floatarg = [arg floatValue];
                            argbuffer = &floatarg;
                            break;
                        case 'd':
                            doublearg = [arg floatValue];
                            argbuffer = &doublearg;
                            break;
                        default:
                            if ( !strcmp( argtype, "{?={?=ff}{?=ff}}") ) {
                                rectarg=[arg asNSRect];
                                argbuffer=&rectarg;
                            } else {
                                NSLog(@"unsupported argument type: '%s'",argtype);
                            }
                    }
                    [invocation setArgument:argbuffer atIndex:i+2];
                } else {

                }
            }
            [invocation setTarget:obj];
            [invocation setSelector:sel];
            [invocation invoke];
            {
                const char *argtype = [[invocation methodSignature] methodReturnType];
                if ( argtype ) {
                    if (*argtype != 'v' ) {
                        char resultbuf[200];
//                        char *secondaryResult;
//                        int resultLen = [[invocation methodSignature] methodReturnLength];
                        id temp=nil;
                        [invocation getReturnValue:resultbuf];
                        switch (  argtype[strlen(argtype)-1])
                        {
                            case 'i': case 'I': case 'l': case 'L':
                                result = ((*(int*)resultbuf)<<1) + 1;
                                break;
                            case '*':
                                temp = [NSString stringWithCString:*(char**)resultbuf];
                                break;
                            case '@':
                                temp = *(id*)resultbuf;
                                break;
                            case 'd':
                                temp = [NSNumber numberWithDouble:*(double*)resultbuf];
                                break;
                            case 'f':
                                temp = [NSNumber numberWithFloat:*(float*)resultbuf];
                                break;
                            default:
                                if ( !strcmp( argtype, "{?={?=ff}{?=ff}}") ) {
                                    temp=[@"R" stringByAppendingString:NSStringFromRect( *(NSRect*)resultbuf)];
                                } else {
                                    NSLog(@"unsupported return type: '%s'",argtype);
                                }
                                
                        }
                        if ( temp ) {
                            temp = [temp encodeAsSqueakValue];
                            result = vm()->instantiateClassindexableSize(longAt(((((char *) specialObjectsOop)) + 4) + (6 << 2)), [temp cStringLength] );
                            [temp getCString:(char*)result+4 maxLength:[temp cStringLength]];
                        }
                    }
                }
            }

            NS_HANDLER
                NSLog(@"exception during message construction or forwarding %@",localException);
            NS_ENDHANDLER
        } else {
            NSLog(@"couldn't get message signature or invocation");
        }
    } else {
        NSLog(@"passed obj-address is not an integer");
    }
    if ( result == 0 ) {
        result=1;	// SmallInteger 0
    }
    vm()->push(result);

}


@implementation NSObject(SqueakValue)

-(NSString*)encodeAsSqueakValue
{
    return [@"@" stringByAppendingString:[NSString stringWithFormat:@"%d",(int)(self)>>2]];
}

-next
{
    return [self nextObject];
}

@end

@implementation NSString(SqueakValue)

-(NSString*)encodeAsSqueakValue
{
    return [@"*" stringByAppendingString:self];
}

-(NSRect)asNSRect
{
    return NSRectFromString( self );
}

@end

@implementation NSNumber(SqueakValue)

-(NSString*)encodeAsSqueakValue
{
    return [@"N" stringByAppendingString:[self stringValue]];
}


@end

@implementation NSDictionary(SqueakValue)

-(NSRect)asNSRect
{
    NSRect result;
    result.origin.x = [[self objectForKey:@"x"] floatValue];
    result.origin.y = [[self objectForKey:@"x"] floatValue];
    result.size.width = [[self objectForKey:@"width"] floatValue];
    result.size.height = [[self objectForKey:@"height"] floatValue];
    return result;
}

@end


