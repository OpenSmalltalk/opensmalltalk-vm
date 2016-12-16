/*
 * A set of definitions for C source code control systems, to provide accurate
 * and definitive version information to the VM.
 *
 * Currently instantiated only for Subversion.  Please add definitions for
 * other repositories as appropriate.
 *
 * I guess a good way to manage this is to edit the below define list to select
 * appropriate the repository type, and then that's the extent of the fork.
 *
 * Eliot Miranda
 * eliot.miranda@gmail.com
 * 15 July 2011
 */

#define SCCS 0
#define RCS 0
#define CVS 0
#define SUBVERSION 0
#define BAZAAR 0
#define MERCURIAL 0
#define GIT 1

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "../plugins/sqPluginsSCCSVersion.h"

#if SUBVERSION
# define PREFIX "r"
static char SvnRawRevisionString[] = "$Rev$";
# define REV_START (SvnRawRevisionString + 6)

static char SvnRawRevisionDate[] = "$Date$";
# define DATE_START (SvnRawRevisionDate + 7)

static char SvnRawRepositoryURL[] = "$URL$";
# define URL_START (SvnRawRepositoryURL + 6)

static char *
revisionAsString()
{
	char *maybe_space = strchr(REV_START,' ');
	if (maybe_space)
		*maybe_space = 0;
	return REV_START;
}

static char *
revisionDateAsString()
{
	char *maybe_paren = strchr(DATE_START,'(');
	if (maybe_paren)
		*(maybe_paren - 1) = 0;
	return DATE_START;
}

static char *
repositoryURL()
{
	char *maybe_platforms = strstr(URL_START, "/platforms");
	if (maybe_platforms)
		*maybe_platforms = 0;
	return URL_START;
}
# undef REV_START
# undef URL_START
#elif GIT
# define PREFIX ""
static char GitRawRevisionString[] = "$Rev$";
# define REV_START (GitRawRevisionString + 6)

static char GitRawRevisionDate[] = "$Date$";
# define DATE_START (GitRawRevisionDate + 7)

static char GitRawRepositoryURL[] = "$URL$";
# define URL_START (GitRawRepositoryURL + 6)

static char *
revisionAsString()
{
	char *maybe_space = strchr(REV_START,' ');
	if (maybe_space)
		*maybe_space = 0;
	return REV_START;
}

static char *
revisionDateAsString()
{
	char *maybe_paren = strchr(DATE_START,'(');
	if (maybe_paren)
		*(maybe_paren - 1) = 0;
	return DATE_START;
}

static char *
repositoryURL()
{
	char *maybe_platforms = strstr(URL_START, "/platforms");
	if (maybe_platforms)
		*maybe_platforms = 0;
	return URL_START;
}
# undef REV_START
# undef URL_START
#else /* SUBVERSION */
# define PREFIX ""
char *
revisionAsString() { return "?"; }

static char *
repositoryURL() { return "unknown"; }
#endif /* SUBVERSION */

static char *sourceVersion = 0;

static char *
sourceVersionString(char separator)
{
	if (!sourceVersion) {
#if 1 /* a) mingw32 doesn't have asprintf and b) on Mac OS it segfaults. */
		char *fmt = "VM: " PREFIX "%s %s Date: %s%cPlugins: " PREFIX "%s %s";
		int len = strlen(fmt)
				+ strlen(revisionAsString())
				+ strlen(repositoryURL())
				+ strlen(revisionDateAsString())
				+ strlen(pluginsRevisionAsString())
				+ strlen(pluginsRepositoryURL());
		sourceVersion = malloc(len);
		snprintf(sourceVersion, len, fmt,
				revisionAsString(), repositoryURL(), revisionDateAsString(),
				separator,
				pluginsRevisionAsString(), pluginsRepositoryURL());
#else
		asprintf(&sourceVersion,
				"VM: " PREFIX "%s %s Date: %s%cPlugins: " PREFIX "%s %s",
				revisionAsString(), repositoryURL(), revisionDateAsString(),
				separator,
				pluginsRevisionAsString(), pluginsRepositoryURL());
#endif
	}
	return sourceVersion;
}


#if VERSION_PROGRAM
# include "sq.h"

#if SistaVM
# define NICKNAME "Sista"
#elif COGVM
# define NICKNAME "Cog"
#elif STACKVM
# define NICKNAME "Stack"
#else
# define NICKNAME "Context"
#endif

#if SPURVM
# define OBJMEM "Spur"
#else
# define OBJMEM "V3"
#endif

int argc = 0;
char **argv = 0;
int justPrintTags = 0;

/* printit allows that with no arguments print all key/value pairs
 * and with one argument print the value of a particular key, or with
 * the one argument TAGS to print all keys.
 */
int
printit(const char *what)
{
	if (justPrintTags) {
		printf("%s ", what);
		return 0;
	}
	if (argc == 1) {
		printf("%s: ", what);
		return 1;
	}
	return argc == 2 && !strcmp(argv[1], what);
}

int
main(int _argc, char **_argv)
{
	char vm_version[] = VM_VERSION;

	argc = _argc;
	argv = _argv;

	justPrintTags = argc == 2 && !strcmp(argv[1], "TAGS");

	if (printit("VM_NICKNAME"))
		printf("%s\n", NICKNAME " " OBJMEM " VM");
	if (printit("VIRTUAL_MACHINE_NICKNAME"))
		printf("%s\n", NICKNAME " " OBJMEM " Virtual Machine");
	if (printit("VM_MONIKER"))
		printf("%s\n", NICKNAME OBJMEM "VM");
	if (printit("VM_VERSION"))
		printf("%s\n", vm_version);
	if (printit("VM_MAJOR"))
		printf("%.*s\n", (int)(strchr(vm_version,'.') - vm_version), vm_version);
	if (printit("VM_MINOR"))
		printf("%s\n", strchr(vm_version,'.') + 1);
	if (printit("VM_RELEASE"))
		printf("%s\n", revisionAsString());
	if (printit("VERSION_TAG"))
		printf("%s-%s\n", vm_version, revisionAsString());
	if (printit("VERSION_NUMBER"))
		printf("%s.%s\n", vm_version, revisionAsString());
	if (printit("NICKNAME"))
		printf("%s\n", NICKNAME);
	if (printit("OBJMEM"))
		printf("%s\n", OBJMEM);
	if (printit("DEFAULT_IMAGE_NAME"))
		printf("%s\n", DEFAULT_IMAGE_NAME);

	if (justPrintTags)
		printf("\n");

	return 0;
}
#endif /* VERSION_PROGRAM */
