/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*           sqRPCLocale.c                                                */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */

/* define this to get lots of debug reports  */
//#define DEBUG

#include <string.h>
#include <locale.h>
#include "sq.h"
#include "oslib/territory.h"

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
	/* ought to be able to find proper code from locale or territroy call ? */
	strncpy(str, "GBR", 3);
}

/* write the 3 char string describing the language in use into string ptr.
 * ISO 639 is the relevant source here;
 * see http://www.w3.org/WAI/ER/IG/ert/iso639.html
 * for details */
void	sqLocGetLanguageInto(char * str) {
	strncpy(str, "ENG", 3);
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
	strncpy(str, localeTable->currency_symbol, strlen(localeTable->currency_symbol));
}


/***************** Numbers and measurements **************/

/* return true if the metric measurements system is to be used, false otherwise
 * (USA is about it) */
sqInt	sqLocMeasurementMetric(void) {
	/* I really don't care too much if it's wrong in USA */
	return true;
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
char * tzName;
int tzOffset;
	xterritory_read_current_time_zone( &tzName, &tzOffset);
	return (tzOffset / 6000);
}

/* return true if DST is in use, false otherwise */
sqInt	sqLocDaylightSavings(void) {
struct tm * timeBlock;
time_t theTime;
	theTime = time((time_t)NULL);
	timeBlock = localtime(&theTime);
	return timeBlock->tm_isdst;
}

static char longDateFormat[] = "dddd dd mmmm yy";
/* return the size in chars of the long date format string */
sqInt	sqLocLongDateFormatSize(void) {
	return strlen(longDateFormat);
}
/*Write the string describing the long date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetLongDateFormatInto(char * str) {
	strncpy(str, longDateFormat, strlen(longDateFormat) );
}

static char shortDateFormat[] = "dd/mm/yy";
/* return the size in chars of the short date format string */
sqInt	sqLocShortDateFormatSize(void) {
	return strlen(shortDateFormat);
}
/*Write the string describing the short date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetShortDateFormatInto(char * str) {
	strncpy(str, shortDateFormat, strlen(shortDateFormat));
}

static char timeFormat[] = "h:m:s";
/* return the size in chars of the time format string */
sqInt	sqLocTimeFormatSize(void) {
	return strlen(timeFormat);
}
/* write the string describing the time formatting into string ptr.
 * Format is made up of
 * 		h hour (h 12, H 24), m minute, s seconds, x (am/pm String)
 * 		double symbol is null padded, single not padded (h=6, hh=06)  */
void	sqLocGetTimeFormatInto(char * str) {
	strncpy(str, timeFormat, strlen(timeFormat));
}
