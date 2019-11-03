/*
 *  sqMacSpellingPlugin.h
 *  SqueakSpelling
 *
 *  Created by John M McIntosh on 14/06/05.
 *
 */

#include <Carbon/Carbon.h>

int		sqSpellingInitialize(void);
void	sqSpellingShutdown(void);
void	sqSpelllingCheckSpellingstartingAtresults(char * data,long startLocation,int length, int *results);
int		sqSpellingGetIgnoredWordListLengthWithTag(int tag);
void	sqSpellingGetIgnoredWordListWithTaginto(int tag, char* string);
int		sqSpelllingGetLanguageLength(void);
void	sqSpelllingGetLanguageInto(char* string);
int		sqSpelllingGetUniqueSpellingTag(void);
int		sqSpelllingGuessForWordLengthwithTag(char * string, int tag);
void	sqSpelllingGuessForWordwithTaginto(char *string, int tag, char *results);
void	sqSpelllingSetIgnoredWordwithTag(char *string, int tag);
void	sqSpelllingSetIgnoredWordswithTag(char *string, int tag);
void	sqSpelllingSetLanguage(char *string);