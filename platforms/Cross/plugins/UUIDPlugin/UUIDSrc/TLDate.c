/*------------------------------------------------------------
| TLDate.c
|-------------------------------------------------------------
|
| PURPOSE: To provide date and time conversion procedures.
|
| HISTORY: 01.22.95
------------------------------------------------------------*/

#include "TLTarget.h" // Include this first.

#include <stdio.h>

#if macintosh

#include <OSUtils.h>

#endif // macintosh

#include "TLTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLDate.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLMassMem.h"
#include "TLTable.h"
#include "TLNameAt.h"
#include "TLAk2Types.h"
#include "TLNumber.h"
#include "TLStacks.h"
#include "TLParse.h"

#if defined( __INTEL__ ) || defined( _M_IX86 )
#include "TLTimeNT.h"
#endif

// These dates are regarded as current for purposes of
// estimation and daily data update requests.
u32 EffectiveTradeTime;
u32 EffectiveTradeTimeYYYYMMDD;

// List of all holidays over the period recorded in the
// contract database.  A holiday is defined as any day
// for which the exchanges close voluntarily.
// This has been superceded by market specific lists.
s8*
Holidays[] = 
{
    (s8*) "09/06/93", // Labor Day 
    (s8*) "11/25/93", // Thanksgiving
    0 // Mark end list with a zero.
};

DayRecord   
DaysOfWeek[DaysPerWeek] = // Day index is 0-based.
{
    {
        Sunday,  // DayNumber  
        (s8*) "Sunday",// NameOfDay 
        (s8*) "Sun"    // ShortNameOfDay 
    },
    {
        Monday,  // DayNumber  
        (s8*) "Monday",// NameOfDay 
        (s8*) "Mon"    // ShortNameOfDay 
    },
    {
        Tuesday,  // DayNumber  
        (s8*) "Tuesday",// NameOfDay 
        (s8*) "Tue"     // ShortNameOfDay 
    },
    {
        Wednesday,  // DayNumber  
        (s8*) "Wednesday",// NameOfDay 
        (s8*) "Wed"       // ShortNameOfDay 
    },
    {
        Thursday,  // DayNumber  
        (s8*) "Thursday",// NameOfDay 
        (s8*) "Thu"      // ShortNameOfDay 
    },
    {
        Friday,  // DayNumber  
        (s8*) "Friday",// NameOfDay 
        (s8*) "Fri"    // ShortNameOfDay 
    },
    {
        Saturday,  // DayNumber  
        (s8*) "Saturday",// NameOfDay 
        (s8*) "Sat"      // ShortNameOfDay 
    }
};

    
MonthRecord 
MonthsOfYear[MonthsPerYear+1] = // Month index is 1-based.
{
    {
        0, // MonthNumber      THIS IS A PLACEHOLDER RECORD 
        0, // MonthLetter 
        0, // NameOfMonth 
        0, // ShortNameOfMonth 
    },
    {
        January,    // MonthNumber      
        'F',        // MonthLetter 
        (s8*) "January",    // NameOfMonth 
        (s8*) "Jan"         // ShortNameOfMonth 
    },
    {
        February,   // MonthNumber      
        'G',        // MonthLetter 
        (s8*) "February", // NameOfMonth 
        (s8*) "Feb"         // ShortNameOfMonth 
    },
    {
        March,      // MonthNumber      
        'H',        // MonthLetter 
        (s8*) "March",  // NameOfMonth 
        (s8*) "Mar"         // ShortNameOfMonth 
    },
    {
        April,      // MonthNumber      
        'J',        // MonthLetter 
        (s8*) "April",  // NameOfMonth 
        (s8*) "Apr"         // ShortNameOfMonth 
    },
    {
        May,        // MonthNumber      
        'K',        // MonthLetter 
        (s8*) "May",        // NameOfMonth 
        (s8*) "May",        // ShortNameOfMonth 
    },
    {
        June,       // MonthNumber      
        'M',        // MonthLetter 
        (s8*) "June",   // NameOfMonth 
        (s8*) "Jun",        // ShortNameOfMonth 
    },
    {
        July,       // MonthNumber      
        'N',        // MonthLetter 
        (s8*) "July",   // NameOfMonth 
        (s8*) "Jul",        // ShortNameOfMonth 
    },
    {
        August,     // MonthNumber      
        'Q',        // MonthLetter 
        (s8*) "August",     // NameOfMonth 
        (s8*) "Aug",        // ShortNameOfMonth 
    },
    {
        September,  // MonthNumber      
        'U',        // MonthLetter 
        (s8*) "September",  // NameOfMonth 
        (s8*) "Sep",        // ShortNameOfMonth 
    },
    {
        October,    // MonthNumber      
        'V',        // MonthLetter 
        (s8*) "October",    // NameOfMonth 
        (s8*) "Oct",        // ShortNameOfMonth 
    },
    {
        November,   // MonthNumber      
        'X',        // MonthLetter 
        (s8*) "November", // NameOfMonth 
        (s8*) "Nov",        // ShortNameOfMonth 
    },
    {
        December,   // MonthNumber      
        'Z',        // MonthLetter 
        (s8*) "December", // NameOfMonth 
        (s8*) "Dec",        // ShortNameOfMonth 
    },
};

// Assumes TradeTime origin is on a leap year.
u32 
MinutesToYearAfterTradeTimeOrigin[]=
{
    0,                         // At the origin
    MinPerLeapYear,            // One year after origin
    MinPerLeapYear+MinPerYear, // Two years after origin
    MinPerLeapYear+
    MinPerYear+MinPerYear,     // Three years after origin
    MinPerFourYears            // Four years after origin
};

u32
MinutesToMonth[] =
{ 
         0, // place holder - month is 1-based
         0, // January,   31 days
     44640, // February,  28 days 
     84960, // March,     31 days
    129600, // April,     30 days 
    172800, // May,       31 days 
    217440, // June,      30 days 
    260640, // July,      31 days 
    305280, // August,    31 days 
    349920, // September, 30 days 
    393120, // October,   31 days 
    437760, // November,  30 days 
    480960, // December,  31 days
    MinPerLeapYear // January
};

u32
MinutesToMonthForLeapYear[] =
{
         0, // place holder - month is 1-based
         0, // January,   31 days
     44640, // February,  29 days 
     86400, // March,     31 days
    131040, // April,     30 days 
    174240, // May,       31 days 
    218880, // June,      30 days 
    262080, // July,      31 days 
    306720, // August,    31 days 
    351360, // September, 30 days 
    394560, // October,   31 days 
    439200, // November,  30 days 
    482400, // December,  31 days
    MinPerLeapYear  // January
};

u32
DaysInMonth[] =
{ 
     0, // place holder - month is 1-based
    31, // January
    28, // February, 29 for leap years.
    31, // March
    30, // April 
    31, // May 
    30, // June
    31, // July 
    31, // August 
    30, // September 
    31, // October 
    30, // November 
    31, // December
};

u32
DaysInMonthForLeapYear[] =
{ 
     0, // place holder - month is 1-based
    31, // January
    29, // February 
    31, // March
    30, // April 
    31, // May 
    30, // June
    31, // July 
    31, // August 
    30, // September 
    31, // October 
    30, // November 
    31, // December
};

/*------------------------------------------------------------
| AddMinutesToHourMinute
|-------------------------------------------------------------
| 
| PURPOSE: To add some number of minutes to an hour:minute
|          time.
| 
| DESCRIPTION:  
| 
| EXAMPLE:  
| 
| NOTE: 
| 
| ASSUMES: Amount added/subtracted results in a value that
|          is in the same day.
| 
| HISTORY: 12.27.96
------------------------------------------------------------*/
void    
AddMinutesToHourMinute( s32 MinToAdd, u32* Hour, u32* Minute )
{
    s32 MinOfDay;
    
    // Convert hour:minute to minute of day.
    MinOfDay = (s32) HourMinuteToMinuteOfDay( *Hour, *Minute );
    
    // Add the adjustment.
    MinOfDay += MinToAdd;
    
    // Convert the minute of the day back to hour:minute.
    MinuteOfDayToHourMinute( (u32) MinOfDay, Hour, Minute );
}

/*------------------------------------------------------------
| CalendarTimeToTradeTime
|-------------------------------------------------------------
| 
| PURPOSE: To convert calendar time to the TradeTime system.
| 
| DESCRIPTION: Returns the number of minutes since the 
| TradeTime origin.
| 
| EXAMPLE:  t = CalendarTimeToTradeTime( 1968, 5, 23, 12, 0 );
|           t =  ?
| NOTE: 
| 
| ASSUMES: Calendar time is in terms of GMT.
|          'Year' is > TradeTimeOriginYear.
|          Hours are in 24 hour format 0-23.
| 
| HISTORY: 01.22.95 from 'time.txt' in Focus.
------------------------------------------------------------*/
u32
CalendarTimeToTradeTime( u32 Year, 
                         u32 Month, 
                         u32 Day, 
                         u32 Hour,
                         u32 Minute )
{
    u32 dy;
    u32 Time;
    u32 FourYearPeriods;
    
    Time = Minute;
    Time += Hour * MinPerHour;
    Time += (Day - 1) * MinPerDay;
    
    if( (Year & 3) == 0 ) // Is this a leap year?
    {
        Time += MinutesToMonthForLeapYear[Month];
    }
    else // Non-Leap year.
    {
        Time += MinutesToMonth[Month];
    }
    
    // 'Time' now holds the number of minutes since
    // the beginning of 'Year'.
    
    // Add the number of minutes between the origin 
    // year and this one.
    
    dy = Year - TradeTimeOriginYear;
    
    FourYearPeriods = dy >> 2 ; // number of complete four year periods.
    
    Time += FourYearPeriods * MinPerFourYears;
    
    dy -= FourYearPeriods << 2;
    
    // 'dy' now hold number of years not in a full
    // four-year period; 0-3.
    
    Time += MinutesToYearAfterTradeTimeOrigin[dy];
    
    return( Time );
} 

/*------------------------------------------------------------
| CurrentMinuteOfDay
|-------------------------------------------------------------
|
| PURPOSE: To get the current minute of the day for the local
|          time zone.
|
| DESCRIPTION: Returns the current number of minutes since
|              midnight.
| 
| EXAMPLE:  TheTime = CurrentMinuteOfDay();
|
| NOTE: See 'Inside Mac, Operating System Utilities' p. 4-19.
|
| ASSUMES: 
|
| HISTORY: 12.23.96 
------------------------------------------------------------*/
u32
CurrentMinuteOfDay()
{
    u32* LocalTime;
    u32  LocalTimeInSeconds;
    u32  SecondOfTheDay;
    u32  MinuteOfTheDay;
    
    // Get the local time in seconds since midnight
    // January 1 1904.
    LocalTime = (u32*) 0x20C; // see page 223 Inside Mac XRef
    
    // Get the local time in seconds.
    LocalTimeInSeconds =  LocalTime[0];
    
    // Get the current second of the day.
    SecondOfTheDay = LocalTimeInSeconds % SecondsPerDay;
    
    // Convert seconds to minutes.
    MinuteOfTheDay = SecondOfTheDay / SecondsPerMinute;
    
    return( MinuteOfTheDay );
}
    
/*------------------------------------------------------------
| CurrentMonth
|-------------------------------------------------------------
|
| PURPOSE: To get the current month number.
|
| DESCRIPTION: Returns a number from 1 to 12.
| 
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.14.96 
------------------------------------------------------------*/
u32
CurrentMonth()
{
    u32 TradeTime;
    u32 Year;
    u32 Month;
    u32 Day;
    u32 Hour;
    u32 Minute;
    
    TradeTime = CurrentTradeTime();
    
    TradeTimeToCalendarTime( TradeTime,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
    return( Month );
}

/*------------------------------------------------------------
| CurrentYear
|-------------------------------------------------------------
|
| PURPOSE: To get the current year number.
|
| DESCRIPTION: Returns a number like '1996'.
| 
| EXAMPLE:   
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 06.13.96 
------------------------------------------------------------*/
u32
CurrentYear()
{
    u32 TradeTime;
    u32 Year;
    u32 Month;
    u32 Day;
    u32 Hour;
    u32 Minute;
    
    TradeTime = CurrentTradeTime();
    
    TradeTimeToCalendarTime( TradeTime,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
    return( Year );
}
    
/*------------------------------------------------------------
| CurrentTradeTime
|-------------------------------------------------------------
|
| PURPOSE: To get the current time in TradeTime format.
|
| DESCRIPTION: Returns the number of minutes since 00:00
| January 1 1904 GMT.
| 
| EXAMPLE:  TheTime = CurrentTradeTime();
|
| Test results:
|
|   TradeTime   TimeAndDateString     The system time.
|   48414225    01/18/96 23:45          1/18/96  3:45 PM 
|
|   48588418    05/18/96 22:58          05/18/96 3:58 PM *
|                                       * Daylight savings 
|                                         time.
|
| NOTE: See 'Inside Mac, Operating System Utilities' p. 4-19.
|
| ASSUMES: 
|
| HISTORY: 01.18.96 Tested for today.
|                   Check DayLight savings adjustment.
|          01.14.99 Added reading of location parameter: code
|                   copied from 'TLUUID.c'; added NT support.
------------------------------------------------------------*/
u32
CurrentTradeTime()
{
    s32  TradeTime;
    u64  t;

#if macintosh
    u32             LocalTime;
    u32             LocalStandardTime;
    s32             LocalTimeInMinutes;
    MachineLocation Here;
    u32             TheGMTDelta, TheDLSDelta;
    
    // Get the local time in seconds since midnight
    // January 1 1904.
    LocalTime = *( (u32*) 0x20C ); // see page 223 Inside Mac XRef
    
    // Read the machine location from the parameter RAM.
    //
    // If the geographic location record has never been set, 
    // all fields contain 0.
    ReadLocation( &Here );
    
    // If the location has never been set.
    if( Here.latitude   == 0 && 
        Here.longitude  == 0 && 
        Here.u.gmtDelta == 0 )
    {
        // Default to location defined by 'LocalTimeZone'
        // in 'TLDate.h'.
        
        // Convert local time to minutes relative to TradeTime
        // origin.
        LocalTimeInMinutes = (s32)
            ( (f64) LocalTime * MinPerSecond );
        
        // Apply the Daylight Savings Time correction.
        LocalStandardTime = 
            LocalTimeToLocalStandardTime( LocalTimeInMinutes,
                                          LocalTimeZone );
        
        // Apply the GMT offset to standard time. 
        TradeTime = LocalStandardTime + 
                    ( LocalTimeZone * MinPerHour );
    }
    else // The location has been set.
    {
        // The Greenwich mean time value of the location
        // record is in seconds east of GMT. For example, 
        // San Francisco is at ­28,800 seconds 
        // (8 hours * 3,600 seconds per hour) east of GMT.
        //
        // The 'gmtDelta' field of the geographic location 
        // record is a 3-byte value contained in a 32-bit field
        // so it must be extracted and sign-extended.
        TheGMTDelta = Here.u.gmtDelta & 0x00FFFFFF;
    
        // Sign-extend the GMT correction.
        if( TheGMTDelta & 0x00800000 )
        {
            TheGMTDelta |= 0xFF000000;
        }
        
        // The daylight savings time value is a signed byte 
        // value that specifies the offset for the hour field --
        // whether to add 1 hour, subtract 1 hour, or make no 
        // change at all.
        TheDLSDelta = (s32) Here.u.dlsDelta;
        
        // Add the number of seconds for the GMT adjustment
        // to the local time.
        t = LocalTime + TheGMTDelta;
        
        // Add the number of seconds for the DLS adjustment.
        t += (TheDLSDelta * SecondsPerHour);
        
        // Convert seconds to minutes.
        TradeTime = (s32) ( t / 60 );
    }
 #else // Not MacOS.
 
#if defined( __INTEL__ ) || defined( _M_IX86 )
 
    // Get the current time in 100-nanosecond units since
    // January 1, 1601.
    GetTimeNT( &t ); 
 
    // Convert time from 100-nanoseconds to seconds by 
    // dividing by ten million.
    t = t / 10000000;
 
    // Subtract the number of seconds between January 1 1601
    // and January 1 1904.  This adjustment can be computed
    // before compile time to make this go faster.
    t = t -
        ( ( JulianDay( 1, 1, 1904 ) - 
            JulianDay( 1, 1, 1601 ) ) * SecondsPerDay );
    
    // Convert seconds to minutes.
    TradeTime = (s32) ( t / 60 );
 
 #endif // __INTEL__
 
 #endif // macintosh
 
    // Return the result.
    return( (u32) TradeTime );
}

/*------------------------------------------------------------
| CurrentYYYYMMDD
|-------------------------------------------------------------
|
| PURPOSE: To get the current GMT date in YYYYMMDD format.
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 03.27.96 from 'CurrentTradeTime'.
------------------------------------------------------------*/
u32
CurrentYYYYMMDD()
{
    u32  TradeTime;
    
    TradeTime = CurrentTradeTime();

    return( TradeTimeToYYYYMMDD( TradeTime ) );
}

/*------------------------------------------------------------
| ConvertMonthLetterToMonthNumber
|-------------------------------------------------------------
| 
| PURPOSE: To convert a contract month letter code to calendar
|          month number.
| 
| DESCRIPTION: January = 1... December = 12.
| 
| EXAMPLE:  m = MonthLetterToMonthNumber( 'F' );
|           so, m == 1.
|             
| NOTE: To get the month code from the month number use
|       this fragment:
|
|        mc = MonthsOfYear[MonthNumber].MonthLetter
| 
| ASSUMES: 
| 
| HISTORY: 01.09.96 
------------------------------------------------------------*/
u32
ConvertMonthLetterToMonthNumber( u32 MonthLetter )
{
    switch( MonthLetter )
    {
        case JanuaryLetter:     return( January );
        case FebruaryLetter:    return( February );
        case MarchLetter:       return( March );
        case AprilLetter:       return( April );
        case MayLetter:         return( May );
        case JuneLetter:        return( June );
        case JulyLetter:        return( July );
        case AugustLetter:      return( August );
        case SeptemberLetter:   return( September );
        case OctoberLetter:     return( October );
        case NovemberLetter:    return( November );
        case DecemberLetter:    return( December );
        
        default:    
            // if get here then in error.
            Debugger();
    }
    
    return( 0 );
}

/*------------------------------------------------------------
| DayOfWeek
|-------------------------------------------------------------
| 
| PURPOSE: To compute the day of the week given a date
|          vector.
| 
| DESCRIPTION: Sunday = 0, Monday = 1...
| 
| EXAMPLE:  DayOfWeek( 12, 6, 1994 )
|            ans = 2
| NOTE: 
| 
| ASSUMES: Year is > 0. 
| 
| HISTORY: 12.06.94 
|          01.15.95 revised from Matlab format.
------------------------------------------------------------*/
u32
DayOfWeek( u32 Month, u32 Day, u32 Year )
{
    return( ( JulianDay( Month, Day, Year ) + 1) % 7 );
}

/*------------------------------------------------------------
| DayOfWeek2
|-------------------------------------------------------------
| 
| PURPOSE: To compute the day of the week given a time in
|          TradeTime format.
| 
| DESCRIPTION: Sunday = 0, Monday = 1...
| 
| EXAMPLE:  d = DayOfWeek2( t );
|             
| NOTE: 
| 
| ASSUMES: Year is > 0. 
| 
| HISTORY: 01.09.96 from 'DayOfWeek'.
------------------------------------------------------------*/
u32
DayOfWeek2( u32 TradeTime )
{
    u32 Year; 
    u32 Month; 
    u32 Day; 
    u32 Hour;
    u32 Minute;
    
    TradeTimeToCalendarTime( TradeTime,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );

    return( ( JulianDay( Month, Day, Year ) + 1) % 7 );
}

/*------------------------------------------------------------
| DayOfWeek3
|-------------------------------------------------------------
| 
| PURPOSE: To compute the day of the week given a date
|          in string format.
| 
| DESCRIPTION: Sunday = 0, Monday = 1...
| 
| EXAMPLE:  DayOfWeek3( "12/06/94" );
|            ans = 2
| NOTE: 
| 
| ASSUMES: Year is > 0. 
| 
| HISTORY: 04.16.96 from 'DayOfWeek'.
------------------------------------------------------------*/
u32
DayOfWeek3( s8* Date )
{
    return( ( DateStringToJulianDay( Date ) + 1) % 7 );
}

/*------------------------------------------------------------
| DayAtOffset
|-------------------------------------------------------------
|
| PURPOSE: To return the date string of the day at a given 
| number of days from the given date string.
|
| DESCRIPTION: Given a date string in the format:
|
|            mm/dd/yy, eg. "07/01/93" and the number of 
| days to add or subtract,
|
| returns the date string of the resulting day.
|
| EXAMPLE:  
|
|    DayAtOffset("08/01/93",-1);
|
|   returns "07/31/93"
|
| NOTE: 
|
| ASSUMES: Date string is exactly in the form: mm/dd/yy.
|
| HISTORY:  08.19.93 
|           01.15.96 converted from Mathematica.
------------------------------------------------------------*/
s8*
DayAtOffset( s8* Date, s32 Offset )
{
    s32 Time;
    
    Time = (s32) DateStringToTradeTime( Date );
    
    Time += Offset * MinPerDay;

    return( TradeTimeToDateString( (u32) Time ) );
}

/*------------------------------------------------------------
| DayAtOffset2
|-------------------------------------------------------------
|
| PURPOSE: To return the date of the day at a given 
| number of days from the given date.
|
| DESCRIPTION: Given a date in the TradeTime format and the 
| number of days to add or subtract, returns the TradeTime
| of the resulting day.
|
| EXAMPLE:  
|
|   n = DayAtOffset2(t,-1);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.16.96 From 'DayAtOffset'.
|           01.21.99 Converted to unsigned.
------------------------------------------------------------*/
u32
DayAtOffset2( u32 Time, s32 Offset )
{
    u32 t;
    
    if( Offset < 0 )
    {
        t = Time - ( (u32) Offset * MinPerDay );
    }
    else
    {
        t = Time + ( (u32) Offset * MinPerDay );
    }   
        
    return( t );
}

/*------------------------------------------------------------
| DateAndTimeStringToTradeTime
|-------------------------------------------------------------
|
| PURPOSE: To convert a date and time string to TradeTime.
|
| DESCRIPTION: Expects a date string in the format 
| 'mm/dd/yy hh:mm', eg. "07/01/93 12:34", where the time is
| in 24-hour format.
|
| EXAMPLE:  
|
|    s = DateAndTimeStringToTradeTime( "07/01/93 12:34" );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  05.31.96
------------------------------------------------------------*/
u32
DateAndTimeStringToTradeTime( s8* DateAndTime )
{
    u32 Year, Month, Day, Hour, Minute;
    
    DateStringToYearMonthDay( DateAndTime,
                              &Year, 
                              &Month, 
                              &Day );
                            
    TimeStringToHourMinute( &DateAndTime[9], 
                            &Hour, 
                            &Minute );
                            
    return( CalendarTimeToTradeTime( Year, 
                                     Month, 
                                     Day, 
                                     Hour,
                                     Minute ) );
}   

/*------------------------------------------------------------
| DateStringToJulianDay
|-------------------------------------------------------------
| 
| PURPOSE: To convert a date string to Julian day number.
| 
| DESCRIPTION: Given a date string in the format:
| 
|             mm/dd/yy, eg. "07/01/93"
| 
|  returns Julian day number.
| 
| EXAMPLE:  DateStringToJulianDay( "05/23/68" )
|           ans = 2440000
| NOTE: 
| 
| ASSUMES: Year is in range 1911 - 2010. 
| 
| HISTORY: 01.15.95 
------------------------------------------------------------*/
u32
DateStringToJulianDay( s8* Date )
{
    u32 Month, Day, Year;
    
    DateStringToYearMonthDay( Date,
                              &Year, 
                              &Month, 
                              &Day );
    
    return( JulianDay( Month, Day, Year ) );
}

/*------------------------------------------------------------
| DateStringToTradeTime
|-------------------------------------------------------------
| 
| PURPOSE: To convert a date string to TradeTime minute number.
| 
| DESCRIPTION: Given a date string in the format:
| 
|             mm/dd/yy, eg. "07/01/93"
| 
|  returns TradeTime minute number.
| 
| EXAMPLE:  DateStringToTradeTime( "05/23/68" )
|           ans = ?
| NOTE: 
| 
| ASSUMES: Year is in range 1911 - 2010. 
| 
| HISTORY: 01.22.95 
|          01.15.96 use 'DateStringToYearMonthDay'.
------------------------------------------------------------*/
u32
DateStringToTradeTime( s8* Date )
{
    u32 Month, Day, Year;
    
    DateStringToYearMonthDay( Date, &Year, &Month, &Day );
    
    // Default to 12 noon.
    return( 
        CalendarTimeToTradeTime( 
            Year, Month, Day, 12L, 0L )  
          );
}

/*------------------------------------------------------------
| DateStringToYearMonthDay
|-------------------------------------------------------------
|
| PURPOSE: To convert a date string to year, month, day.
|
| DESCRIPTION: Takes as input date strings of the format
| "MM.DD.YY" or "M.D.YY" or "MM.DD.YYYY" where '.' can be 
| any non-digit.
|
| EXAMPLE:  
|
|    DateStringToYearMonthDay( "07/01/93", &yr, &mn, &dy );
|    DateStringToYearMonthDay( "7/1/93", &yr, &mn, &dy );
|    DateStringToYearMonthDay( "07-01-93", &yr, &mn, &dy );
|    DateStringToYearMonthDay( "7-1-93", &yr, &mn, &dy );
|    DateStringToYearMonthDay( "7-1-1993", &yr, &mn, &dy );
|
| NOTE: 
|
| ASSUMES: Year is in range 1911 - 2010. 
|
| HISTORY:  01.15.96
|           06.06.96 Changed from year range 1951 - 2050 to
|                    accommodate MAP date conversion.
|           01.02.97 revised to allow single digit day or
|                    month.
|           01.07.97 added support for 4-digit year.
------------------------------------------------------------*/
void
DateStringToYearMonthDay( s8* Date,
                          u32* Year, 
                          u32* Month, 
                          u32* Day )
{
    u32 Y, M, D;
    s8* At;
    
    // Refer to the first byte in the string.
    At = Date;
    
    // Parse the month.
    M = ParseUnsignedInteger( &At );
    
    // Advance to the day number.
    At++;
    
    // Parse the day of the month.
    D = ParseUnsignedInteger( &At );
    
    // Advance to the year number.
    At++;

    // Parse the year.
    Y = ParseUnsignedInteger( &At );
    
    // If the year has only 2 digits, infer the other two.
    if( Y < 100 )
    {
        // Convert the two digit year to four digit year.
        if( Y > 10 ) 
        {
            Y += 1900;
        }
        else
        {
            Y += 2000;
        }
    }
    
    *Year  = Y;
    *Month = M;
    *Day   = D;
}

/*------------------------------------------------------------
| DateStringToYYYYMMDD
|-------------------------------------------------------------
| 
| PURPOSE: To convert a date string to 'YYYYMMDD' format 
|          number.
| 
| DESCRIPTION: Given a date string in the format:
| 
|             mm/dd/yy, eg. "07/01/93"
| 
|  returns 'YYYYMMDD' format number
| 
| EXAMPLE:  ans = DateStringToYYYYMMDD( "05/23/68" )
|           ans >> '19680523'
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 03.27.96 from 'DateStringToTradeTime'.
------------------------------------------------------------*/
u32
DateStringToYYYYMMDD( s8* Date )
{
    u32 Month, Day, Year;
    u32 YYYYMMDD;
    
    DateStringToYearMonthDay( Date, &Year, &Month, &Day );
    
    YYYYMMDD = Year * 10000 + Month * 100 + Day;
    
    return( YYYYMMDD );
}

/*------------------------------------------------------------
| fl64ToHourMinute
|-------------------------------------------------------------
| 
| PURPOSE: To convert an f64 of the form 'hhmm' to hour
|          and minute values.
| 
| DESCRIPTION:  
| 
| EXAMPLE:  fl64ToHourMinute( 1225., &Hour, &Minute ); 
|
|           Hour   -> 12 
|           Minute -> 25
|            
| NOTE: 
| 
| ASSUMES: Hours are in 24 hour format 0-23.
| 
| HISTORY: 12.19.96 
|          12.23.96 change packed format from 'hh.mm' to
|                   'hhmm' to avoid roundoff.
------------------------------------------------------------*/
void
f64ToHourMinute( f64 HHMM, s32* Hour, s32* Minute ) 
{
    s32 hhmm;
    
    hhmm = (s32) HHMM;
    
    *Hour   = hhmm / 100;
    *Minute = hhmm % 100;
}

/*------------------------------------------------------------
| HourMinuteToHHMM
|-------------------------------------------------------------
| 
| PURPOSE: To pack hour and minute into a 'HHMM' 
|          format number.
| 
| DESCRIPTION:  
| 
| EXAMPLE:   
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 01.01.97 from 'YearMonthDayToYYYYMMDD'.
------------------------------------------------------------*/
u32
HourMinuteToHHMM( u32 Hour, u32 Minute )
{
    u32 HHMM;
    
    HHMM = Hour * 100 + Minute;
    
    return( HHMM );
}

/*------------------------------------------------------------
| HourMinuteToMinuteOfDay
|-------------------------------------------------------------
| 
| PURPOSE: To convert a time of day known in hours and minutes
|          to minute of the day.
| 
| DESCRIPTION:  
| 
| EXAMPLE:   
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 12.27.96
------------------------------------------------------------*/
u32 
HourMinuteToMinuteOfDay( u32 Hour, u32 Minute )
{
    u32 MinOfDay;
    
    MinOfDay = ( Hour * 60 ) + Minute;
    
    return( MinOfDay );
}

/*------------------------------------------------------------
| HourMinuteToTimeString
|-------------------------------------------------------------
| 
| PURPOSE: To convert hour and minute to a time string.
| 
| DESCRIPTION: Given hour and minute, makes time string in 
| the format "HH:MM", eg. "12:25".
| 
| EXAMPLE:  s = HourMinuteToTimeString( Hour, Minute ); 
|            
| NOTE: 
| 
| ASSUMES: Hours are in 24 hour format 0-23.
| 
| HISTORY: 01.18.96 
------------------------------------------------------------*/
s8*
HourMinuteToTimeString( u32 Hour, u32 Minute ) 
{
    static s8   Time[6];
    
    Time[0] = (s8) ( (Hour / 10) % 10 + '0' );
    Time[1] = (s8) ( Hour % 10 + '0' );
    Time[2] = ':';
    Time[3] = (s8) ( (Minute / 10) % 10 + '0' );
    Time[4] = (s8) ( Minute % 10 + '0' );
    Time[5] = 0;
    
    return( Time );
}

/*------------------------------------------------------------
| IsBusinessDay
|-------------------------------------------------------------
|
| PURPOSE: To test a date to see if it is a business day,
| without taking holidays into account.
|
| DESCRIPTION: Given a date string in the format:
|
|            mm/dd/yy, eg. "07/01/93"
|
| returns 1 if it is a business day.
|
| Rule: Monday thru Friday are business days.
|
| EXAMPLE:  
|
|    d = IsBusinessDay("08/01/93");
|
| NOTE: See also 'IsPlannedExchangeBusinessDay'.
|
| ASSUMES: Date string is exactly in the form: mm/dd/yy.
|
| HISTORY:  07.07.93 
|           09.03.93 corrected dow comparison to use ===
|           01.15.96 converted from Mathematica.
|           01.15.96 Removed holiday exception.
------------------------------------------------------------*/
u32  
IsBusinessDay( s8* Date )
{
    u32 Month, Day, Year, dow;

    DateStringToYearMonthDay( Date,
                              &Year, 
                              &Month, 
                              &Day );
    
    dow = DayOfWeek( Month, Day, Year );

    if( dow == Sunday || dow == Saturday )
    {
        return( 0 );
    }
    else
    {
        return( 1 );
    }
}

/*------------------------------------------------------------
| IsBusinessDay2
|-------------------------------------------------------------
|
| PURPOSE: To test a date to see if it is a business day,
| without taking holidays into account.
|
| DESCRIPTION: Given a date in TradeTime format returns 1 
| if it is a business day.
|
| Rule: Monday thru Friday are business days.
|
| EXAMPLE:  
|
|    d = IsBusinessDay2(t);
|
| NOTE: See also 'IsPlannedExchangeBusinessDay'.
|
| ASSUMES: 
|
| HISTORY:  01.16.96 From 'IsBusinessDay'.
------------------------------------------------------------*/
u32  
IsBusinessDay2( u32 Time )
{
    u32 dow;

    dow = DayOfWeek2( Time );

    if( dow == Sunday || dow == Saturday )
    {
        return( 0 );
    }
    else
    {
        return( 1 );
    }
}

/*------------------------------------------------------------
| IsHoliday
|-------------------------------------------------------------
|
| PURPOSE: To test a date to see if it is a holiday.
|
| DESCRIPTION: Given a date string in the format:
|
|            mm/dd/yy, eg. "07/01/93"
|
| returns 1 if it is a holiday.
|
| Rule: Any day on which the exchanges voluntarily close
| is a holiday.
|
| EXAMPLE:  
|
|    h = IsHoliday("08/01/93");
|
| NOTE: To be fully general an exchange parameter is needed.
|
| ASSUMES: Date string is exactly in the form: mm/dd/yy.
|
| HISTORY:  01.11.96 
------------------------------------------------------------*/
u32  
IsHoliday( s8* Date )
{
    return( IsStringInArray( Date, Holidays ) );
}

/*------------------------------------------------------------
| IsInFirstHalfOfYear
|-------------------------------------------------------------
|
| PURPOSE: To test a TradeTime to see if it is in the first
|          half of the year.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|    h = IsInFirstHalfOfYear(t);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.27.96 
------------------------------------------------------------*/
u32  
IsInFirstHalfOfYear( u32 Time )
{
    u32 Year, Month, Day, Hour, Minute;
    
    TradeTimeToCalendarTime( Time,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
                             
    return( Month < July );                          
}

/*------------------------------------------------------------
| IsTradeTimesInSameDay
|-------------------------------------------------------------
|
| PURPOSE: To test if two TradeTimes are in the same calendar
|          day.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 05.06.97 
------------------------------------------------------------*/
u32  
IsTradeTimesInSameDay( u32 A, u32 B )
{
    return( TradeTimeToYYYYMMDD( A ) == 
            TradeTimeToYYYYMMDD( B ) );
}   

/*------------------------------------------------------------
| LastDayOfMonth
|-------------------------------------------------------------
|
| PURPOSE: To return the day-of-month number for the last day 
| of the month.
|
| DESCRIPTION: Given a month and year, returns the day number
| of the last day of the month.
|
| EXAMPLE:  
|
|    d = LastDayOfMonth( 1993, 8 ); 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  08.19.93 
|           01.15.96 from Mathematica format.
------------------------------------------------------------*/
u32
LastDayOfMonth( u32 Year, u32 Month )
{
    switch( Month )
    {
        case January:   return( 31 );
        case February:
                if( (Year & 3) == 0 ) // Is this a leap year?
                {
                    return( 29 );
                }
                else
                {
                    return( 28 );
                }
        case March:     return( 31 );
        case April:     return( 30 );
        case May:       return( 31 );
        case June:      return( 30 );
        case July:      return( 31 );
        case August:    return( 31 );
        case September: return( 30 );
        case October:   return( 31 );
        case November:  return( 30 );
        case December:  return( 31 );
        default: Debugger();
    }
    
    return( 0 );
}

/*------------------------------------------------------------
| LastWeekDayOfMonth
|-------------------------------------------------------------
|
| PURPOSE: To return the TradeTime of the last given weekday
|          of the given month.
|
| DESCRIPTION: 
|
| EXAMPLE:  Date of last Thursday in September 1993.
|
|    d = LastWeekDayOfMonth( September, 1993, Thursday );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.18.96 
------------------------------------------------------------*/
u32
LastWeekDayOfMonth( u32 Month, u32 Year, u32 WeekDay )
{
    u32 Date;
    u32 Day;
    
    Day = LastDayOfMonth( Year, Month );

    // Find the first chosen weekday in the month.
    while( DayOfWeek( Month, Day, Year ) != WeekDay )
    {
        Day--;
    }
    
    Date = CalendarTimeToTradeTime( Year, 
                                    Month, 
                                    Day, 
                                    12, // Default to 12 noon.
                                    0 );
    
    return( Date );
}   

/*------------------------------------------------------------
| LocalStandardTimeToLocalTime
|-------------------------------------------------------------
|
| PURPOSE: To convert local standard time to local time
| which may be adjusted for Daylight Savings Time.
|
| DESCRIPTION: Applies the Daylight Savings Time adjustment.
| 
| Expects a time in number of minutes since the TradeTime
| origin, in terms of local standard time rather than GMT 
| as is usually the case with TradeTime.
|
| Returns a time in number of minutes since the TradeTime
| origin, in terms of Daylight Savings adjusted local time 
| rather than GMT as is usually the case with TradeTime.
| 
| ***** Only adjusts for U.S. time zones. *****
|
| Only adjusts during Daylight Savings Time Period which
| begins at 2 AM the first Sunday in April and ends at
| 2 AM on the last Sunday in October.
|
| EXAMPLE:  TheTime = LocalStandardTimeToLocalTime( t, z );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 04.08.97 from 'LocalTimeToLocalStandardTime'.
------------------------------------------------------------*/
u32
LocalStandardTimeToLocalTime( u32 LocalTime, 
                              u32 ALocalTimeZone )
{
    u32 FirstSundayInApril;
    u32 LastSundayInOctober;
    u32 Year;
    u32 Month; 
    u32 Day; 
    u32 Hour;
    u32 Minute;
    
    // If not one of the continental U.S. time zones,
    // return the local time as is.
    if( ALocalTimeZone < EST || ALocalTimeZone > PST )
    {
        return( LocalTime );
    }

    TradeTimeToCalendarTime( LocalTime,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
    
    // Find 2 AM first Sunday of April in same year as
    // given time.  'DateStringToTradeTime' defaults to 
    // 12 noon.                  
    FirstSundayInApril = 
        DateStringToTradeTime(
            NthWeekDayOfMonth( April, Year, 1, Sunday ) ) -
        ( 10 * MinPerHour );
        

    // Find 2 AM last Sunday of October in same year as
    // given time.                   
    LastSundayInOctober =
            LastWeekDayOfMonth( October, Year, Sunday ) -
            ( 10 * MinPerHour );

    // If during Daylight Savings Time period.
    if( FirstSundayInApril  < LocalTime &&
        LastSundayInOctober > LocalTime )
    {
        // Add an hour to compensate for the hour that
        // was subtracted for Daylight Savings Time.
        LocalTime += MinPerHour;
    }
    
    return( LocalTime );
}

/*------------------------------------------------------------
| LocalTimeToLocalStandardTime
|-------------------------------------------------------------
|
| PURPOSE: To convert local time, which may be adjusted for
| Daylight Savings Time, to local standard time.
|
| DESCRIPTION: Removes the Daylight Savings Time adjustment.
| 
| Expects a time in number of minutes since the TradeTime
| origin, in terms of local time rather than GMT as is
| usually the case with TradeTime.
|
| Returns a time in number of minutes since the TradeTime
| origin, in terms of local time rather than GMT as is
| usually the case with TradeTime.
| 
| ***** Only adjusts for U.S. time zones. *****
|
| Only adjusts during Daylight Savings Time Period which
| begins at 2 AM the first Sunday in April and ends at
| 2 AM on the last Sunday in October.
|
| EXAMPLE:  TheTime = LocalTimeToLocalStandardTime( t, z );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.18.96 
------------------------------------------------------------*/
u32
LocalTimeToLocalStandardTime( u32 LocalTime, 
                              u32 ALocalTimeZone )
{
    u32 FirstSundayInApril;
    u32 LastSundayInOctober;
    u32 Year;
    u32 Month; 
    u32 Day; 
    u32 Hour;
    u32 Minute;
    
    // If not one of the continental U.S. time zones,
    // return the local time as is.
    if( ALocalTimeZone < EST || ALocalTimeZone > PST )
    {
        return( LocalTime );
    }

    TradeTimeToCalendarTime( LocalTime,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
    
    // Find 2 AM first Sunday of April in same year as
    // given time.  'DateStringToTradeTime' defaults to 
    // 12 noon.                  
    FirstSundayInApril = 
        DateStringToTradeTime(
            NthWeekDayOfMonth( April, Year, 1, Sunday ) ) -
        ( 10 * MinPerHour );
        

    // Find 2 AM last Sunday of October in same year as
    // given time.                   
    LastSundayInOctober =
            LastWeekDayOfMonth( October, Year, Sunday ) -
            ( 10 * MinPerHour );

    // If during Daylight Savings Time period.
    if( FirstSundayInApril  < LocalTime &&
        LastSundayInOctober > LocalTime )
    {
        // Subtract an hour to compensate for the hour that
        // was added for Daylight Savings Time.
        LocalTime -= MinPerHour;
    }
    
    return( LocalTime );
}
                        
/*------------------------------------------------------------
| LocalTimeToTradeTime
| 
| PURPOSE: To convert local standard calendar time to 
|          TradeTime format.
| 
| DESCRIPTION: Returns the number of minutes since the 
| TradeTime origin.
| 
| EXAMPLE:  t = LocalTimeToTradeTime( 1968, 5, 23, 12, 0, EST );
|           t =  
| NOTE: 
| 
| ASSUMES: Calendar time is in terms of local time.
|          'Year' is > TradeTimeOriginYear.
|          Hours are in 24 hour format 0-23.
| 
| HISTORY: 01.11.96 from 'CalendarTimeToTradeTime'.
|          01.18.96 added 'LocalTimeToLocalStandardTime'.
|          12.19.96 factored out 'CalendarTimeToTradeTime'.
------------------------------------------------------------*/
u32
LocalTimeToTradeTime( u32 Year, 
                      u32 Month, 
                      u32 Day, 
                      u32 Hour,
                      u32 Minute,
                      u32 ALocalTimeZone )
{
    u32 Time;
    
    // Convert the local time to TradeTime as if the locality
    // were Greenwich.
    Time = CalendarTimeToTradeTime( Year, 
                                    Month, 
                                    Day, 
                                    Hour,
                                    Minute );
    
    // Time is now in terms of the local time, unadjusted for 
    // Daylight Savings Time.  Now adjust for Daylight Savings.
    Time = 
        LocalTimeToLocalStandardTime( Time, ALocalTimeZone );

    // Finish with correction from local standard time to GMT.
    Time += ALocalTimeZone * MinPerHour;
    
    return( Time );
} 

/*------------------------------------------------------------
| JulianDay
|-------------------------------------------------------------
| 
| PURPOSE: To compute the Julian Day Number given a date.
| 
| DESCRIPTION: The Julian Day begins at noon on the calendar
| date given.
| 
| EXAMPLE:  j = JulianDay( 5, 23, 1968 );
|           j = 2440000
| NOTE: 
| 
| ASSUMES: Year is >= October 15, 1582, the date the Gregorian
|          calendar was adopted.
| 
| HISTORY: 01.15.95 from 'Numerical Recipes in C', 2nd ed.
|          01.21.98 Changed to unsigned, fixed (s16) casting
|                   error.
------------------------------------------------------------*/
u32
JulianDay( u32 Month, u32 Day, u32 Year )
{
    u32 j;
    u32 Jy, Jm, Ja;
    
    if( Month > February )
    {
        Jy = Year;
        Jm = Month + 1;
    }
    else
    {
        Jy = Year - 1;
        Jm = Month + 13;
    }
    
    j = (u32) ( floor( 365.25  * Jy ) + 
                floor( 30.6001 * Jm ) + Day + 1720995);
    
    Ja = (u32) ( 0.01 * Jy );
    
    j += 2 - Ja + (u32) ( 0.25 * Ja );
    
    return( j );
} 

/*------------------------------------------------------------
| JulianDayToDate
|-------------------------------------------------------------
| 
| PURPOSE: To convert Julian Day Number to a day, month and
|          year.
| 
| DESCRIPTION: Uses the fact that 5/23/68 = Julian Day
|              2440000. 
| 
| EXAMPLE:  j = JulianDayToDate( 5, 23, 1968 );
|           j = 2440000
| NOTE: 
| 
| ASSUMES: Year is > 1968. 
| 
| HISTORY: 01.22.95 
------------------------------------------------------------*/
//void
//JulianDayToDate( s32 JulianDay )
//{
//  s16 Day,Month,Year;
    
/*------------------------------------------------------------
| MinuteOfDayToHourMinute
|-------------------------------------------------------------
|
| PURPOSE: To convert the time of day in minutes to hours and
|          minutes.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  12.27.96 
------------------------------------------------------------*/
void
MinuteOfDayToHourMinute( u32 MinOfDay, u32* Hour, u32* Minute )
{
    *Hour   = MinOfDay / 60;
    *Minute = MinOfDay % 60;
}

/*------------------------------------------------------------
| MMDDToMonthDay
|-------------------------------------------------------------
|
| PURPOSE: To unpack a date number in MMDD format.
|
| DESCRIPTION: Expects a date number, eg. '0701' means July
| first.
|
| EXAMPLE:  
|
|   MMDDToMonthDay( 0701, &Month &Day );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.01.97 from 'YYYYMMDDToYearMonthDay'.
------------------------------------------------------------*/
void
MMDDToMonthDay( s32 MMDD, s32* Month, s32* Day )
{
    *Month = MMDD / 100;
    *Day   = MMDD % 100;
}

/*------------------------------------------------------------
| MonthAtOffset
|-------------------------------------------------------------
|
| PURPOSE: To return the month and year numbers for a month
| at a given offset.
|
| DESCRIPTION: Given a month and year and number of months
| offset, returns the month and year of the month.
|
| EXAMPLE:  
|
|    MonthAtOffset( August,1993, 12, &PMonth, &PYear );
|
|    returns: August, 1994 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.15.96 
------------------------------------------------------------*/
void
MonthAtOffset( s32 Month, s32 Year, s32 Offset, 
               s32* BMonth, s32* BYear )
{
    s32 Months;
    
    // Convert to months.
    Months = Year * 12 + (Month - January);
    
    // Apply the offset.
    Months += Offset;
    
    // Convert back to month and year.
    *BYear  = Months / 12;
    *BMonth = Months % 12 + January;
}   

/*------------------------------------------------------------
| MonthOfYear
|-------------------------------------------------------------
| 
| PURPOSE: To compute the month of the year given a time in
|          TradeTime format.
| 
| DESCRIPTION: January = 1... December = 12.
| 
| EXAMPLE:  m = MonthOfYear( t );
|             
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 01.09.96 from 'DayOfWeek'.
------------------------------------------------------------*/
u32
MonthOfYear( u32 TradeTime )
{
    u32 Year; 
    u32 Month; 
    u32 Day; 
    u32 Hour;
    u32 Minute;
    
    TradeTimeToCalendarTime( TradeTime,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );

    return( Month );
}

/*------------------------------------------------------------
| NextDay
|-------------------------------------------------------------
|
| PURPOSE: To return the date string of the day after the 
| given a date string.
|
| DESCRIPTION: Given a date string in the format:
|
|            mm/dd/yy, eg. "07/01/93"
|
| returns the date string of the next day.
|
| EXAMPLE:  
|
|    n = NextDay("08/01/93");
|
| returns: "08/02/93"
|
| NOTE: 
|
| ASSUMES: Date string is exactly in the form: mm/dd/yy.
|
| HISTORY:  08.19.93 
|           01.15.96 converted from Mathematica.
------------------------------------------------------------*/
s8*
NextDay( s8* Date )
{
    return( DayAtOffset( Date, 1 ) );
}

/*------------------------------------------------------------
| NextDay2
|-------------------------------------------------------------
|
| PURPOSE: To return the date of the day after the given a 
| date.
|
| DESCRIPTION: Given a date in TradeTime format returns the 
| TradeTime of the next day.
|
| EXAMPLE:  
|
|    n = NextDay2(t);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.16.96 from 'NextDay'.
------------------------------------------------------------*/
u32
NextDay2( u32 Date )
{
    return( DayAtOffset2( Date, 1 ) );
}

/*------------------------------------------------------------
| NextMonth
|-------------------------------------------------------------
|
| PURPOSE: To return the month and year numbers for the month
| after to the given one.
|
| DESCRIPTION: Given a month and year, returns the month and
| year of the following month.
|
| EXAMPLE:  
|
|    NextMonth( August,1993, &PMonth, &PYear );
|
|    returns: 9, 1993 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.16.96 from 'PriorMonth'.
------------------------------------------------------------*/
void
NextMonth( u32 Month, u32 Year, u32* NMonth, u32* NYear )
{
    if( Month == December )
    {
        *NMonth = January;
        *NYear = Year + 1;
    }
    else
    {
        *NMonth = Month + 1;
        *NYear  = Year;
    }
}

/*------------------------------------------------------------
| NextYYYYMMDD
|-------------------------------------------------------------
|
| PURPOSE: To return the YYYYMMDD of the day after the 
|          given YYYYMMDD.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.31.96
------------------------------------------------------------*/
u32
NextYYYYMMDD( u32 YYYYMMDD )
{
    u32 n, t;
     
    t = YYYYMMDDToTradeTime( YYYYMMDD ) + MinPerDay;
    
    n = TradeTimeToYYYYMMDD( t );

    return( n );
}

/*------------------------------------------------------------
| Now
|-------------------------------------------------------------
|
| PURPOSE: To get the current time in Mac absolute time
|          format.
|
| DESCRIPTION: Returns the number of seconds since 00:00
| January 1 1904 local time.
| 
| EXAMPLE:  TheTime = Now();
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 09.01.93 
|          09.22.93 added WaitNextEvent
|          10.15.93 changed to access global time variable
------------------------------------------------------------*/
u32
Now()
{
    u32* GlobalTime;
    
    GlobalTime = (u32*) 0x20C; 
        /* see page 223 Inside Mac XRef */
    
    return( GlobalTime[0] );
}

/*------------------------------------------------------------
| NthWeekDayOfMonth
|-------------------------------------------------------------
|
| PURPOSE: To return the date string of the nth given weekday
| of the given month.
|
| DESCRIPTION: 
|
| EXAMPLE:  Date of 3rd Thursday in September 1993.
|
|    d = NthWeekDayOfMonth( September, 1993, 3, Thursday );
|
| NOTE: 
|
| ASSUMES: The sought after day exists.
|
| HISTORY:  08.19.93 
|           09.03.93 fixed comparison error
|           09.03.93 tested ok
|           01.15.96 converted from Mathematica.
------------------------------------------------------------*/
s8*
NthWeekDayOfMonth( u32 Month, u32 Year, u32 Week, u32 WeekDay )
{
    u32 Day;
    
    Day = 1;
    
    // Find the first chosen weekday in the month.
    while( DayOfWeek( Month, Day, Year ) != WeekDay )
    {
        Day++;
    }
    
    // If not in the first week, add the number of weeks
    // needed.
    if( Week > 1 )
    {
        Day += 7 * ( Week - 1 );
    }

    return( YearMonthDayToDateString( Year, Month, Day ) );
}   

/*------------------------------------------------------------
| PrintTradeTimeAsDateString
|-------------------------------------------------------------
|
| PURPOSE: To print out a date string given date in TradeTime
|          format.
|
| DESCRIPTION: Useful for printing a holiday date list.
|
| EXAMPLE:  
|
|   ForEachItem( AList, PrintTradeTimeAsDateString, 0 );
|
| NOTE: 
|
| ASSUMES: Date string is exactly in the form: mm/dd/yy.
|
| HISTORY:  08.19.93 
|           01.15.96 converted from Mathematica.
------------------------------------------------------------*/
void
PrintTradeTimeAsDateString( s8* Time, u32 Dummy )
{
    Dummy = Dummy;
    
    printf( "\t\"%s\",\n", TradeTimeToDateString( (u32) Time ) );
}

/*------------------------------------------------------------
| PriorDay
|-------------------------------------------------------------
|
| PURPOSE: To return the date string of the day before a
| date string.
|
| DESCRIPTION: Given a date string in the format:
|
|            mm/dd/yy, eg. "07/01/93"
|
| returns the date string of the prior day.
|
| EXAMPLE:  
|
|    p = PriorDay("08/01/93");
|
|    returns "07/31/93"
|
| NOTE: 
|
| ASSUMES: Date string is exactly in the form: mm/dd/yy.
|
| HISTORY:  08.19.93 
|           01.15.96 converted from Mathematica.
------------------------------------------------------------*/
s8*
PriorDay( s8* Date )
{
    return( DayAtOffset( Date, -1 ) );
}

/*------------------------------------------------------------
| PriorDay2
|-------------------------------------------------------------
|
| PURPOSE: To return the date of the day before the given a 
| date.
|
| DESCRIPTION: Given a date in TradeTime format returns the 
| TradeTime of the previous day.
|
| EXAMPLE:  
|
|    n = PriorDay2(t);
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.16.96 from 'PriorDay'.
------------------------------------------------------------*/
u32
PriorDay2( u32 Date )
{
    return( DayAtOffset2( Date, -1 ) );
}

/*------------------------------------------------------------
| PriorMonth
|-------------------------------------------------------------
|
| PURPOSE: To return the month and year numbers for the month
| prior to the given one.
|
| DESCRIPTION: Given a month and year, returns the month and
| year of the prior month.
|
| EXAMPLE:  
|
|    PriorMonth( August,1993, &PMonth, &PYear );
|
|    returns: 7, 1993 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  08.19.93 
|           01.15.96 converted from Mathematica.
------------------------------------------------------------*/
void
PriorMonth( u32 Month, u32 Year, u32* PMonth, u32* PYear )
{
    if( Month == January )
    {
        *PMonth = December;
        *PYear = Year - 1;
    }
    else
    {
        *PMonth = Month - 1;
        *PYear  = Year;
    }
}

/*------------------------------------------------------------
| ThirdThursdayOfMonth
|-------------------------------------------------------------
|
| PURPOSE: To return the date string for the third Thursday
| of the given month.
|
| DESCRIPTION: Given a month and year, returns the date string
| of the third Thursday of that month.
|
| EXAMPLE:  
|
|    s = ThirdThursdayOfMonth( July, 1990 );
|
|    returns: "07/19/90"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  08.19.93 
|           09.03.93 tested ok
------------------------------------------------------------*/
s8*
ThirdThursdayOfMonth( u32 Month, u32 Year )
{
    return( NthWeekDayOfMonth( Month, Year, 3, Thursday ) );
}   

/*------------------------------------------------------------
| TimeStringTofl64
| 
| PURPOSE: To convert a time string to an f64.
| 
| DESCRIPTION: Given time string in the format "HH:MM", eg.
| "12:25", returns the hour and minute packed into a f64
| as 'hhmm.'.
| 
| EXAMPLE:  t = TimeStringTof64( "12:25" ); 
|
|           t -> 1225.
|            
| NOTE: 
| 
| ASSUMES: Hours are in 24 hour format 0-23.
| 
| HISTORY: 12.18.96 from 'TimeStringToHourMinute'.
|          12.23.96 change packed format from 'hh.mm' to
|                   'hhmm' to avoid roundoff.
------------------------------------------------------------*/
f64
TimeStringTof64( s8* Time ) 
{
    f64 Hour, Minute, Result;
    
    Hour   = (f64) ( ( (Time[0] - '0') * 10 ) + Time[1] - '0');
    Minute = (f64) ( ( (Time[3] - '0') * 10 ) + Time[4] - '0');
    
    Result = Hour * 100. + Minute;
    
    return( Result );
}

/*------------------------------------------------------------
| TimeStringToHourMinute
| 
| PURPOSE: To convert a time string to hour and minute.
| 
| DESCRIPTION: Given time string in the format "HH:MM", eg.
| "12:25", returns the hour and minute separately as '12'
| and '25'.
| 
| EXAMPLE:  TimeStringToHourMinute( "12:25", &Hour, &Minute ); 
|            
| NOTE: 
| 
| ASSUMES: Hours are in 24 hour format 0-23.
| 
| HISTORY: 01.18.96 
------------------------------------------------------------*/
void
TimeStringToHourMinute( s8* Time, u32* Hour, u32* Minute ) 
{
    *Hour   = 
        (u32) ( ( (Time[0] - '0') * 10 ) + Time[1] - '0' );
        
    *Minute = 
        (u32) ( ( (Time[3] - '0') * 10 ) + Time[4] - '0' );
}

/*------------------------------------------------------------
| TradeTimeToCalendarTime
|-------------------------------------------------------------
| 
| PURPOSE: To convert TradeTime to calendar time.
| 
| DESCRIPTION: Returns year, month, day, hour, minute GMT.
| 
| EXAMPLE:  TradeTimeToCalendarTime( 
|               t, &Year, &Month, &Day, &Hour, &Minute );
|            
| NOTE: 
| 
| ASSUMES: Time is in terms of GMT.
|          'Year' is > TradeTimeOriginYear.
|          Hours are in 24 hour format 0-23.
| 
| HISTORY: 01.22.95 from 'time.txt' in Focus.
------------------------------------------------------------*/
void
TradeTimeToCalendarTime( u32  Time,
                         u32* AtYear, 
                         u32* AtMonth, 
                         u32* AtDay, 
                         u32* AtHour,
                         u32* AtMinute )
{
    u32 FourYearPeriods;
    u32 Year;
    u32 Month;
    u32 Day;
    u32 Hour;
    u32 Minute;
    u32 i;
    
    // Compute how many full four-year periods follow
    // the TradeTime origin.
    FourYearPeriods = Time / MinPerFourYears;
    Year = TradeTimeOriginYear;
    Year += FourYearPeriods << 2;
    
    // Reduce 'Time' by the number of four-year periods.
    Time -= FourYearPeriods * MinPerFourYears;
    
    // Now less than four years of minutes need to be
    // accounted for.  First figure out how many years.
    i = 1;
    while( Time >= MinutesToYearAfterTradeTimeOrigin[i] )
    {
        i++;
    }
    
    // Reduce 'Time' by number of minutes in years.
    Time -= MinutesToYearAfterTradeTimeOrigin[i-1];
    Year += i-1;
    
    // Now less than one year of minutes.  Figure out
    // the month number based on the year.
    if( (Year & 3) == 0 )
    {
        i = 1;
        while( Time >= MinutesToMonthForLeapYear[i] )
        {
            i++;
        }
        
        Time -= MinutesToMonthForLeapYear[i-1];
        Month = i-1;
    }
    else // non-leap year
    {
        i = 1;
        while( Time >= MinutesToMonth[i] )
        {
            i++;
        }
        
        Time -= MinutesToMonth[i-1];
        Month = i-1;
    }
    
    Day = ( Time / MinPerDay ) + 1;
    
    Time -= (Day-1) * MinPerDay;
    
    // Time now holds hours and minutes of day.
    
    Hour = Time / MinPerHour;
    
    Minute = Time % MinPerHour;
    
    // Return result.
    *AtYear   = Year;
    *AtMonth  = Month;
    *AtDay    = Day;
    *AtHour   = Hour;
    *AtMinute = Minute;
} 

/*------------------------------------------------------------
| TradeTimeToDateString
|-------------------------------------------------------------
|
| PURPOSE: To convert a TradeTime to a date string.
|
| DESCRIPTION: Returns a date string in the format mm/dd/yy, 
|              eg. "07/01/93".
|
| EXAMPLE:  
|
|    s = TradeTimeToDateString( t );
|
|    Result>>> "07/01/93"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.15.96
------------------------------------------------------------*/
s8*
TradeTimeToDateString( u32 Time )
{
    u32 Year, Month, Day, Hour, Minute;
    
    
    TradeTimeToCalendarTime( Time,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
                             
    return( YearMonthDayToDateString( Year,  Month, Day) );
}

/*------------------------------------------------------------
| TradeTimeToDateAndTimeString
|-------------------------------------------------------------
|
| PURPOSE: To convert a TradeTime to a date and time string.
|
| DESCRIPTION: Returns a date string in the format 
| 'mm/dd/yy hh:mm', eg. "07/01/93 12:34".
|
| EXAMPLE:  
|
|    s = TradeTimeToDateAndTimeString( t );
|
|    Result>>> "07/01/93 12:34"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.18.96
------------------------------------------------------------*/
s8*
TradeTimeToDateAndTimeString( u32 Time )
{
    u32 Year, Month, Day, Hour, Minute;
    static s8   Date[15];
    
    TradeTimeToCalendarTime( Time,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
                             
    CopyString( YearMonthDayToDateString( Year,  Month, Day),
                Date );
                
    Date[8] = ' ';
             
    CopyString( HourMinuteToTimeString( Hour, Minute ),
                &Date[9] );
                
    return( Date );
}

/*------------------------------------------------------------
| TradeTimeToLocalTime
| 
| PURPOSE: To convert TradeTime to local time.
| 
| DESCRIPTION: Returns the local time equivalent to the given
| TradeTime.
| 
| EXAMPLE:  TradeTimeToLocalTime( 
|               t, LocalTimeZone, 
|               &Year, &Month, &Day, &Hour, &Minute );
|            
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 01.11.96 from 'TradeTimeToCalendarTime'.
|          04.08.96 added Daylight Savings Time correction.
------------------------------------------------------------*/
void
TradeTimeToLocalTime( u32  Time,
                      u32  ALocalTimeZone,
                      u32* AtYear, 
                      u32* AtMonth, 
                      u32* AtDay, 
                      u32* AtHour,
                      u32* AtMinute )
{
    u32 FourYearPeriods;
    u32 Year;
    u32 Month;
    u32 Day;
    u32 Hour;
    u32 Minute;
    u32 i;

    // Begin with correction from GMT to local standard time.
    Time -= ALocalTimeZone * MinPerHour;
    
    // Adjust for Daylight Savings.
    Time = 
        LocalStandardTimeToLocalTime( Time, ALocalTimeZone );
    
    // Compute how many full four-year periods follow
    // the TradeTime origin.
    FourYearPeriods = Time / MinPerFourYears;
    Year = TradeTimeOriginYear;
    Year += FourYearPeriods << 2;
    
    // Reduce 'Time' by the number of four-year periods.
    Time -= FourYearPeriods * MinPerFourYears;
    
    // Now less than four years of minutes need to be
    // accounted for.  First figure out how many years.
    i = 1;
    while( Time >= MinutesToYearAfterTradeTimeOrigin[i] )
    {
        i++;
    }
    
    // Reduce 'Time' by number of minutes in years.
    Time -= MinutesToYearAfterTradeTimeOrigin[i-1];
    Year += i-1;
    
    // Now less than one year of minutes.  Figure out
    // the month number based on the year.
    if( (Year & 3) == 0 )
    {
        i = 1;
        while( Time >= MinutesToMonthForLeapYear[i] )
        {
            i++;
        }
        
        Time -= MinutesToMonthForLeapYear[i-1];
        Month = i-1;
    }
    else // non-leap year
    {
        i = 1;
        while( Time >= MinutesToMonth[i] )
        {
            i++;
        }
        
        Time -= MinutesToMonth[i-1];
        Month = i-1;
    }
    
    Day = ( Time / MinPerDay ) + 1;
    
    Time -= (Day-1) * MinPerDay;
    
    // Time now holds hours and minutes of day.
    
    Hour = Time / MinPerHour;
    
    Minute = Time % MinPerHour;
    
    // Return result.
    *AtYear   = Year;
    *AtMonth  = Month;
    *AtDay    = Day;
    *AtHour   = Hour;
    *AtMinute = Minute;
} 

/*------------------------------------------------------------
| TradeTimeToLocalYYYMMDDAndHHMM
|-------------------------------------------------------------
|
| PURPOSE: To convert a TradeTime to a local date and time in  
|          YYYYMMDD and HHMM formats.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|    s = TradeTimeToLocalYYYMMDDAndHHMM( t, z, &yy, &hh );
|
|    Result>>> '19930701'  '1203'
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  03.27.96 from 'TradeTimeToYYYYMMDDString'.
------------------------------------------------------------*/
void
TradeTimeToLocalYYYMMDDAndHHMM( 
    u32  Time,
    u32  ALocalTimeZone,
    u32* YYYYMMDD,
    u32* HHMM )
{
    u32  Year, Month, Day, Hour, Minute;

    // Convert the TradeTime to local time.
    TradeTimeToLocalTime( Time,
                          ALocalTimeZone,
                          &Year, 
                          &Month, 
                          &Day, 
                          &Hour,
                          &Minute );
        
    *YYYYMMDD = YearMonthDayToYYYYMMDD( Year, Month, Day );

    *HHMM = HourMinuteToHHMM( Hour, Minute );
}

/*------------------------------------------------------------
| TradeTimeToMM_DD_YYYY_hh_mm_ss_GMTString
|-------------------------------------------------------------
|
| PURPOSE: To convert a TradeTime to a date and time string
|          in a format similar to RFC822. 
|
| DESCRIPTION: Returns a 24 byte, including zero terminator, 
| date string in this format:
|
|           MM-DD-YYYY hh:mm:ss GMT 
|
| Examples: "01-23-1998 12:10:00 GMT"
|           "11-05-2001 05:52:00 GMT"
|  
|
| EXAMPLE:  
|            s = TradeTimeToMM_DD_YYYY_hh_mm_ss_GMTString( t );
|
|
| NOTE: The seconds field is always set to zero.
|
| ASSUMES: OK to always set the seconds field to zero.
|
| HISTORY:  10.21.98 From 'TradeTimeToDateAndTimeString'.
------------------------------------------------------------*/
s8*
TradeTimeToMM_DD_YYYY_hh_mm_ss_GMTString( u32 Time )
{
    u32 Year, Month, Day, Hour, Minute;
    static s8   Date[24];
    
    // Unpack the trade time number into year, month, day,
    // hour and minute GMT.
    TradeTimeToCalendarTime( Time,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
    
    // Make a MM-DD-YYYY string and copy it to the local date
    // string buffer.                        
    CopyString( 
        YearMonthDayToMM_DD_YYYYString( Year,  Month, Day),
        Date );
    
    // Set the separator space following the date string.            
    Date[10] = ' ';
    
    // Make a hh:mm string and copy it to the local date
    // string buffer.       
    CopyString( HourMinuteToTimeString( Hour, Minute ),
                &Date[11] );
    
    // Append zeros for seconds.
    Date[16] = ':';
    Date[17] = '0';
    Date[18] = '0';
    
    // Set the separator space following the time string.            
    Date[19] = ' ';
    
    // Append the "GMT" symbol.
    Date[20] = 'G';
    Date[21] = 'M';
    Date[22] = 'T';
    
    // Append the string terminator.
    Date[23] = 0;
    
    // Return address of the static string buffer.
    return( Date );
}

/*------------------------------------------------------------
| TradeTimeToYYYYMMDD
|-------------------------------------------------------------
|
| PURPOSE: To convert a TradeTime to a date in YYYYMMDD 
|          format.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
|    s = TradeTimeToYYYYMMDD( t );
|
|    Result>>> '19930701'
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  03.27.96 from 'TradeTimeToYYYYMMDDString'.
|           01.20.98 Changed 'yyyymmdd' from 'f64' type.
------------------------------------------------------------*/
u32
TradeTimeToYYYYMMDD( u32 Time )
{
    u32 Year, Month, Day, Hour, Minute;
    u32 yyyymmdd;
    
    TradeTimeToCalendarTime( Time,
                             &Year, 
                             &Month, 
                             &Day, 
                             &Hour,
                             &Minute );
                             
    yyyymmdd = Year * 10000 + Month * 100 + Day;
                             
    return( yyyymmdd );
}

/*------------------------------------------------------------
| TradeTimeToYYYYMMDDString
|-------------------------------------------------------------
|
| PURPOSE: To convert a TradeTime to a date string.
|
| DESCRIPTION: Returns a date string in the format YYYYMMDD, 
|              eg. "19930701".
|
| EXAMPLE:  
|
|    s = TradeTimeToYYYYMMDDString( t );
|
|    Result>>> "19930701"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  02.22.96 from 'TradeTimeToDateString'.
|           03.27.96 to use 'TradeTimeToYYYYMMDD'.
------------------------------------------------------------*/
s8*
TradeTimeToYYYYMMDDString( u32 Time )
{
    f64 yyyymmdd;
                             
    yyyymmdd = TradeTimeToYYYYMMDD( Time );
                             
    return( ConvertNumberToString( (Number) yyyymmdd) );
}

/*------------------------------------------------------------
| YearMonthDayToDateString
|-------------------------------------------------------------
|
| PURPOSE: To convert a year, month, day to a date string.
|
| DESCRIPTION: Returns a date string in the format mm/dd/yy, 
|              eg. "07/01/93".
|
| EXAMPLE:  
|
|    s = YearMonthDayToDateString( 1993, 7, 1 );
|
|    Result>>> "07/01/93"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.15.96
------------------------------------------------------------*/
s8*
YearMonthDayToDateString( u32 Year, 
                          u32 Month, 
                          u32 Day )
{
    static s8   Date[9];
    
    if( Month < 10 )
    {
        Date[0] = '0';
        Date[1] = (s8) ( Month + '0' );
    }
    else
    {
        Date[0] = '1';
        Date[1] = (s8) ( Month - 10 + '0' );
    }
        
    Date[2] = '/';
    
    Date[3] = (s8) ( (Day / 10) % 10 + '0' );
    Date[4] = (s8) ( Day % 10 + '0' );
    
    Date[5] = '/';

    if( Year > 1999 )
    {
        Year -= 2000;
    }
    else
    {
        Year -= 1900;
    }
    
    Date[6] = (s8) ( (Year / 10) % 10 + '0' );
    Date[7] = (s8) ( Year % 10 + '0' );
    
    Date[8] = 0;
    
    return( Date );
}

/*------------------------------------------------------------
| YearMonthDayToMM_DD_YYYYString
|-------------------------------------------------------------
|
| PURPOSE: To convert a year, month, day to a date string.
|
| DESCRIPTION: Returns a zero-terminated ASCII date string in 
| the format:
|
|            MM-DD-YYYY
|
| Examples:  01-23-1998
|            11-05-2001
|
| EXAMPLE:  
|
|    s = YearMonthDayToMM_DD_YYYYString( 1993, 7, 1 );
|
|    Result>>> "07-01-1993"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  01.15.96 From 'YearMonthDayToDateString'.
------------------------------------------------------------*/
s8*
YearMonthDayToMM_DD_YYYYString( u32 Year, u32 Month, u32 Day )
{
    static s8   Date[11];
    
    // Calculate the ASCII digits for month of the year.
    if( Month < 10 )
    {
        Date[0] = '0';
        Date[1] = (s8) ( Month + '0' );
    }
    else
    {
        Date[0] = '1';
        Date[1] = (s8) ( Month - 10 + '0' );
    }
    
    // Set the first separator. 
    Date[2] = '-';
    
    // Calculate the ASCII digits for day of the month.
    Date[3] = (s8) ( (Day / 10) + '0' );
    Date[4] = (s8) ( Day % 10   + '0' );
    
    // Set the second separator.    
    Date[5] = '-';
    
    // Calculate the year digits in reverse order.
    Date[9] = (s8) ( Year % 10 + '0' );
    Year /= 10;
    
    Date[8] = (s8) ( Year % 10 + '0' );
    Year /= 10;
    
    Date[7] = (s8) ( Year % 10 + '0' );
    Year /= 10;
    
    Date[6] = (s8) ( Year % 10 + '0' );
    
    // Append the string terminator.
    Date[10] = 0;
    
    // Return the address of the static string buffer.
    return( Date );
}

/*------------------------------------------------------------
| YearMonthDayToYYYYMMDD
|-------------------------------------------------------------
| 
| PURPOSE: To pack year, month and day into a 'YYYYMMDD' 
|          format number.
| 
| DESCRIPTION:  
| 
| EXAMPLE:   
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.25.96 from 'DateStringToYYYYMMDD'.
------------------------------------------------------------*/
u32
YearMonthDayToYYYYMMDD( u32 Year, u32 Month, u32 Day )
{
    u32 YYYYMMDD;
    
    YYYYMMDD = Year * 10000 + Month * 100 + Day;
    
    return( YYYYMMDD );
}

/*------------------------------------------------------------
| YYMMDDToYearMonthDay
|-------------------------------------------------------------
|
| PURPOSE: To unpack a date number in YYMMDD format.
|
| DESCRIPTION: Expects a date number, eg. '930701'.
|
| EXAMPLE:  
|
|   YYMMDDToYearMonthDay( 930701, &Year, &Month &Day );
|
|   returns: Year = 1993, Month = 7, Day = 1 
|
| NOTE: 
|
| ASSUMES: Year is in range 1911 - 2010. 
|
| HISTORY:  01.14.97
------------------------------------------------------------*/
void
YYMMDDToYearMonthDay( u32  YYMMDD, 
                      u32* Year, 
                      u32* Month, 
                      u32* Day )
{
    *Year  = YYMMDD / 10000;
    
    // Convert the two digit year to four digit year.
    if( *Year > 10 ) 
    {
        *Year += 1900;
    }
    else
    {
        *Year += 2000;
    }
    
    *Month = (YYMMDD % 10000) / 100;
    *Day   = YYMMDD % 100;
}

/*------------------------------------------------------------
| YYYYMMDDToTradeTime
|-------------------------------------------------------------
|
| PURPOSE: To convert a date number in YYYYMMDD format to
|          TradeTime format.
|
| DESCRIPTION: Expects a date number, eg. '19930701', and
| returns the equivalent trade time.
|
| EXAMPLE:  
|
|    t = YYYYMMDDToTradeTime( 19930701 );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  03.23.96 
------------------------------------------------------------*/
u32
YYYYMMDDToTradeTime( u32 YYYYMMDD )
{
    u32  Year, Month, Day, Hour, Minute;
    
    Year  = YYYYMMDD / 10000;
    Month = (YYYYMMDD % 10000) / 100;
    Day   = YYYYMMDD % 100;
    
    // Default to 12 noon.
    Hour   = 12;
    Minute = 0;
    
    return( 
        CalendarTimeToTradeTime( 
            Year, Month, Day, Hour, Minute )  
          );
}

/*------------------------------------------------------------
| YYYYMMDDToDateString
|-------------------------------------------------------------
|
| PURPOSE: To convert a date number in YYYYMMDD format to
|          date string format.
|
| DESCRIPTION: Expects a date number, eg. '19930701', and
| returns the equivalent trade time.
|
| EXAMPLE:  
|
|    s = YYYYMMDDToDateString( 19930701 );
|
|    Result>>> "07/01/93"
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  03.27.96 from 'YYYYMMDDToTradeTime'.
------------------------------------------------------------*/
s8*
YYYYMMDDToDateString( u32 YYYYMMDD )
{
    u32  Year, Month, Day;
    
    Year  = YYYYMMDD / 10000;
    Month = (YYYYMMDD % 10000) / 100;
    Day   = YYYYMMDD % 100;
    
    return( YearMonthDayToDateString( Year, Month, Day ) );
}

/*------------------------------------------------------------
| YYYYMMDDToYearMonthDay
|-------------------------------------------------------------
|
| PURPOSE: To unpack a date number in YYYYMMDD format.
|
| DESCRIPTION: Expects a date number, eg. '19930701'.
|
| EXAMPLE:  
|
|   YYYYMMDDToYearMonthDay( 19930701, &Year, &Month &Day );
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY:  03.23.96 
------------------------------------------------------------*/
void
YYYYMMDDToYearMonthDay( s32 YYYYMMDD, 
                        s32* Year, 
                        s32* Month, 
                        s32* Day )
{
    *Year  = YYYYMMDD / 10000;
    *Month = (YYYYMMDD % 10000) / 100;
    *Day   = YYYYMMDD % 100;
}


#ifdef FROM_MATHEMATICA







LastTradingDayFormula =
(* Source: "A Complete Guide To The Futures Markets" by Schwager *)
(* The month implicit in the following is the contract month.
   BasisFunctions expect the following arguments: [ContractMonth_, Year_].
 *)
{ (*      BusinessDayOffset    BasisFunction *)
  {"Cocoa",     -10,        LastBusinessDayOfMonth},
  {"Coffee",    -7,         LastBusinessDayOfMonth},
  {"Copper",    -3,         LastBusinessDayOfMonth},
  {"Corn",      -7,         LastBusinessDayOfMonth},
  (* Source: "NYMEX Energy Complex" *)
  {"CrudeOil",  -2,         BusinessDayPriorTo25thofPriorMonth},
  {"EuroDollar",-1,         BusinessDayPriorTo3rdWednesdayOfMonth},
  {"EuroMark",  -1,         BusinessDayPriorTo3rdWednesdayOfMonth}, (* ? *)
  (* Source: "NYMEX Energy Complex" *)
  {"Gasoline",  0,          LastBusinessDayOfPriorMonth},
  {"Gold",      -3,         LastBusinessDayOfMonth},
  (* Source: "NYMEX Energy Complex" *)
  {"HOil",      0,          LastBusinessDayOfPriorMonth},
  (* Source: "NYMEX Energy Complex" *)
  {"NGas",      -5,         LastBusinessDayOfPriorMonth},
  {"Silver",    -3,         LastBusinessDayOfMonth},
  {"Soybeans",  -7,         LastBusinessDayOfMonth},
  {"SP500",     0,          ThirdThursdayOfMonth},
  {"Sugar",     0,          LastBusinessDayOfPriorMonth},
  {"TBond",     -7,         LastBusinessDayOfMonth},
  {"Wheat",     -7,         LastBusinessDayOfMonth}
};

GetLastTradingDayOffset[ Commodity_ ] := 
      LookUp[LastTradingDayFormula,Commodity][[2]];

GetLastTradingBasisFunction[ Commodity_ ] := 
      LookUp[LastTradingDayFormula,Commodity][[3]];
      
(* ------------------------------------------------------------
 | GetLastTradingDay
 |
 | PURPOSE: To return the date string for the last trading day
 | for of a given contract.
 |
 | DESCRIPTION: Given commodity, month and year, returns the 
 | date string of the last trading day.
 |
 | EXAMPLE:  
 |
 |    GetLastTradingDay["Corn",8,1993];
 |
 |    Out[30] = "08/20/93"
 |
 | NOTE: 
 |
 | ASSUMES: 
 |
 | HISTORY:  08.19.93 
 ------------------------------------------------------------- *)
GetLastTradingDay[ Commodity_, Month_, Year_ ] :=
    Module[ {BasisFunction,BasisDate,Offset},
             
    BasisFunction = GetLastTradingBasisFunction[ Commodity ];
    BasisDate     = BasisFunction[ Month, Year];
    Offset        = GetLastTradingDayOffset[ Commodity ];
    BusinessDayAtOffset[ BasisDate, Offset ]
];


    
    
(* ------------------------------------------------------------
 | PeriodOfDatedSeries
 |
 | PURPOSE: To find the first and last date in a dated series.
 |
 | DESCRIPTION: Returns a time period list in the format:
 |
 |           {"07/01/93","07/31/93"}
 |
 | EXAMPLE:  
 |
 |    Period = PeriodOfDatedSeries[CopperJuly93]
 |
 |    Out[30] = {"07/01/93","07/31/93"}
 |
 | NOTE: 
 |
 | ASSUMES: First field in a series record holds the date.
 |
 | HISTORY:  07.08.93 
 ------------------------------------------------------------- *)
PeriodOfDatedSeries[ DatedSeries_ ]:=
   { DatedSeries[[1,1]], DatedSeries[[-1,1]] };
   
(* ------------------------------------------------------------
 | IntersectingPeriod
 |
 | PURPOSE: To find the time period over which two dated series
 | overlap.
 |
 | DESCRIPTION: Returns a time period list in the format:
 |
 |           {"07/01/93","07/31/93"}
 |
 | EXAMPLE:  
 |
 |    Period = IntersectingPeriod[CopperJuly93,CopperAug93]
 |
 |    Out[30] = {"07/01/93","07/31/93"}
 |
 | NOTE: Returns empty list if there is no intersection.
 |
 | ASSUMES: First field in a series record holds the date.
 |
 | HISTORY:  07.08.93 
 ------------------------------------------------------------- *)
IntersectingPeriod[ DatedSeriesA_, DatedSeriesB_ ] :=
    Module[ {PeriodOfA, PeriodOfB, PeriodOfI, 
             StartsCompared, EndsCompared},
    
    If[ Length[DatedSeriesA] == 0 ||
        Length[DatedSeriesB] == 0, 
        Return[{}]];
        
    PeriodOfA = PeriodOfDatedSeries[DatedSeriesA];
    PeriodOfB = PeriodOfDatedSeries[DatedSeriesB];
    
    PeriodOfI = PeriodOfA;
    
    StartsCompared = 
        CompareDates[ PeriodOfA[[1]], PeriodOfB[[1]] ];
    If[ StartsCompared < 0 ,
        PeriodOfI[[1]] = PeriodOfB[[1]]
      ];

    EndsCompared = 
        CompareDates[ PeriodOfA[[2]], PeriodOfB[[2]] ];
    If[ EndsCompared  > 0,
        PeriodOfI[[2]] = PeriodOfB[[2]]
      ];

    (* If ends before starting then no intersection. *)
    If[ CompareDates[ PeriodOfI[[1]], PeriodOfI[[2]] ] > 0,
        Return[ {} ] 
      ];
      
    Return[ PeriodOfI ];
];

(* ------------------------------------------------------------
 | IndexOfKey
 |
 | PURPOSE: To find the list index of a date in a dated series.
 |
 | DESCRIPTION: Given a two dimensional list like this:
 |
 |          {{7/1/93, 368.50},
 |           {7/2/93, 369.75}...}
 |
 | this procedure locates the record index of a given date in 
 | the list.
 |
 | If the date is not found in the series, the index of the
 | place where the record would be inserted is returned.
 |
 | Returns: { RecordIndex, FoundFlag } 
 |
 |        where FoundFlag is 0 if not found, 1 if found.
 |
 | EXAMPLE:  
 |
 |    FirstDateIndex = 
 |       IndexOfKey[CopperDateAndPrice,"06/21/93"];
 |
 | NOTE: Uses a binary search for speed.
 |
 | ASSUMES: Date is in the form: mm/dd/yy in which leading zeros
 |          are used for single digit months or days.
 |
 |          Dated series in ascending date order.
 |
 | HISTORY:  07.07.93 
 ------------------------------------------------------------- *)
IndexOfKey[ DatedSeries_, DateToFind_ ]:=
    Return[ BinarySearch[ DatedSeries, 
                          1, 
                          CompareDates,  
                          DateToFind] ];

(* ------------------------------------------------------------
 | RecordsInPeriod
 |
 | PURPOSE: To make a list of records from a dated series
 | given beginning and ending dates.
 |
 | DESCRIPTION: Given a two dimensional list like this:
 |
 |          {{7/1/93, 368.50},
 |           {7/2/93, 369.75}...}
 |
 | this procedure creates a list of records like this:
 |
 |          {{7/1/93, 368.50},
 |           {7/2/93, 369.75}...}
 |
 |
 | Date range specification is inclusive.
 |
 | EXAMPLE:  
 |
 |    Result = 
 |       RecordsInPeriod[NearDateAndPrice,{"06/21/93","07/07/93"}];
 |
 | NOTE: This works but is slow.  Try binary search.
 |
 | ASSUMES: Date is in the form: mm/dd/yy in which leading zeros
 |          are used for single digit months or days.
 |
 | HISTORY:  07.07.93 
 ------------------------------------------------------------- *)
RecordsInPeriod[ DatedSeries_, TimePeriod_ ]:=
    Module[ {RecordCount, Result, StartIndex, EndIndex},
    
    RecordCount = Length[DatedSeries];
    (* If no records, return empty list. *)
    If[ RecordCount == 0, Return[ {} ] ];
    
    StartIndex = IndexOfKey[ DatedSeries, TimePeriod[[1]]];
    EndIndex   = IndexOfKey[ DatedSeries, TimePeriod[[2]]];
    
    (* If no records found, return empty list. *)
    If[ StartIndex[[1]] > RecordCount, Return[ {} ] ];
    
    Return[ Take[DatedSeries,
                 {StartIndex[[1]],
                  Min[RecordCount,EndIndex[[1]]]}
                ]
          ];
]; 

(* ------------------------------------------------------------
 | ColumnInPeriod
 |
 | PURPOSE: To make a list of fields from the records of a
 | dated series over a given time period.
 |
 | DESCRIPTION: Given a two dimensional list like this:
 |
 |          {{7/1/93, 368.50...},
 |           {7/2/93, 369.75...}...}
 |
 | this procedure creates a list of numbers like this:
 |
 |          {368.50, 369.75...}
 |
 |
 | Date range specification is inclusive.
 |
 | EXAMPLE:  
 |
 | NearPrice = 
 |   ColumnInPeriod[NearDateAndPrice,
 |                  {"06/21/93","07/07/93"},
 |                  2];
 |
 | NOTE: 
 |
 | ASSUMES: Date is in the form: mm/dd/yy in which leading zeros
 |          are used for single digit months or days.
 |
 | HISTORY:  07.07.93 
 ------------------------------------------------------------- *)
ColumnInPeriod[ DatedSeries_, TimePeriod_, Column_ ]:=
    Module[ {RecordsFound},
    
    RecordsFound = RecordsInPeriod[ DatedSeries, 
                                    TimePeriod ];
                                    
    Return[ ColumnOfFields[ RecordsFound, Column ] ];
    
];



#endif // FROM_MATHEMATICA

