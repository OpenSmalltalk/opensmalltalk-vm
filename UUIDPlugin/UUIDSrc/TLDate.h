/*------------------------------------------------------------
| TLDate.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for date and time procedures.
|
| DESCRIPTION:  
|
|
| From Encyclopedia of Science and Technology:
|
| "Time - The dimension of the physical universe which,
| at a given place, orders the sequence of events: also, a
| designated instant in this sequence, as the time of day,
| technically known as an epoch."
|
| NOTE: 
|
| HISTORY: 01.2.95 
------------------------------------------------------------*/
    
#ifndef _DATE_H_
#define _DATE_H_

#ifdef __cplusplus
extern "C"
{
#endif

// TimeZone codes:
//
// Use standard time to establish relation between 
// exchanges.  Assume that all exchanges shift uniformly
// with daylight savings time shifts.
//
// Standard Time Zone Code from Encyclopedia of Science and 
// Technology:
//
// Associates time zone code with the number of hours
// that must be added to local time in order to arrive at 
// GMT.

#define GMT 0  // Greenwich Mean Time

#define EST 5  // Eastern Standard Time
#define CST 6  // Central Standard Time
#define MST 7  // Mountain Standard Time
#define PST 8  // Pacific Standard Time

#define ChicagoTimeZone         CST
#define KansasCityTimeZone      CST
#define LondonTimeZone          GMT
#define MinneapolisTimeZone     CST
#define LocalTimeZone           PST // Time zone where I am.
#define NewYorkTimeZone         EST
#define PhiladelphiaTimeZone    EST
#define WinnipegTimeZone        CST

// ---------------------------------------------------------
// 'TradeTime' is a time scale used to identify trades and
// economic measurements.  This is the same as the absolute
// time standard used by the Apple Mac except that units
// are minutes instead of seconds.
//
// TradeTime Format is as follows:
//
// Origin: 00:00 January 1 1904 GMT
// Unit:   Minutes
// Bytes:  4 in binary format, 8 in decimal ASCII.

// Code assumes origin is on year boundary.
#define TradeTimeOriginYear   1904 
#define TradeTimeOriginMonth  1  
#define TradeTimeOriginDay    1 
#define TradeTimeOriginMinute 0

// ---------------------------------------------------------

#define TicksPerSecond   60
#define TicksPerMinute   3600
#define SecondsPerMinute 60
#define SecondsPerHour   3600
#define SecondsPerDay    86400
#define MinPerSecond     (1.0/60.0)
#define MinPerHour       60
#define MinPerDay        1440     
#define MinPerYear       525600 
#define MinPerLeapYear   527040 
#define MinPerFourYears  2103840 
#define DaysPerWeek      7
#define MonthsPerYear    12
#define DaysPerYear         365 // Roughly
#define TradingDaysPerYear  253 // Roughly 52 weekends plus 8 holidays.
#define TradingDayPerCalendarDay ((f64) TradingDaysPerYear/ (f64) DaysPerYear)

// Day of week numbers.
#define Sunday      0
#define Monday      1
#define Tuesday     2
#define Wednesday   3
#define Thursday    4
#define Friday      5
#define Saturday    6

typedef struct
{
    s32 DayNumber;      // 0-6
    s8* NameOfDay;      // "Sunday"
    s8* ShortNameOfDay; // "Sun"
} DayRecord;

// Month of year numbers.
#define January     1
#define February    2
#define March       3
#define April       4
#define May         5
#define June        6
#define July        7
#define August      8
#define September   9
#define October     10
#define November    11
#define December    12

// Month of year letter codes.
#define JanuaryLetter   'F'
#define FebruaryLetter  'G'
#define MarchLetter     'H'
#define AprilLetter     'J'
#define MayLetter       'K'
#define JuneLetter      'M'
#define JulyLetter      'N'
#define AugustLetter    'Q'
#define SeptemberLetter 'U'
#define OctoberLetter   'V'
#define NovemberLetter  'X'
#define DecemberLetter  'Z'

typedef struct
{
    u32 MonthNumber;      // 1-12
    u32 MonthLetter;      // 'F', the contract month codes.
    s8* NameOfMonth;      // "January"
    s8* ShortNameOfMonth; // "Jan"
} MonthRecord;

extern DayRecord    DaysOfWeek[];
extern MonthRecord  MonthsOfYear[];
extern u32          MinutesToMonth[];
extern u32          MinutesToMonthForLeapYear[];
extern u32          DaysInMonth[];
extern u32          DaysInMonthForLeapYear[];

// These dates are regarded as current for purposes of
// estimation.
extern u32  EffectiveTradeTime;
extern u32  EffectiveTradeTimeYYYYMMDD;

void    AddMinutesToHourMinute( s32, u32*, u32* );
u32     CalendarTimeToTradeTime( u32, u32, u32, u32, u32 );
u32     ConvertMonthLetterToMonthNumber( u32 );
u32     CurrentMinuteOfDay();
u32     CurrentMonth();
u32     CurrentYear();
u32     CurrentTradeTime();
u32     CurrentYYYYMMDD();
u32     DayOfWeek( u32, u32, u32 );
u32     DayOfWeek2( u32 );
u32     DayOfWeek3( s8* );
s8*     DayAtOffset( s8*, s32 );
u32     DayAtOffset2( u32, s32 );
u32     DateAndTimeStringToTradeTime( s8* );
u32     DateStringToJulianDay( s8* );
u32     DateStringToTradeTime( s8* );
void    DateStringToYearMonthDay( s8*, u32*, u32*, u32* );
u32     DateStringToYYYYMMDD( s8* );
void    f64ToHourMinute( f64, s32*, s32* );
u32     HourMinuteToHHMM( u32, u32 );
u32     HourMinuteToMinuteOfDay( u32, u32 );
s8*     HourMinuteToTimeString( u32, u32 ); 
u32     IsBusinessDay( s8* );
u32     IsBusinessDay2( u32 );
u32     IsHoliday( s8* );
u32     IsInFirstHalfOfYear( u32 );
u32     IsTradeTimesInSameDay( u32, u32 );
u32     JulianDay( u32, u32, u32 );
u32     LastDayOfMonth( u32, u32 );
u32     LastWeekDayOfMonth( u32, u32, u32 );
u32     LocalStandardTimeToLocalTime( u32, u32 );
u32     LocalTimeToLocalStandardTime( u32, u32 );
u32     LocalTimeToTradeTime( u32, u32, u32, u32, u32, u32 );
void    MinuteOfDayToHourMinute( u32, u32*, u32* );
void    MMDDToMonthDay( s32, s32*, s32* );
void    MonthAtOffset( s32, s32, s32, s32*, s32* );
u32     MonthOfYear( u32 );
s8*     NextDay( s8* );
u32     NextDay2( u32 );
void    NextMonth( u32, u32, u32*, u32*);
u32     NextYYYYMMDD( u32 );
u32     Now();
s8*     NthWeekDayOfMonth( u32, u32, u32, u32 );
void    PrintTradeTimeAsDateString( s8*, u32 );
s8*     PriorDay( s8* );
u32     PriorDay2( u32 );
void    PriorMonth( u32, u32, u32*, u32* );
s8*     ThirdThursdayOfMonth( u32, u32 );
f64     TimeStringTof64( s8* );
void    TimeStringToHourMinute( s8*, u32*, u32* );
void    TradeTimeToCalendarTime( u32, u32*, u32*, u32*, u32*, u32* );
s8*     TradeTimeToDateString( u32 );
s8*     TradeTimeToDateAndTimeString( u32 );
void    TradeTimeToLocalTime( u32, u32, u32*, u32*, u32*, u32*, u32* );
void    TradeTimeToLocalYYYMMDDAndHHMM( u32, u32, u32*, u32* );
s8*     TradeTimeToMM_DD_YYYY_hh_mm_ss_GMTString( u32 );
u32     TradeTimeToYYYYMMDD( u32 );
s8*     TradeTimeToYYYYMMDDString( u32 );
s8*     YearMonthDayToDateString( u32, u32, u32 );
s8*     YearMonthDayToMM_DD_YYYYString( u32, u32, u32 );
u32     YearMonthDayToYYYYMMDD( u32, u32, u32 );
void    YYMMDDToYearMonthDay( u32, u32*, u32*, u32* );
s8*     YYYYMMDDToDateString( u32 );
u32     YYYYMMDDToTradeTime( u32 );
void    YYYYMMDDToYearMonthDay( s32, s32*, s32*, s32* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif
