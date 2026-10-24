/*
 * A set of definitions for C source code control systems, to provide accurate
 * and definitive version information to the VM.  This file identifies the
 * platform plugin code, which is shared between Cog and the trunk interpreter.
 * It is included by platforms/Cross/vm/sqSCCSVersion.h.
 *
 * Currently instantiated only for Subversion.  Please add definitions for
 * other repositories as appropriate.
 */

#if SUBVERSION
static char SvnRawPluginsRevisionString[] = "$Rev: 202610242158-oil-m5-base $";
# define PLUGINS_REV_START (SvnRawPluginsRevisionString + 6)

static char SvnRawPluginsRepositoryURL[] = "$URL: clementbera@clementbera.c.googlers.com:.gemini/jetski/brain/7ce39ff8-2a06-42fe-96ff-a75b88c4fff2/scratch/osvm $";
# define URL_START (SvnRawPluginsRepositoryURL + 6)

static char *
pluginsRevisionAsString()
{
	char *maybe_space = strchr(PLUGINS_REV_START,' ');
	if (maybe_space)
		*maybe_space = 0;
	return PLUGINS_REV_START;
}

static char *
pluginsRepositoryURL()
{
	char *maybe_sqplugins = strstr(URL_START, "/sqPlugins");
	if (maybe_sqplugins)
		*maybe_sqplugins = 0;
	return URL_START;
}
# undef PLUGINS_REV_START
# undef URL_START
#elif GIT
static char GitRawPluginsRevisionString[] = "$Rev: 202610242158-oil-m5-base $";
# define PLUGINS_REV_START (GitRawPluginsRevisionString + 6)

static char GitRawPluginsRepositoryURL[] = "$URL: clementbera@clementbera.c.googlers.com:.gemini/jetski/brain/7ce39ff8-2a06-42fe-96ff-a75b88c4fff2/scratch/osvm $";
# define URL_START (GitRawPluginsRepositoryURL + 6)

static char *
pluginsRevisionAsString()
{
	char *maybe_space = strchr(PLUGINS_REV_START,' ');
	if (maybe_space)
		*maybe_space = 0;
	return PLUGINS_REV_START;
}

static char *
pluginsRepositoryURL()
{
	char *maybe_sqplugins = strchr(URL_START, ' ');
	if (maybe_sqplugins)
		*maybe_sqplugins = 0;
	return URL_START;
}
# undef PLUGINS_REV_START
# undef URL_START
#else /* SUBVERSION */
static char *
pluginsRevisionAsString() { return "?"; }

static char *
pluginsRepositoryURL() { return "unknown"; }
#endif /* SUBVERSION */
