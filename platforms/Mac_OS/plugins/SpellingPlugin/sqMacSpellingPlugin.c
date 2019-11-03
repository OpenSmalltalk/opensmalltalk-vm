/*
 *  sqMacSpellingPlugin.c
 *  SqueakSpelling
 *
 *  Created by John M McIntosh on 14/06/05.
 *  Copyright 2005 Corporate Smalltalk Consulting Ltd. All rights reserved. Licenced under the Squeak-L
 *
 */

#include "sqMacSpellingPlugin.h"

/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#if __BIG_ENDIAN__
#define kCFStringEncodingUTF16Squeak kCFStringEncodingUnicode
#else
#define kCFStringEncodingUTF16Squeak kCFStringEncodingUTF16BE

#endif

extern struct VirtualMachine *interpreterProxy;
CFBundleRef			gSpellingBundle=0;		//	"SpellCheck.bundle" reference 

//	Function pointer prototypes to the Mach-O Cocoa wrappers
typedef CFRange		(*CheckSpellingOfStringWithOptionsProc)( CFStringRef, int, CFStringRef,Boolean, int, int );
typedef CFRange		(*CheckSpellingOfStringProc)( CFStringRef, int );
typedef void		(*IgnoreWordProc)( CFStringRef, int );
typedef CFArrayRef	(*GuessesForWordProc)( CFStringRef );
typedef void 		(*InitializeCocoaProc)();
typedef void		(*CloseSpellDocumentWithTagProc)( int );
typedef int 		(*UniqueSpellDocumentTagProc)();
typedef CFStringRef	(*LanguageProc)();
typedef Boolean		(*SetLanguageProc)(CFStringRef);
typedef CFArrayRef	(*IgnoredWordsInSpellDocumentWithTagProc)( int );
typedef void		(*SetIgnoredWordsProc)(CFArrayRef, int );

CheckSpellingOfStringProc	CocoaCheckSpellingOfString;
IgnoreWordProc				CocoaIgnoreWord;
GuessesForWordProc			CocoaGuessesForWord;
InitializeCocoaProc			CocoaInitializeCocoa;
CloseSpellDocumentWithTagProc	CocoaCloseSpellDocumentWithTag;
UniqueSpellDocumentTagProc		CocoaUniqueSpellDocumentTag;
LanguageProc				CocoaLanguage;
SetLanguageProc				CocoaSetLanguage;
IgnoredWordsInSpellDocumentWithTagProc				CocoaIgnoredWordsInSpellDocumentWithTag;
SetIgnoredWordsProc				CocoaSetIgnoredWords;
CheckSpellingOfStringWithOptionsProc CocoaCheckSpellingOfStringWithOptions;

void	LoadPrivateFrameworkBundle( CFStringRef framework, CFBundleRef *bundlePtr, CFStringRef pluginName );

int		gDocumentTag=0;

int		sqSpellingInitialize(void) {
	if (gSpellingBundle != NULL) 
		return 1;
   LoadPrivateFrameworkBundle( CFSTR("SpellCheck.bundle"), &gSpellingBundle,CFSTR("org.squeak.SpellingPlugin") );
    if ( gSpellingBundle == NULL ) 
		return 0;
	
	CocoaInitializeCocoa	= (InitializeCocoaProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("InitializeCocoa") );
	if ( CocoaInitializeCocoa != NULL ) 
			CocoaInitializeCocoa();
	CocoaCheckSpellingOfString					= (CheckSpellingOfStringProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("CheckSpellingOfString") );
	CocoaGuessesForWord							= (GuessesForWordProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("GuessesForWord") );
	CocoaIgnoreWord								= (IgnoreWordProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("IgnoreWord") );
	CocoaCloseSpellDocumentWithTag				= (CloseSpellDocumentWithTagProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("CloseSpellDocumentWithTag") );
	CocoaUniqueSpellDocumentTag					= (UniqueSpellDocumentTagProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("UniqueSpellDocumentTag") );
	CocoaLanguage								= (LanguageProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("language") );
	CocoaSetLanguage							= (SetLanguageProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("setLanguage") );
	CocoaIgnoredWordsInSpellDocumentWithTag		= (IgnoredWordsInSpellDocumentWithTagProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("CopyIgnoredWordsInSpellDocumentWithTag") );
	CocoaSetIgnoredWords						= (SetIgnoredWordsProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("SetIgnoredWords") );
	CocoaCheckSpellingOfStringWithOptions		= (CheckSpellingOfStringWithOptionsProc) CFBundleGetFunctionPointerForName( gSpellingBundle, CFSTR("CheckSpellingOfStringWithOptions") );

	gDocumentTag = CocoaUniqueSpellDocumentTag();
	return 1;
}

void	sqSpellingShutdown(void) {
	if (gDocumentTag == 0) 
		return;
	if (gSpellingBundle == 0) 
		return;
		
	CocoaCloseSpellDocumentWithTag(gDocumentTag);
}


CFStringRef		gLanguage=NULL;
void	sqSpellingCheckSpellingstartingAtlengthresults(char * data,int startLocation,int length, int *results)
{
	CFRange	range;
	CFStringRef		stringToSpellCheck;

	if (gLanguage == NULL) {
		int ignore;
		ignore = sqSpellingGetLanguageLength();
	}
		
	stringToSpellCheck = CFStringCreateWithBytes(kCFAllocatorDefault, data, length*2, kCFStringEncodingUTF16Squeak, false);

	range = CocoaCheckSpellingOfStringWithOptions( stringToSpellCheck, startLocation, gLanguage, 0, gDocumentTag,0);
	results[0] = (range.location+1);
	results[1] = (range.length);
	CFRelease(stringToSpellCheck);
}

int		sqSpellingGetLanguageLength(void) {
	gLanguage = CocoaLanguage();
	return CFStringGetLength(gLanguage);	
}

void	sqSpellingGetLanguageInto(char* string) {
	CFRange range = { 0, CFStringGetLength(gLanguage)};
	CFIndex usedBufLen,actual;
	
	actual = CFStringGetBytes(gLanguage, range, kCFStringEncodingMacRoman, 0, false,
					string,CFStringGetLength(gLanguage), &usedBufLen);
}

int		sqSpellingGetUniqueSpellingTag(void) {
	return gDocumentTag;
}

void	sqSpellingSetLanguagelength(char *string,int length) {
	CFStringRef lang;
	
	lang = CFStringCreateWithBytes(kCFAllocatorDefault, string, length, kCFStringEncodingMacRoman, false);
	CocoaSetLanguage(lang);
	CFRelease(lang);
}

CFArrayRef	guessArray=NULL;
 
int		sqSpellingGuessForWordListLengthwithTaglength(char *data, int tag,int size) {
   CFIndex				count;
   CFStringRef			word;
   
	if ( guessArray != NULL ) 
			{ CFRelease( (void*)guessArray ); guessArray = NULL; }
			
	word = CFStringCreateWithBytes(kCFAllocatorDefault, data, size*2, kCFStringEncodingUTF16Squeak, false);
	guessArray	= CocoaGuessesForWord( word );
	count	= CFArrayGetCount( guessArray );
	if (count == 0)
		{ 
		CFRelease( (void*)guessArray ); 
		guessArray = NULL; }
		
	CFRelease(word);
	return count;
}

int		sqSpellingGuessForWordwithTagLengthat(int aTag, int indexs){
	if ( guessArray == NULL ) 
			return 0;
	CFStringRef	guess = CFArrayGetValueAtIndex( guessArray, indexs );
	return CFStringGetLength(guess);
}

void	sqSpellingGuessForWordwithTagatinto(int aTag,int index, char *data) {
	if ( guessArray == NULL ) 
			return;
	{
		CFStringRef	guess = CFArrayGetValueAtIndex( guessArray, index );
		CFRange range = { 0, CFStringGetLength(guess)};
		CFIndex usedBufLen,actual;

		actual = CFStringGetBytes(guess, range, kCFStringEncodingUTF16Squeak, 0, false,
					data,CFStringGetLength(guess)*2, &usedBufLen);
					
		if (index+1 == CFArrayGetCount( guessArray )) {
			CFRelease(guessArray);
			guessArray = NULL;
		}
	}
}

CFArrayRef	ignoredWordsArray=NULL;

int		sqSpellingGetIgnoredWordsListLengthWithTag(int aTag) {
	CFIndex				count;
	if ( ignoredWordsArray != NULL ) 
			{ CFRelease( (void*)ignoredWordsArray ); ignoredWordsArray = NULL; }
			
	ignoredWordsArray = CocoaIgnoredWordsInSpellDocumentWithTag(aTag);
	if (ignoredWordsArray == NULL) 
		return 0;
	count	= CFArrayGetCount( ignoredWordsArray );
	return count;
}

int		sqSpellingGetIgnoredWordLengthWithTagat(int aTag, int anIndex){
	if ( ignoredWordsArray == NULL ) 
		return 0;
		
	CFStringRef	guess = CFArrayGetValueAtIndex( ignoredWordsArray, anIndex );
	return CFStringGetLength(guess);
}

void	sqSpellingGetIgnoredWordWithTagatinto(int aTag, int anIndex, char *data) {
	if ( ignoredWordsArray == NULL ) 
		return;
	{
	CFStringRef	ignoreWord = CFArrayGetValueAtIndex( ignoredWordsArray, anIndex );
	CFRange range = { 0, CFStringGetLength(ignoreWord)};
	CFIndex usedBufLen,actual;

	actual = CFStringGetBytes(ignoreWord, range, kCFStringEncodingUTF16Squeak, 0, false,
					data,CFStringGetLength(ignoreWord)*2, &usedBufLen);
	}
}

CFMutableArrayRef	newIgnoredWordsArray=NULL;
CFIndex				newIgnoredWordsArrayLength=0;

void	sqSpellingSetIgnoredWordsListLengthwithTag(int length, int aTag) {
	if ( newIgnoredWordsArray != NULL ) 
			{ CFRelease( (void*)newIgnoredWordsArray ); newIgnoredWordsArray = NULL; }

	newIgnoredWordsArrayLength = length;
	newIgnoredWordsArray = CFArrayCreateMutable(kCFAllocatorDefault, newIgnoredWordsArrayLength, NULL);
	if (newIgnoredWordsArrayLength == 0) {
		CocoaSetIgnoredWords(newIgnoredWordsArray,aTag);
		CFRelease(newIgnoredWordsArray);
		newIgnoredWordsArray = NULL;
	}
		
}

void	sqSpellingSetIgnoredWordwithTagatlength(char *data,int aTag, int anIndex, int length) {
	CFStringRef word;
	if (newIgnoredWordsArray == NULL) 
			return;
	word = CFStringCreateWithBytes(kCFAllocatorDefault, data, length*2, kCFStringEncodingUTF16Squeak, false);
	CFArraySetValueAtIndex (newIgnoredWordsArray,anIndex,word);
	if ((anIndex+1) == newIgnoredWordsArrayLength) {
		CocoaSetIgnoredWords(newIgnoredWordsArray,aTag);
		CFRelease(newIgnoredWordsArray);
		newIgnoredWordsArray = NULL;
	}
}

void	sqSpellingSetNewIgnoredWordwithTaglength(char *data,int aTag, int length) {
	CFStringRef	word;
	word = CFStringCreateWithBytes(kCFAllocatorDefault, data, length*2, kCFStringEncodingUTF16Squeak, false);
	CocoaIgnoreWord(word,aTag);
	CFRelease(word);
}

//	Utility routine to load a bundle from the applications Frameworks folder.
//	i.e. : "SpellingChecker.app/Contents/Frameworks/SpellCheck.bundle"
void	LoadPrivateFrameworkBundle( CFStringRef framework, CFBundleRef *bundlePtr, CFStringRef pluginIdentifier)
{
	CFURLRef	baseURL			= NULL;
	CFURLRef	bundleURL		= NULL;
	CFBundleRef	myAppsBundle	= NULL;
	
	if ( bundlePtr == NULL )	goto Bail;
	*bundlePtr = NULL;
	
	myAppsBundle	= CFBundleGetBundleWithIdentifier(pluginIdentifier);					//	Get our application's main bundle from Core Foundation
	if ( myAppsBundle == NULL )	goto Bail;
	
	baseURL	= CFBundleCopyPrivateFrameworksURL( myAppsBundle );
	if ( baseURL == NULL )	goto Bail;

	bundleURL = CFURLCreateCopyAppendingPathComponent( kCFAllocatorSystemDefault, baseURL, framework, false );
	if ( bundleURL == NULL )	goto Bail;

	*bundlePtr = CFBundleCreate( kCFAllocatorSystemDefault, bundleURL );
	if ( *bundlePtr == NULL )	goto Bail;

	if ( ! CFBundleLoadExecutable( *bundlePtr ) )
	{
		CFRelease( *bundlePtr );
		*bundlePtr	= NULL;
	}

Bail:															// Clean up.
	if ( bundleURL != NULL )	CFRelease( bundleURL );
	if ( baseURL != NULL )		CFRelease( baseURL );
}


