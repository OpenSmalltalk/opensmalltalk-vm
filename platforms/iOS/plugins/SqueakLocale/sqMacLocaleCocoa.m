//
//  sqMacLocaleCocoa.m
//  SqueakLocale
//
//  Created by John M McIntosh on 10-09-07.
/*
Copyright (c) 2010 Corporate Smalltalk Consulting Ltd. All rights reserved.
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

#import "sqMacLocaleCocoa.h"

sqInt sqLocInitialize(void) {
	return true;
}

/************** Country and language ******************/

/* write the country code into the string ptr. ISO 3166 is the relevant source
 * here; see http://www.unicode.org/onlinedat/countries.html for details.
 * Using the 3 character Alpha-3 codes */
void	sqLocGetCountryInto(char * str) {
	NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
	NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
	NSUInteger usedByteCount = 0;
	[countryCode getBytes: str 
				maxLength: 3 
			   usedLength: &usedByteCount 
				 encoding: NSMacOSRomanStringEncoding 
				  options:NSStringEncodingConversionExternalRepresentation 
					range:NSMakeRange(0,3) 
		   remainingRange: NULL];
}

/* write the 3 char string describing the language in use into string ptr.
 * ISO 639 is the relevant source here;
 * see http://www.w3.org/WAI/ER/IG/ert/iso639.html
 * for details */
void	sqLocGetLanguageInto(char * str) {
	NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
	NSString *languageCode = [locale objectForKey: NSLocaleLanguageCode];
	NSUInteger usedByteCount = 0;
	[languageCode getBytes: str 
				maxLength: 3 
			   usedLength: &usedByteCount 
				 encoding: NSMacOSRomanStringEncoding 
				  options:NSStringEncodingConversionExternalRepresentation 
					range:NSMakeRange(0,3) 
		   remainingRange: NULL];
}

/***************** Currency ********************/

/* return 1 (true) if the currency symbol is to be placed in front of the
 *currency amount */
sqInt	sqLocCurrencyNotation(void) {

	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    NSString *numberAsString = [numberFormatter stringFromNumber:[NSNumber numberWithFloat: 1.2f]];
	NSRange currencyLocation = [numberAsString rangeOfString:[numberFormatter currencySymbol]];
	return (sqInt) (currencyLocation.location == 0);
}

/* return the length in chars of the curency symbol string */
sqInt	sqLocCurrencySymbolSize(void) {
	NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
	NSString *currencySymbol = [locale objectForKey: NSLocaleCurrencySymbol];
	return [currencySymbol lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
}

/* write the currency symbol into the string ptr */
void	sqLocGetCurrencySymbolInto(char * str) {
	NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
	NSString *currencySymbol = [locale objectForKey: NSLocaleCurrencySymbol];
	NSUInteger usedByteCount = 0;
	[currencySymbol getBytes: str 
				 maxLength: sqLocCurrencySymbolSize()
				usedLength: &usedByteCount 
				  encoding: NSUTF8StringEncoding 
				   options:NSStringEncodingConversionExternalRepresentation 
					 range:NSMakeRange(0,[currencySymbol length]) 
			remainingRange: NULL];
}

/***************** Numbers and measurements **************/

/* return true if the metric measurements system is to be used, false otherwise
 * (USA is about it) */
sqInt	sqLocMeasurementMetric(void) {
	NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
	NSNumber *metric = [locale objectForKey: NSLocaleUsesMetricSystem];
	return [metric boolValue];
}

/* write the 1 char used for digit grouping into string ptr.
 * Usually this is . or ,  as in 1,000,000 */
void	sqLocGetDigitGroupingSymbolInto(char * str) {
	NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
	NSString *grouping = [locale objectForKey: NSLocaleGroupingSeparator];	
	NSUInteger usedByteCount = 0;
	[grouping getBytes: str 
				 maxLength: 1 
				usedLength: &usedByteCount 
				  encoding: NSMacOSRomanStringEncoding 
				   options:NSStringEncodingConversionExternalRepresentation 
					 range:NSMakeRange(0,[grouping length]) 
			remainingRange: NULL];
}

/* write the 1 char used for decimal separation into string ptr.
 * Usually this is . or , */
void	sqLocGetDecimalSymbolInto(char * str) {
	NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
	NSString *decimal = [locale objectForKey: NSLocaleDecimalSeparator];	
	NSUInteger usedByteCount = 0;
	[decimal getBytes: str 
			 maxLength: 1 
			usedLength: &usedByteCount 
			  encoding: NSMacOSRomanStringEncoding 
			   options:NSStringEncodingConversionExternalRepresentation 
				 range:NSMakeRange(0,[decimal length]) 
		remainingRange: NULL];
}


/****************** time and date *********************/

sqInt	sqLocGetVMOffsetToUTC(void) {
	/* return 0 for now */
	return 0;
}

sqInt	sqLocGetTimezoneOffset(void) {
	NSTimeZone *tz = [NSTimeZone systemTimeZone];
	NSInteger offset = [tz secondsFromGMT];
	return (offset)/60;
}

/* return true if DST is in use, false otherwise */
sqInt	sqLocDaylightSavings(void) {
	NSTimeZone *tz = [NSTimeZone systemTimeZone];
	return [tz isDaylightSavingTime];
}

/* return the size in chars of the long date format string */

sqInt	sqLocLongDateFormatSize(void) {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *fmt = [dateFormatter dateFormat];	
	return [fmt lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
}
/*Write the string describing the long date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetLongDateFormatInto(char * str) {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *fmt = [dateFormatter dateFormat];	
	NSUInteger usedByteCount = 0;
	[fmt getBytes: str 
			 maxLength: sqLocLongDateFormatSize() 
			usedLength: &usedByteCount 
			  encoding: NSUTF8StringEncoding 
			   options:NSStringEncodingConversionExternalRepresentation 
				 range:NSMakeRange(0,[fmt length]) 
		remainingRange: NULL];
	
}

/* return the size in chars of the short date format string */
sqInt	sqLocShortDateFormatSize(void) {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:kCFDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *fmt = [dateFormatter dateFormat];	
	return [fmt lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
}
/*Write the string describing the short date formatting into string ptr.
 * Format is made up of
 * 		d day, m month, y year,
 * 		double symbol is null padded, single not padded (m=6, mm=06)
 * 		dddd weekday
 * 		mmmm month name */
void	sqLocGetShortDateFormatInto(char * str) {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:kCFDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *fmt = [dateFormatter dateFormat];	
	NSUInteger usedByteCount = 0;
	[fmt getBytes: str 
		maxLength: sqLocLongDateFormatSize() 
	   usedLength: &usedByteCount 
		 encoding: NSUTF8StringEncoding 
		  options:NSStringEncodingConversionExternalRepresentation 
			range:NSMakeRange(0,[fmt length]) 
   remainingRange: NULL];
}

/* return the size in chars of the time format string */
sqInt	sqLocTimeFormatSize(void) {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
	[dateFormatter setTimeStyle:kCFDateFormatterMediumStyle];
	NSString *fmt = [dateFormatter dateFormat];	
	return [fmt lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
}
/* write the string describing the time formatting into string ptr.
 * Format is made up of
 * 		h hour (h 12, H 24), m minute, s seconds, x (am/pm String)
 * 		double symbol is null padded, single not padded (h=6, hh=06)  */
void	sqLocGetTimeFormatInto(char * str) {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
	[dateFormatter setTimeStyle:kCFDateFormatterMediumStyle];
	NSString *fmt = [dateFormatter dateFormat];	
	NSUInteger usedByteCount = 0;
	[fmt getBytes: str 
		maxLength: sqLocTimeFormatSize() 
	   usedLength: &usedByteCount 
		 encoding: NSUTF8StringEncoding 
		  options:NSStringEncodingConversionExternalRepresentation 
			range:NSMakeRange(0,[fmt length]) 
   remainingRange: NULL];
}