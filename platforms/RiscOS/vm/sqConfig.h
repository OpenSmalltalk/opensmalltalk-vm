/* Acorn sqConfig.h -- platform identification and configuration */


#if defined(ACORN)
# if defined(SQ_CONFIG_DONE)
#   error configuration conflict
# endif
# define SQ_CONFIG_DONE
#endif
