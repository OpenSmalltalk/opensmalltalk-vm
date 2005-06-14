/*
 *  sqMacLocaleCarbon.c
 *  SqueakLocale
 *
 *  Created by John M McIntosh on 6/9/05.
 *
 */

#include "sqMacLocaleCarbon.h"

/* Locale support functions */
char * thisLocale;
struct lconv * localeTable;

sqInt sqLocInitialize(void) {
	thisLocale = setlocale(LC_ALL,"");
	localeTable = localeconv();
	return true;
}
/************** Country and language ******************/

/* write the country code into the string ptr. ISO 3166 is the relevant source
 * here; see http://www.unicode.org/onlinedat/countries.html for details.
 * Using the 3 character Alpha-3 codes */
void	sqLocGetCountryInto(char * str) {
	CFLocaleRef		userLocaleRef;
	CFStringRef		stringRef;
	char			buffer[4];
	
	userLocaleRef = CFLocaleCopyCurrent();
	stringRef = CFLocaleGetValue(userLocaleRef, kCFLocaleCountryCode);
	CFStringGetCString(stringRef, buffer, 4,kCFStringEncodingMacRoman);	
	memcpy(str,buffer,3);
	CFRelease(userLocaleRef);
}

/* write the 3 char string describing the language in use into string ptr.
 * ISO 639 is the relevant source here;
 * see http://www.w3.org/WAI/ER/IG/ert/iso639.html
 * for details */
void	sqLocGetLanguageInto(char * str) {
	CFLocaleRef		userLocaleRef;
	CFStringRef		stringRef;
	char			buffer[4];
	
	userLocaleRef = CFLocaleCopyCurrent();
	stringRef = CFLocaleGetValue(userLocaleRef, kCFLocaleLanguageCode);
	CFStringGetCString(stringRef, buffer, 4,kCFStringEncodingMacRoman);	
	memcpy(str,buffer,3);
	CFRelease(userLocaleRef);
}

/***************** Currency ********************/

/* return 1 (true) if the currency symbol is to be placed in front of the
 *currency amount */
sqInt	sqLocCurrencyNotation(void) {
	return localeTable->p_cs_precedes;
}

/* return the length in chars of the curency symbol string */
sqInt	sqLocCurrencySymbolSize(void) {
	return strlen(localeTable->currency_symbol);
}
/* write the currency symbol into the string ptr */
void	sqLocGetCurrencySymbolInto(char * str) {
	strcpy(str, localeTable->currency_symbol);
}


/***************** Numbers and measurements **************/

/* return true if the metric measurements system is to be used, false otherwise
 * (USA is about it) */
sqInt	sqLocMeasurementMetric(void) {
	CFLocaleRef		userLocaleRef;
	CFStringRef		stringRef;
	char			buffer[7];
	
	userLocaleRef = CFLocaleCopyCurrent();
	stringRef = CFLocaleGetValue(userLocaleRef, kCFLocaleMeasurementSystem);
	CFStringGetCString(stringRef, buffer, 7,kCFStringEncodingMacRoman);	
	CFRelease(userLocaleRef);
	if (strcmp(buffer, "Metric") == 0)
		return 1;
	else
		return 0;
}

/* write the 1 char used for digit grouping into string ptr.
 * Usually this is . or ,  as in 1,000,000 */
void	sqLocGetDigitGroupingSymbolInto(char * str) {
	strncpy(str, localeTable->thousands_sep, 1);
}
/* write the 1 char used for decimal separation into string ptr.
 * Usually this is . or , */
void	sqLocGetDecimalSymbolInto(char * str) {
	strncpy(str, localeTable->decimal_point, 1);
}


/****************** time and date *********************/

sqInt	sqLocGetVMOffsetToUTC(void) {
	/* return 0 for now */
	return 0;
}

sqInt	sqLocGetTimezoneOffset(void) {
	CFTimeZoneRef zoneRef = CFTimeZoneCopySystem ();
	CFAbsoluteTime  timeIs = CFAbsoluteTimeGetCurrent();
	CFTimeInterval interval;
	
	interval = CFTimeZoneGetSecondsFromGMT (zoneRef,timeIs);
	CFRelease(zoneRef);
	return ((sqInt) interval)/60;
}

/* return true if DST is in use, false otherwise */
sqInt	sqLocDaylightSavings(void) {
struct tm * timeBlock;
time_t theTime;
	theTime = time((time_t)NULL);
	timeBlock = localtime(&theTime);
	return timeBlock->tm_isdst;
}

void dateFormatIs(char *buffer,CFDateFormatterStyle type ) {
	CFDateFormatterRef longFormatter = CFDateFormatterCreate(NULL, NULL, type, type);
	CFStringRef longStrRef = CFDateFormatterGetFormat(longFormatter);
	CFStringGetCString(longStrRef, buffer, 255,kCFStringEncodingMacRoman);	
	CFRelease(longFormatter);
}
/* return the size in chars of the long date format string */
sqInt	sqLocLongDateFormatSize(void) {
	char buffer[256];
	dateFormatIs(buffer,kCFDateFormatterLongStyle);

	return strlen(buffer);
}
/*Write the string describing the long date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetLongDateFormatInto(char * str) {
	char buffer[256];
	dateFormatIs(buffer,kCFDateFormatterLongStyle);
	memcpy(str, buffer,strlen(buffer));
}

/* return the size in chars of the short date format string */
sqInt	sqLocShortDateFormatSize(void) {
	char buffer[256];
	dateFormatIs(buffer,kCFDateFormatterShortStyle);

	return strlen(buffer);
}
/*Write the string describing the short date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetShortDateFormatInto(char * str) {
	char buffer[256];
	dateFormatIs(buffer,kCFDateFormatterShortStyle);
	memcpy(str, buffer,strlen(buffer));
}

/* return the size in chars of the time format string */
sqInt	sqLocTimeFormatSize(void) {
	char buffer[256];
	dateFormatIs(buffer,kCFDateFormatterLongStyle);

	return strlen(buffer);
}
/* write the string describing the time formatting into string ptr.
 * Format is made up of
 * 		h hour (h 12, H 24), m minute, s seconds, x (am/pm String)
 * 		double symbol is null padded, single not padded (h=6, hh=06)  */
void	sqLocGetTimeFormatInto(char * str) {
	char buffer[256]; 
	dateFormatIs(buffer,kCFDateFormatterLongStyle);
	memcpy(str, buffer,strlen(buffer));
}
