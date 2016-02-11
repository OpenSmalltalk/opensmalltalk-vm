/*
 * Provide a fake environ so that xmalloc.o from libiberty.a links.
 */

char **environ = 0;
