/****************************************************************************
*   PROJECT: Common include
*   FILE:    LocalePlugin.h
*   CONTENT: 
*
*   AUTHOR:   tim@rowledge.org
*   ADDRESS: 
*   EMAIL:   
*   RCSID:   $Id: LocalePlugin.h
*
*/
/* Locale support definitions */

sqInt sqLocInitialize(void);

/************** Country and language ******************/

/* write the country code into the string ptr. ISO 3166 is the relevant source
 * here; see http://www.unicode.org/onlinedat/countries.html for details.
 * Using the 3 character Alpha-3 codes */
void	sqLocGetCountryInto(char * str);

/* write the 3 char string describing the language in use into string ptr.
 * ISO 639 is the relevant source here;
 * see http://www.w3.org/WAI/ER/IG/ert/iso639.html
 * for details */
void	sqLocGetLanguageInto(char * str);


/***************** Currency ********************/

/* return true if the currency symbol is to be placed in front of the currency
 * amount */
sqInt	sqLocCurrencyNotation(void);

/* return the length in chars of the curency symbol string */
sqInt	sqLocCurrencySymbolSize(void);
/* write the currency symbol into the string ptr */
void	sqLocGetCurrencySymbolInto(char * str);


/***************** Numbers and measurements **************/

/* return true if the metric measurements system is to be used, false otherwise
 * (USA is about it) */
sqInt	sqLocMeasurementMetric(void);

/* write the 1 char used for digit grouping into string ptr.
 * Usually this is . or ,  as in 1,000,000 */
void	sqLocGetDigitGroupingSymbolInto(char * str);
/* write the 1 char used for decimal separation into string ptr.
 * Usually this is . or , */
void	sqLocGetDecimalSymbolInto(char * str);


/****************** time and date *********************/

/* return in minutes the offset between thisVM and UTC. */
sqInt	sqLocGetVMOffsetToUTC(void);

/* return in minutes the offset between the currenct timezone and UTC */
sqInt	sqLocGetTimezoneOffset(void);

/* return true if DST is in use, false otherwise */
sqInt	sqLocDaylightSavings(void);

/* return the size in chars of the long date format string */
sqInt	sqLocLongDateFormatSize(void);
/*Write the string describing the long date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetLongDateFormatInto(char * str);

/* return the size in chars of the short date format string */
sqInt	sqLocShortDateFormatSize();
/*Write the string describing the short date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetShortDateFormatInto(char * str);

/* return the size in chars of the time format string */
sqInt	sqLocTimeFormatSize(void);
/* write the string describing the time formatting into string ptr.
 * Format is made up of
 * 		h hour (h 12, H 24), m minute, s seconds, x (am/pm String)
 * 		double symbol is null padded, single not padded (h=6, hh=06)  */
void	sqLocGetTimeFormatInto(char * str);
