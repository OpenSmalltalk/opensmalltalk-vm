/*------------------------------------------------------------
| TLURL.c
|-------------------------------------------------------------
|
| PURPOSE: To support URL parsing and construction.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 12.12.96 
------------------------------------------------------------*/

#include "TLTarget.h"

#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLURL.h"

/*------------------------------------------------------------
| IsSchemeHTTP
|-------------------------------------------------------------
| 
| PURPOSE: To test if the scheme part of a URL is 'http' or
|          'HTTP'.
|
| DESCRIPTION: Given a buffer holding just the scheme part of
| a URL, test to see if it is 'http' or 'HTTP'.
|
| EXAMPLE: 
|
|   t = IsSchemeHTTP( SchemeBuffer );
|                    
|
| NOTE: 
| 
| ASSUMES:  
| 
| HISTORY: 12.12.96
------------------------------------------------------------*/
u32  
IsSchemeHTTP( s8* AtScheme )
{
    if( ( AtScheme[0] == 'h' || AtScheme[0] == 'H' ) &&
        ( AtScheme[1] == 't' || AtScheme[1] == 'T' ) &&
        ( AtScheme[2] == 't' || AtScheme[2] == 'T' ) &&
        ( AtScheme[3] == 'p' || AtScheme[2] == 'P' ) )
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}


/*------------------------------------------------------------
| ParseDomainNameFromURL
|-------------------------------------------------------------
| 
| PURPOSE: To parse out the domain name part of a URL string.
|
| DESCRIPTION: 
|
| Returns non-zero if the URL is invalid.
|
| EXAMPLE: 
|
|   err = ParseDomainNameFromURL( "http://cnn.com", &Host );
|                    
|
| NOTE:  
| 
| ASSUMES: Enough room in destination buffer for the domain 
|          name.
| 
| HISTORY: 12.17.96
------------------------------------------------------------*/
s32
ParseDomainNameFromURL( s8* Host, s8* URL )
{
    s32 err;
    s8  Scheme[40];
    s8  User[64]; 
    s8  Password[64];
    s8  Port[20];
    s8  Path[1024]; 
    
    err = ParseURL( URL, 
                    Scheme, 
                    User, 
                    Password, 
                    Host,
                    Port,
                    Path );
    return( err );
}

/*------------------------------------------------------------
| ParseURL
|-------------------------------------------------------------
| 
| PURPOSE: To parse a URL string into parts.
|
| DESCRIPTION: Separates the URL string into part in given
| buffers.  Returns zero strings for parts not present.
|
| Returns non-zero if the URL is invalid.
|
| In general, URL's are written as follows:
|
|   <scheme>:<scheme-specific-part>
|
| Some schemes are: 
|
|   ftp         File Transfer protocol
|   http        Hypertext Transfer Protocol
|   gopher      The Gopher protocol
|   mailto      Electronic mail address
|   news        USENET news
|   nntp        USENET news using NNTP access
|   telnet      Reference to interactive sessions
|   wais        Wide Area Information Servers
|   file        Host-specific file names
|   prospero    Prospero Directory Service
|
| The scheme-specific part has a common syntax:
|
|   //<user>:<password>@<host>:<port>/<url-path>
|
| EXAMPLE: ParseURL( "http://www.cnn.com/markets.htm",
|                    &scheme, &user, &password, &host,
|                    &port, &urlpath );
|                    
|
| NOTE: See RFC1738.TXT.
| 
| ASSUMES: Enough room in destination buffers for the parts.
| 
| HISTORY: 12.12.96
------------------------------------------------------------*/
s32
ParseURL( s8* URL, 
          s8* Scheme, 
          s8* User, 
          s8* Password,
          s8* Host,
          s8* Port,
          s8* Path )
{
    s8* AtSchemeSep;
    s8* AtSpecialPart;
    s8* AtAtSign;
    s8* AtUser;
    s8* AtPassword;
    s8* AtHost;
    s8* AtPort;
    s8* AtColon;
    s8* AtSlash;
    s32 SchemeByteCount,PasswordByteCount,UserByteCount;
    s32 HostByteCount;

    // Find the '://' so that the scheme and the scheme-
    // specific parts can be separated.
    AtSchemeSep = FindStringInString( (s8*) "://", URL );
    
    // Return an error if the separator is missing.
    if( AtSchemeSep == 0 ) return( 1 );
    
    // Compute the scheme length.
    SchemeByteCount = AtSchemeSep - URL;
    
    // Copy the scheme to a special buffer.
    CopyBytes( (u8*) URL, (u8*) Scheme, SchemeByteCount );
    
    // Append a zero to terminate the string.
    Scheme[SchemeByteCount] = 0;
    
    // Refer to the substring following the scheme
    // separator.
    AtSpecialPart = &AtSchemeSep[3];
    
    // Look for the user/host delimiter, '@', starting
    // after the scheme separator.
    AtAtSign = FindByteInString( '@', AtSpecialPart );
    
    // If there is an '@', then separate out the user and
    // password.
    if( AtAtSign )
    {
        // Look for the colon that separates the user from
        // the password.
        AtColon = 
            FindByteInString( ':', AtSpecialPart );
    
        // If the ':' is missing or immediately preceeds
        // the '@' or follows the '@', then there is no 
        // password.
        if( AtColon == 0 ||
            AtAtSign - AtColon <= 1 )
        {
            Password[0] = 0;
        }
        else // There is a password.
        {
            AtPassword = AtColon + 1;
            
            PasswordByteCount = AtAtSign - AtPassword;
            
            CopyBytes( (u8*) AtPassword, 
                       (u8*) Password, 
                       PasswordByteCount );
                       
            Password[PasswordByteCount] = 0;
        }
        
        // The user name begins the special part.
        AtUser = AtSpecialPart;

        // Compute the length of the user name.
        if( AtColon && AtColon < AtAtSign )
        {
            UserByteCount = AtColon - AtUser;
        }
        else // No colon before the '@' sign.
        {
            UserByteCount = AtAtSign - AtUser;
        }
        
        // Copy the user name.
        CopyBytes( (u8*) AtUser, (u8*) User, UserByteCount );
                   
        User[UserByteCount] = 0;
        
        // The host follows the '@' if there is one.
        AtHost = AtAtSign + 1;
    }
    else // No '@' sign so host begins the special part.
    {
        Password[0] = 0;
        User[0]     = 0;
        
        AtHost = AtSpecialPart;
    }
    
    // Search for a colon and slash following the start 
    // of the host name.
    AtColon = FindByteInString( ':', AtHost );
    AtSlash = FindByteInString( '/', AtHost );
    
    // If there is a ':' and it occurs before any '/'
    // then there is a port number.
    if( ( AtSlash && AtColon < AtSlash ) ||
        ( AtColon && !AtSlash ) )
    {
        // Copy any contiguous digits following the ':'
        // to the port buffer.
        AtPort = AtColon + 1;
        
        while( IsDigit( *AtPort ) )
        {
            *Port++ = *AtPort++;
        }
        
        *Port = 0;
    }
    
    // Compute the length of the host name.
    if( AtColon && AtColon < AtSlash )
    {
        HostByteCount = AtColon - AtHost;
    }
    else // No colon or slash comes first.
    {
        if( AtSlash )
        {
            HostByteCount = AtSlash - AtHost;
        }
        else // No slash: use rest of string.
        {
            HostByteCount = CountString( AtHost );
        }
    }
    
    // Copy the host name to the buffer.
    CopyBytes( (u8*) AtHost, (u8*) Host, HostByteCount );
    
    Host[HostByteCount] = 0;
    
    // Copy the rest of the URL as the path.
    if( AtSlash )
    {
        CopyString( AtSlash, Path );
    }
    else // No slash so make one as default.
    {
        CopyString( (s8*) "/", Path );
    }
    
    // No error if get here.
    return( 0 );
}
