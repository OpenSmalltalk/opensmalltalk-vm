#ifndef __sq_SqModule_h
#define __sq_SqModule_h


#define SqModuleVersionMajor	1
#define SqModuleVersionMinor	1
#define SqModuleVersion		((SqModuleVersionMajor << 16) | (SqModuleVersionMinor))

struct SqModule
{
  int		   version;
  char		  *name;
  char		  *type;
  int		   (*parseArgument)(int, char **);
  void		   (*parseEnvironment)(void);
  void		   (*printUsage)(void);
  void		   (*printUsageNotes)(void);
  void		  *(*makeInterface)(void);
  struct SqModule *next;
};

#define SqModuleDefine(TYPE, NAME)		\
struct SqModule TYPE##_##NAME= {		\
  SqModuleVersion,				\
  #NAME,					\
  #TYPE,					\
  TYPE##_parseArgument,				\
  TYPE##_parseEnvironment,			\
  TYPE##_printUsage,				\
  TYPE##_printUsageNotes,			\
  TYPE##_makeInterface,				\
  0						\
}


#endif /* __sq_SqModule_h */
