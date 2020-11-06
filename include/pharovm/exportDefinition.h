/* pluggable primitive support */
#pragma once

#undef EXPORT
#undef VM_EXPORT

#ifdef _WIN32
# define EXPORT(returnType) __declspec( dllexport ) returnType
# define VM_EXPORT __declspec( dllexport )
#else
# define EXPORT(returnType) returnType
# define VM_EXPORT
#endif
