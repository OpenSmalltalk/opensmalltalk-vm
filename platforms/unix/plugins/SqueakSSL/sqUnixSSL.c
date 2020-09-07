/* -*- mode: c; -*- */
/****************************************************************************
 *   PROJECT: SqueakSSL implementation for Unix
 *   FILE:    sqUnixSSL.c
 *   CONTENT: SSL platform functions
 *
 *   AUTHORS: Tobias Pape (topa)
 *               Hasso Plattner Institute, Potsdam, Germany
 *****************************************************************************/

#include "sq.h"
#include "SqueakSSL.h"

#if defined(__OpenBSD__) || defined(SQSSL_LIBRESSL)
#include "sqUnixLibreSSL.inc"
#else
#include "sqUnixOpenSSL.inc"
#endif
