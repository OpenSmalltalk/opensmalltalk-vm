/****************************************************************************
*   PROJECT: Squeak port for Win32
*   FILE:    sqWin32LocalePlugin.c
*   CONTENT: locale support
*
*   AUTHORS: Andreas Raab (ar) , Bernd Eckardt (be)
*   ADDRESS: Magdeburg, Germany
*   EMAIL:   andreas.raab@gmx.de, bernd.eckardt@impara.de
*****************************************************************************/

#include <windows.h>
#include <winnls.h>
#include "sq.h"
#include "LocalePlugin.h"


/* extra definitions for older include files */
#ifndef LOCALE_SISO3166CTRYNAME
#define LOCALE_SISO3166CTRYNAME 90
#endif
#ifndef LOCALE_SISO639LANGNAME
#define LOCALE_SISO639LANGNAME 89
#endif

/* Locale support functions */
sqInt sqLocInitialize(void) {
	return true;
}

/************** Country and language ******************/

/* write the country code into the string ptr. ISO 3166 is the relevant source
 * here; see http://www.unicode.org/onlinedat/countries.html for details.
 * Using the 3 character Alpha-3 codes */
void	sqLocGetCountryInto(char * str) {

	char currString[6];
	int length;
	length = GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SISO3166CTRYNAME,currString, 6);
	strncpy(str, currString, length-1);

}

/* write the 3 char string describing the language in use into string ptr.
 * ISO 639 is the relevant source here;
 * see http://www.w3.org/WAI/ER/IG/ert/iso639.html
 * for details */
void	sqLocGetLanguageInto(char * str) {

	char currString[6];
	int length;
	length = GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SISO639LANGNAME,currString, 6);
	strncpy(str, currString, length-1);
}

/***************** Currency ********************/

/* return 1 (true) if the currency symbol is to be placed in front of the
 *currency amount */
sqInt	sqLocCurrencyNotation(void) {
	DWORD icurrency;
	if (GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_ICURRENCY | LOCALE_RETURN_NUMBER,(char *)&icurrency, sizeof(icurrency)/sizeof(TCHAR)) != 0){
		return((icurrency % 2) == 0);
	}
	return 0;
}

/* return the length in chars of the curency symbol string */
sqInt	sqLocCurrencySymbolSize(void) {
	char currString[6];
	return GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SCURRENCY,currString, 6)-1;
}

/* write the currency symbol into the string ptr */
void	sqLocGetCurrencySymbolInto(char * str) {
	char currString[6];
	int length;
	length = GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SCURRENCY,currString, 6);
	strncpy(str, currString, length-1);


}


/***************** Numbers and measurements **************/

/* return true if the metric measurements system is to be used, false otherwise
 * (USA is about it) */
sqInt	sqLocMeasurementMetric(void) {
	char resultString[2];
	if (GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_IMEASURE,resultString, 2) != 0){
		if (strcmp (resultString,"0")) return false;
		else return true;
	}
	return true;
}

/* write the 1 char used for digit grouping into string ptr.
 * Usually this is . or ,  as in 1,000,000 */
void	sqLocGetDigitGroupingSymbolInto(char * str) {
	char groupString[4];
	GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_STHOUSAND,groupString, 4);
	strncpy(str, groupString, 1);

}
/* write the 1 char used for decimal separation into string ptr.
 * Usually this is . or , */
void	sqLocGetDecimalSymbolInto(char * str) {
	char deciString[4];
	GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SDECIMAL, deciString, 4);
	strncpy(str, deciString, 1);
}


/****************** time and date *********************/

sqInt	sqLocGetVMOffsetToUTC(void) {
	/* return 0 for now */
	return 0;
}

sqInt	sqLocGetTimezoneOffset(void) {
  DWORD tzid;
  TIME_ZONE_INFORMATION timeZoneInformation;
  tzid = GetTimeZoneInformation(&timeZoneInformation);

  if(tzid == 1) /* TIME_ZONE_ID_STANDARD */
    return -(timeZoneInformation.Bias+timeZoneInformation.StandardBias);

  if(tzid == 2) /* TIME_ZONE_ID_DAYLIGHT */
    return -(timeZoneInformation.Bias+timeZoneInformation.DaylightBias);

  return -timeZoneInformation.Bias;
}

/* return true if DST is in use, false otherwise */
sqInt	sqLocDaylightSavings(void) {
  TIME_ZONE_INFORMATION timeZoneInformation;
  return GetTimeZoneInformation(&timeZoneInformation) == 2;
}

static char longDateFormat[] = "dddd dd mmmm yy";
/* return the size in chars of the long date format string */
sqInt	sqLocLongDateFormatSize(void) {
	return GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SLONGDATE, NULL, 0)-1;
}

/*Write the string describing the long date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name
*/
void	sqLocGetLongDateFormatInto(char * str) {
	char dateString[80];
	int length;
	length = GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SLONGDATE, dateString, 80);
	strncpy(str, dateString, length-1);
}

static char shortDateFormat[] = "dd/mm/yy";
/* return the size in chars of the short date format string */
sqInt	sqLocShortDateFormatSize(void) {
	return GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SSHORTDATE, NULL, 0)-1;
}

/*Write the string describing the short date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetShortDateFormatInto(char * str) {
	char dateString[80];
	int length;
	length = GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_SSHORTDATE, dateString, 80);
	strncpy(str, dateString, length-1);
}

static char timeFormat[] = "h:m:s";
/* return the size in chars of the time format string */
sqInt	sqLocTimeFormatSize(void) {
	return GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_STIMEFORMAT, NULL, 0)-1;
}

/* write the string describing the time formatting into string ptr.
 * Format is made up of
 * 		h hour (h 12, H 24), m minute, s seconds, x (am/pm String)
 * 		double symbol is null padded, single not padded (h=6, hh=06)  */
void	sqLocGetTimeFormatInto(char * str) {
	char timeString[80];
	int length;
	length = GetLocaleInfo(LOCALE_USER_DEFAULT,LOCALE_STIMEFORMAT, timeString, 80);
	strncpy(str, timeString, length-1);
}
