/* sqUnixLocale.c -- support for POSIX locales
 * 
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

/* Author: Ian.Piumarta@inria.fr
 * 
 * Last edited: 2008-11-10 13:25:18 by piumarta on ubuntu.piumarta.com
 */

#include "sq.h"
#include "LocalePlugin.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sys/time.h>
#include <locale.h>
#include <langinfo.h>


#define CODELEN			2	/* 2 for ISO two-letter codes, 3 for UN three-letter codes */


#define DEFAULT_LOCALE		"en_US.ISO8859-1"

#if (CODELEN == 2)
#  define DEFAULT_COUNTRY	"US"
#  define DEFAULT_LANGUAGE	"en"
#elif (CODELEN == 3)
#  define DEFAULT_COUNTRY	"USA"
#  define DEFAULT_LANGUAGE	"eng"
#else
#  error -- CODELEN must be 2 or 3
#endif


static const char *localeString= 0;
static struct lconv *localeConv= 0;


/*** SUNDRY STUPIDITY ***/


#if (CODELEN == 3)

static struct CountryCode
{
  const char *iso, *un;
}
countryCodes[] = {
  /* ISO   UN		   COUNTRY */
  { "AD", "AND" },	/* Andorra */
  { "AE", "ARE" },	/* United Arab Emirates */
  { "AF", "AFG" },	/* Afghanistan */
  { "AG", "ATG" },	/* Antigua and Barbuda */
  { "AI", "AIA" },	/* Anguilla */
  { "AL", "ALB" },	/* Albania */
  { "AM", "ARM" },	/* Armenia */
  { "AN", "ANT" },	/* Netherlands Antilles */
  { "AO", "AGO" },	/* Angola */
  { "AQ", "ATA" },	/* Antarctica */
  { "AR", "ARG" },	/* Argentina */
  { "AS", "ASM" },	/* American Samoa */
  { "AT", "AUT" },	/* Austria */
  { "AU", "AUS" },	/* Australia */
  { "AW", "ABW" },	/* Aruba */
  { "AX", "ALA" },	/* Aland Islands */
  { "AZ", "AZE" },	/* Azerbaijan */
  { "BA", "BIH" },	/* Bosnia and Herzegovina */
  { "BB", "BRB" },	/* Barbados */
  { "BD", "BGD" },	/* Bangladesh */
  { "BE", "BEL" },	/* Belgium */
  { "BF", "BFA" },	/* Burkina Faso */
  { "BG", "BGR" },	/* Bulgaria */
  { "BH", "BHR" },	/* Bahrain */
  { "BI", "BDI" },	/* Burundi */
  { "BJ", "BEN" },	/* Benin */
  { "BM", "BMU" },	/* Bermuda */
  { "BN", "BRN" },	/* Brunei Darussalam */
  { "BO", "BOL" },	/* Bolivia */
  { "BR", "BRA" },	/* Brazil */
  { "BS", "BHS" },	/* Bahamas */
  { "BT", "BTN" },	/* Bhutan */
  { "BV", "BVT" },	/* Bouvet Island */
  { "BW", "BWA" },	/* Botswana */
  { "BY", "BLR" },	/* Belarus */
  { "BZ", "BLZ" },	/* Belize */
  { "CA", "CAN" },	/* Canada */
  { "CC", "CCK" },	/* Cocos (Keeling) Islands */
  { "CD", "COD" },	/* Congo, Democratic Republic of the */
  { "CF", "CAF" },	/* Central African Republic */
  { "CG", "COG" },	/* Congo, Republic of the */
  { "CH", "CHE" },	/* Switzerland */
  { "CI", "CIV" },	/* Cote D'Ivoire */
  { "CK", "COK" },	/* Cook Islands */
  { "CL", "CHL" },	/* Chile */
  { "CM", "CMR" },	/* Cameroon */
  { "CN", "CHN" },	/* China */
  { "CO", "COL" },	/* Colombia */
  { "CR", "CRI" },	/* Costa Rica */
  { "CS", "SCG" },	/* Serbia and Montenegro */
  { "CU", "CUB" },	/* Cuba */
  { "CV", "CPV" },	/* Cape Verde */
  { "CX", "CXR" },	/* Christmas Island */
  { "CY", "CYP" },	/* Cyprus */
  { "CZ", "CZE" },	/* Czech Republic */
  { "DE", "DEU" },	/* Germany */
  { "DJ", "DJI" },	/* Djibouti */
  { "DK", "DNK" },	/* Denmark */
  { "DM", "DMA" },	/* Dominica */
  { "DO", "DOM" },	/* Dominican Republic */
  { "DZ", "DZA" },	/* Algeria */
  { "EC", "ECU" },	/* Ecuador */
  { "EE", "EST" },	/* Estonia */
  { "EG", "EGY" },	/* Egypt */
  { "EH", "ESH" },	/* Western Sahara */
  { "ER", "ERI" },	/* Eritrea */
  { "ES", "ESP" },	/* Spain */
  { "ET", "ETH" },	/* Ethiopia */
  { "FI", "FIN" },	/* Finland */
  { "FJ", "FJI" },	/* Fiji */
  { "FK", "FLK" },	/* Falkland Islands (Islas Malvinas) */
  { "FM", "FSM" },	/* Micronesia, Federated States of */
  { "FO", "FRO" },	/* Faroe Islands */
  { "FR", "FRA" },	/* France */
  { "FX", "FXX" },	/* France, Metropolitan */
  { "GA", "GAB" },	/* Gabon */
  { "GB", "GBR" },	/* United Kingdom */
  { "GD", "GRD" },	/* Grenada */
  { "GE", "GEO" },	/* Georgia */
  { "GF", "GUF" },	/* French Guiana */
  { "GH", "GHA" },	/* Ghana */
  { "GI", "GIB" },	/* Gibraltar */
  { "GL", "GRL" },	/* Greenland */
  { "GM", "GMB" },	/* Gambia */
  { "GN", "GIN" },	/* Guinea */
  { "GP", "GLP" },	/* Guadeloupe */
  { "GQ", "GNQ" },	/* Equatorial Guinea */
  { "GR", "GRC" },	/* Greece */
  { "GS", "SGS" },	/* South Georgia and the South Sandwich Islands */
  { "GT", "GTM" },	/* Guatemala */
  { "GU", "GUM" },	/* Guam */
  { "GW", "GNB" },	/* Guinea-Bissau */
  { "GY", "GUY" },	/* Guyana */
  { "HK", "HKG" },	/* Hong Kong */
  { "HM", "HMD" },	/* Heard Island and McDonald Islands */
  { "HN", "HND" },	/* Honduras */
  { "HR", "HRV" },	/* Croatia */
  { "HT", "HTI" },	/* Haiti */
  { "HU", "HUN" },	/* Hungary */
  { "ID", "IDN" },	/* Indonesia */
  { "IE", "IRL" },	/* Ireland */
  { "IL", "ISR" },	/* Israel */
  { "IN", "IND" },	/* India */
  { "IO", "IOT" },	/* British Indian Ocean Territory */
  { "IQ", "IRQ" },	/* Iraq */
  { "IR", "IRN" },	/* Iran */
  { "IS", "ISL" },	/* Iceland */
  { "IT", "ITA" },	/* Italy */
  { "JM", "JAM" },	/* Jamaica */
  { "JO", "JOR" },	/* Jordan */
  { "JP", "JPN" },	/* Japan */
  { "KE", "KEN" },	/* Kenya */
  { "KG", "KGZ" },	/* Kyrgyzstan */
  { "KH", "KHM" },	/* Cambodia */
  { "KI", "KIR" },	/* Kiribati */
  { "KM", "COM" },	/* Comoros */
  { "KN", "KNA" },	/* Saint Kitts and Nevis */
  { "KP", "PRK" },	/* North Korea */
  { "KR", "KOR" },	/* South Korea */
  { "KW", "KWT" },	/* Kuwait */
  { "KY", "CYM" },	/* Cayman Islands */
  { "KZ", "KAZ" },	/* Kazakstan */
  { "LA", "LAO" },	/* Lao People's Democratic Republic */
  { "LB", "LBN" },	/* Lebanon */
  { "LC", "LCA" },	/* Saint Lucia */
  { "LI", "LIE" },	/* Liechtenstein */
  { "LK", "LKA" },	/* Sri Lanka */
  { "LR", "LBR" },	/* Liberia */
  { "LS", "LSO" },	/* Lesotho */
  { "LT", "LTU" },	/* Lithuania */
  { "LU", "LUX" },	/* Luxembourg */
  { "LV", "LVA" },	/* Latvia */
  { "LY", "LBY" },	/* Libya */
  { "MA", "MAR" },	/* Morocco */
  { "MC", "MCO" },	/* Monaco */
  { "MD", "MDA" },	/* Moldova */
  { "MG", "MDG" },	/* Madagascar */
  { "MH", "MHL" },	/* Marshall Islands */
  { "MK", "MKD" },	/* Macedonia */
  { "ML", "MLI" },	/* Mali */
  { "MM", "MMR" },	/* Burma */
  { "MN", "MNG" },	/* Mongolia */
  { "MO", "MAC" },	/* Macau */
  { "MP", "MNP" },	/* Northern Mariana Islands */
  { "MQ", "MTQ" },	/* Martinique */
  { "MR", "MRT" },	/* Mauritania */
  { "MS", "MSR" },	/* Montserrat */
  { "MT", "MLT" },	/* Malta */
  { "MU", "MUS" },	/* Mauritius */
  { "MV", "MDV" },	/* Maldives */
  { "MW", "MWI" },	/* Malawi */
  { "MX", "MEX" },	/* Mexico */
  { "MY", "MYS" },	/* Malaysia */
  { "MZ", "MOZ" },	/* Mozambique */
  { "NA", "NAM" },	/* Namibia */
  { "NC", "NCL" },	/* New Caledonia */
  { "NE", "NER" },	/* Niger */
  { "NF", "NFK" },	/* Norfolk Island */
  { "NG", "NGA" },	/* Nigeria */
  { "NI", "NIC" },	/* Nicaragua */
  { "NL", "NLD" },	/* Netherlands */
  { "NO", "NOR" },	/* Norway */
  { "NP", "NPL" },	/* Nepal */
  { "NR", "NRU" },	/* Nauru */
  { "NU", "NIU" },	/* Niue */
  { "NZ", "NZL" },	/* New Zealand */
  { "OM", "OMN" },	/* Oman */
  { "PA", "PAN" },	/* Panama */
  { "PE", "PER" },	/* Peru */
  { "PF", "PYF" },	/* French Polynesia */
  { "PG", "PNG" },	/* Papua New Guinea */
  { "PH", "PHL" },	/* Philippines */
  { "PK", "PAK" },	/* Pakistan */
  { "PL", "POL" },	/* Poland */
  { "PM", "SPM" },	/* Saint Pierre and Miquelon */
  { "PN", "PCN" },	/* Pitcairn Island */
  { "PR", "PRI" },	/* Puerto Rico */
  { "PS", "PSE" },	/* Palestinian Territory, Occupied */
  { "PT", "PRT" },	/* Portugal */
  { "PW", "PLW" },	/* Palau */
  { "PY", "PRY" },	/* Paraguay */
  { "QA", "QAT" },	/* Qatar */
  { "RE", "REU" },	/* Reunion */
  { "RO", "ROU" },	/* Romania */
  { "RU", "RUS" },	/* Russia */
  { "RW", "RWA" },	/* Rwanda */
  { "SA", "SAU" },	/* Saudi Arabia */
  { "SB", "SLB" },	/* Solomon Islands */
  { "SC", "SYC" },	/* Seychelles */
  { "SD", "SDN" },	/* Sudan */
  { "SE", "SWE" },	/* Sweden */
  { "SG", "SGP" },	/* Singapore */
  { "SH", "SHN" },	/* Saint Helena */
  { "SI", "SVN" },	/* Slovenia */
  { "SJ", "SJM" },	/* Svalbard */
  { "SK", "SVK" },	/* Slovakia */
  { "SL", "SLE" },	/* Sierra Leone */
  { "SM", "SMR" },	/* San Marino */
  { "SN", "SEN" },	/* Senegal */
  { "SO", "SOM" },	/* Somalia */
  { "SR", "SUR" },	/* Suriname */
  { "ST", "STP" },	/* Sao Tome and Principe */
  { "SV", "SLV" },	/* El Salvador */
  { "SY", "SYR" },	/* Syria */
  { "SZ", "SWZ" },	/* Swaziland */
  { "TC", "TCA" },	/* Turks and Caicos Islands */
  { "TD", "TCD" },	/* Chad */
  { "TF", "ATF" },	/* French Southern and Antarctic Lands */
  { "TG", "TGO" },	/* Togo */
  { "TH", "THA" },	/* Thailand */
  { "TJ", "TJK" },	/* Tajikistan */
  { "TK", "TKL" },	/* Tokelau */
  { "TM", "TKM" },	/* Turkmenistan */
  { "TN", "TUN" },	/* Tunisia */
  { "TO", "TON" },	/* Tonga */
  { "TL", "TLS" },	/* East Timor */
  { "TR", "TUR" },	/* Turkey */
  { "TT", "TTO" },	/* Trinidad and Tobago */
  { "TV", "TUV" },	/* Tuvalu */
  { "TW", "TWN" },	/* Taiwan */
  { "TZ", "TZA" },	/* Tanzania */
  { "UA", "UKR" },	/* Ukraine */
  { "UG", "UGA" },	/* Uganda */
  { "UM", "UMI" },	/* United States Minor Outlying Islands */
  { "US", "USA" },	/* United States of America */
  { "UY", "URY" },	/* Uruguay */
  { "UZ", "UZB" },	/* Uzbekistan */
  { "VA", "VAT" },	/* Holy See (Vatican City) */
  { "VC", "VCT" },	/* Saint Vincent and the Grenadines */
  { "VE", "VEN" },	/* Venezuela */
  { "VG", "VGB" },	/* British Virgin Islands */
  { "VI", "VIR" },	/* Virgin Islands, U.S. */
  { "VN", "VNM" },	/* Vietnam */
  { "VU", "VUT" },	/* Vanuatu */
  { "WF", "WLF" },	/* Wallis and Futuna */
  { "WS", "WSM" },	/* Samoa */
  { "YE", "YEM" },	/* Yemen */
  { "YT", "MYT" },	/* Mayotte */
  { "ZA", "ZAF" },	/* South Africa */
  { "ZM", "ZMB" },	/* Zambia */
  { "ZW", "ZWE" },	/* Zimbabwe */
  { 0, 0 }
};

static struct LanguageCode
{
  const char *iso, *un;
}
languageCodes[] = {
  /* ISO   UN		   LANGUAGE */
  { "ab", "abk" },	/* Abkhazian */
  { "aa", "aar" },	/* Afar */
  { "af", "afr" },	/* Afrikaans */
  { "sq", "alb" },      /* Albanian */
  { "sq", "sqi" },      /* Albanian */
  { "am", "amh" },      /* Amharic */
  { "ar", "ara" },      /* Arabic */
  { "hy", "arm" },      /* Armenian */
  { "hy", "hye" },      /* Armenian */
  { "as", "asm" },      /* Assamese */
  { "ay", "aym" },      /* Aymara */
  { "az", "aze" },      /* Azerbaijani */
  { "ba", "bak" },      /* Bashkir */
  { "eu", "baq" },      /* Basque */
  { "eu", "eus" },      /* Basque */
  { "bn", "ben" },      /* Bengali */
  { "bh", "bih" },      /* Bihari */
  { "bi", "bis" },      /* Bislama */
  { "be", "bre" },      /* Breton */
  { "bg", "bul" },      /* Bulgarian */
  { "my", "bur" },      /* Burmese */
  { "my", "mya" },      /* Burmese */
  { "be", "bel" },      /* Byelorussian */
  { "ca", "cat" },      /* Catalan */
  { "zh", "chi" },      /* Chinese */
  { "zh", "zho" },      /* Chinese */
  { "co", "cos" },      /* Corsican */
  { "cs", "ces" },      /* Czech */
  { "cs", "cze" },      /* Czech */
  { "da", "dan" },      /* Danish */
  { "nl", "dut" },      /* Dutch */
  { "nl", "nla" },      /* Dutch */
  { "dz", "dzo" },      /* Dzongkha */
  { "en", "eng" },      /* English */
  { "eo", "epo" },      /* Esperanto */
  { "et", "est" },      /* Estonian */
  { "fo", "fao" },      /* Faroese */
  { "fj", "fij" },      /* Fijian */
  { "fi", "fin" },      /* Finnish */
  { "fr", "fra" },      /* French */
  { "fr", "fre" },      /* French */
  { "fy", "fry" },      /* Frisian */
  { "gl", "glg" },      /* Gallegan */
  { "ka", "geo" },      /* Georgian */
  { "ka", "kat" },      /* Georgian */
  { "de", "deu" },      /* German */
  { "de", "ger" },      /* German */
  { "el", "ell" },      /* Greek, Modern (1453-) */
  { "el", "gre" },      /* Greek, Modern (1453-) */
  { "kl", "kal" },      /* Greenlandic */
  { "gn", "grn" },      /* Guarani */
  { "gu", "guj" },      /* Gujarati */
  { "ha", "hau" },      /* Hausa */
  { "he", "heb" },      /* Hebrew */
  { "hi", "hin" },      /* Hindi */
  { "hu", "hun" },      /* Hungarian */
  { "is", "ice" },      /* Icelandic */
  { "is", "isl" },      /* Icelandic */
  { "id", "ind" },      /* Indonesian */
  { "ia", "ina" },      /* Interlingua (International Auxiliary language Association) */
  { "iu", "iku" },      /* Inuktitut */
  { "ik", "ipk" },      /* Inupiak */
  { "ga", "gai" },      /* Irish */
  { "ga", "iri" },      /* Irish */
  { "it", "ita" },      /* Italian */
  { "ja", "jpn" },      /* Japanese */
  { "jv", "jav" },      /* Javanese */
  { "jw", "jaw" },      /* Javanese */
  { "kn", "kan" },      /* Kannada */
  { "ks", "kas" },      /* Kashmiri */
  { "kk", "kaz" },      /* Kazakh */
  { "km", "khm" },      /* Khmer */
  { "rw", "kin" },      /* Kinyarwanda */
  { "ky", "kir" },      /* Kirghiz */
  { "ko", "kor" },      /* Korean */
  { "ku", "kur" },      /* Kurdish */
  { "oc", "oci" },      /* Langue d'Oc (post 1500) */
  { "lo", "lao" },      /* Lao */
  { "la", "lat" },      /* Latin */
  { "lv", "lav" },      /* Latvian */
  { "ln", "lin" },      /* Lingala */
  { "lt", "lit" },      /* Lithuanian */
  { "mk", "mac" },      /* Macedonian */
  { "mk", "mak" },      /* Macedonian */
  { "mg", "mlg" },      /* Malagasy */
  { "ms", "may" },      /* Malay */
  { "ms", "msa" },      /* Malay */
  { "ml", "mlt" },      /* Maltese */
  { "mi", "mao" },      /* Maori */
  { "mi", "mri" },      /* Maori */
  { "mr", "mar" },      /* Marathi */
  { "mo", "mol" },      /* Moldavian */
  { "mn", "mon" },      /* Mongolian */
  { "na", "nau" },      /* Nauru */
  { "ne", "nep" },      /* Nepali */
  { "no", "nor" },      /* Norwegian */
  { "or", "ori" },      /* Oriya */
  { "om", "orm" },      /* Oromo */
  { "pa", "pan" },      /* Panjabi */
  { "fa", "fas" },      /* Persian */
  { "fa", "per" },      /* Persian */
  { "pl", "pol" },      /* Polish */
  { "pt", "por" },      /* Portuguese */
  { "ps", "pus" },      /* Pushto */
  { "qu", "que" },      /* Quechua */
  { "rm", "roh" },      /* Rhaeto-Romance */
  { "ro", "ron" },      /* Romanian */
  { "ro", "rum" },      /* Romanian */
  { "rn", "run" },      /* Rundi */
  { "ru", "rus" },      /* Russian */
  { "sm", "smo" },      /* Samoan */
  { "sg", "sag" },      /* Sango */
  { "sa", "san" },      /* Sanskrit */
  { "sh", "scr" },      /* Serbo-Croatian */
  { "sn", "sna" },      /* Shona */
  { "sd", "snd" },      /* Sindhi */
  { "si", "sin" },      /* Singhalese */
  { "ss", "ssw" },      /* Siswant */
  { "sk", "slk" },      /* Slovak */
  { "sk", "slo" },      /* Slovak */
  { "sl", "slv" },      /* Slovenian */
  { "so", "som" },      /* Somali */
  { "st", "sot" },      /* Sotho, Southern */
  { "es", "esl" },      /* Spanish */
  { "es", "spa" },      /* Spanish */
  { "su", "sun" },      /* Sudanese */
  { "sw", "swa" },      /* Swahili */
  { "sv", "sve" },      /* Swedish */
  { "sv", "swe" },      /* Swedish */
  { "tl", "tgl" },      /* Tagalog */
  { "tg", "tgk" },      /* Tajik */
  { "ta", "tam" },      /* Tamil */
  { "tt", "tat" },      /* Tatar */
  { "te", "tel" },      /* Telugu */
  { "th", "tha" },      /* Thai */
  { "bo", "bod" },      /* Tibetan */
  { "bo", "tib" },      /* Tibetan */
  { "ti", "tir" },      /* Tigrinya */
  { "to", "tog" },      /* Tonga (Nyasa) */
  { "ts", "tso" },      /* Tsonga */
  { "tn", "tsn" },      /* Tswana */
  { "tr", "tur" },      /* Turkish */
  { "tk", "tuk" },      /* Turkmen */
  { "tw", "twi" },      /* Twi */
  { "ug", "uig" },      /* Uighur */
  { "uk", "ukr" },      /* Ukrainian */
  { "ur", "urd" },      /* Urdu */
  { "uz", "uzb" },      /* Uzbek */
  { "vi", "vie" },      /* Vietnamese */
  { "vo", "vol" },      /* Volapük */
  { "cy", "cym" },      /* Welsh */
  { "cy", "wel" },      /* Welsh */
  { "wo", "wol" },      /* Wolof */
  { "xh", "xho" },      /* Xhosa */
  { "yi", "yid" },      /* Yiddish */
  { "yo", "yor" },      /* Yoruba */
  { "za", "zha" },      /* Zhuang */
  { "zu", "zul" },      /* Zulu */
  { 0, 0 }
};
  
#endif /* CODELEN == 3 */


/* Answer a canonical, sanitised locale string.
 */
static const char *getlocale(void)
{
  const char *locale= 0;

  /* Use LC_ALL or LANG or current OS locale or some suitable default,
     in that order.  Convert "C" and POSIX locales to the default,
     along with anything else that seems malformed. */

  if ((   !(locale= getenv("LC_ALL")))
      && (!(locale= getenv("LANG")))
      && (!(locale= setlocale(LC_ALL, 0))))
    return DEFAULT_LOCALE;
  else if ((!strcmp(locale, "C")) || (!strcmp(locale, "POSIX"))
	   || strchr(locale, ' ') || strchr(locale, '/'))
    return DEFAULT_LOCALE;

  return locale;
}


/* Answer the 2- or 3-letter country code CC within one of:
 *	_CC
 *	_CC.PP
 *	ll_CC
 *	ll_CC.PP
 */
static const char *getCountry(void)
{
  static const char *country= 0;

  if (!country)
    {
      static char buf[4]= { 0, 0, 0, 0 };
      const char *l, *r;

      if ((l= strrchr(localeString, '_')))
	{
	  ++l;
	  if (!(r= strchr(l, '.'))) r= strchr(l, '\0');
#        if (CODELEN == 2)
	  if (r - l == 2)
	    {
	      strncpy(buf, l, 2);
	      country= buf;
	    }
#        else /* CODELEN == 3 */
	  if (r - l == 3)
	    {
	      strncpy(buf, l, 3);
	      country= buf;
	    }
	  else if (r - l == 2)
	    {
	      struct CountryCode *cc= countryCodes;
	      strncpy(buf, l, 2);
	      while ((!country) && cc->iso)
		if (!strcasecmp(cc->iso, buf))
		  country= cc->un;
		else
		  ++cc;
	    }
#        endif /* CODELEN == 3 */
	}

      if (!country)
	country= DEFAULT_COUNTRY;
    }

  return country;
}


/* Answer the 2- or 3-letter language code ll within one of:
 *	ll
 *	ll.PP
 *	ll_CC
 *	ll_CC.PP
 */
static const char *getLanguage(void)
{
  static const char *language= 0;

  if (!language)
    {
      static char buf[4]= { 0, 0, 0, 0 };

      if (isalpha(localeString[0]) && isalpha(localeString[1])
	  && ((localeString[2] == '.') || (localeString[2] == '_') || !localeString[2]))
	{
	  strncpy(buf, localeString, 2);
#        if (CODELEN == 2)
	  language= buf;
#        elif (CODELEN == 3)
	  {
	    struct LanguageCode *lc= languageCodes;
	    while ((!language) && lc->iso)
	      if (!strcasecmp(lc->iso, buf))
		language= lc->un;
	      else
		++lc;
	  }
#        endif /* CODELEN == 3 */
	}
      if (!language)
	language= DEFAULT_LANGUAGE;
    }
  return language;
}


/* CURRENCY */

/* Answer true if the currency symbol is to be placed in front of the
 * currency value */
sqInt sqLocCurrencyNotation(void)
{
  return localeConv->p_cs_precedes;
}

/* For Cog do *not* copy the trailing null since the VM checks for attempts to
 * overwrite the end of an object, and copying the trailing null into a string
 * does precisely this.
 */
#define safestrcpy(str,source) do { \
	const char *src = (source); \
	int len = strlen(src); \
	strncpy(str,src,len); \
} while (0)

/* Store the currency symbol into the given string.
 */
void sqLocGetCurrencySymbolInto(char *str)
{
  safestrcpy(str, localeConv->currency_symbol);
}

sqInt	sqLocCurrencySymbolSize(void)
{
  return strlen(localeConv->currency_symbol); 
}



/* NUMBERS AND MEASUREMENTS */


/* Answer true if the metric measurements system is to be used.
 */
sqInt sqLocMeasurementMetric(void)
{
  return 1;
}


/* Store the seperator for thousands into the given string.
 */
void sqLocGetDigitGroupingSymbolInto(char *str)
{
  safestrcpy(str, localeConv->thousands_sep);
}


/* Store the decimal point into the given string.
 */
void sqLocGetDecimalSymbolInto(char *str)
{
  safestrcpy(str, localeConv->decimal_point);
}


/* TIME AND DATE */


/* Answer the offset between local time and VM time.  (Despite the
 * function name, this is how it is used.)
 */
sqInt sqLocGetVMOffsetToUTC(void)
{
  return 0;
}

/* Answer the offset to (number of minutes EAST of) GMT.
 */
sqInt sqLocGetTimezoneOffset(void)
{
  /* Match the behaviour of convertToSqueakTime(). */
#ifdef HAVE_TM_GMTOFF
  time_t now= time(0);
  return localtime(&now)->tm_gmtoff / 60;
#else
# ifdef HAVE_TIMEZONE
  extern long timezone;
  extern int daylight;
  return daylight * 60 - timezone / 60;
# else
#  error: cannot determine timezone correction
# endif
#endif
}

/* Answer true if DST is in use.
 */
sqInt sqLocDaylightSavings(void)
{
  time_t now= time(0);
  return localtime(&now)->tm_isdst > 0;
}

/* Answer the number of characters in the long date format.
 */
sqInt sqLocLongDateFormatSize(void)
{
  return strlen(nl_langinfo(D_FMT));
}

/* Store the long date format into the given string.
*/
void sqLocGetLongDateFormatInto(char *str)
{
  safestrcpy(str, nl_langinfo(D_FMT));
}

/* Answer the number of characters in the short date format.
 */
sqInt sqLocShortDateFormatSize(void)
{
  return strlen(nl_langinfo(D_FMT));
}

/* Store the short date format into the given string.
 */
void sqLocGetShortDateFormatInto(char *str)
{
  safestrcpy(str, nl_langinfo(D_FMT));
}

/* Answer the number of characters in the time format.
 */
sqInt sqLocTimeFormatSize(void)
{
  return strlen(nl_langinfo(T_FMT));
}

/* Store the time format into the given string.
 */
void sqLocGetTimeFormatInto(char *str)
{
  safestrcpy(str, nl_langinfo(T_FMT));
}


sqInt sqLocInitialize(void)
{
  if (!(localeString= setlocale(LC_ALL, "")))
    setlocale(LC_ALL, localeString= getlocale());
  localeConv= localeconv();
  return 1;
}


void sqLocGetCountryInto(char * str)
{
  safestrcpy(str, getCountry());
}

void sqLocGetLanguageInto(char * str)
{
  safestrcpy(str, getLanguage());
}

