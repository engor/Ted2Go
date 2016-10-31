
#ifndef BB_MONKEY_H
#define BB_MONKEY_H

#include "bbstd.h"
#include "bbinit.h"
#include "bbtypes.h"
#include "bbassert.h"
#include "bbmemory.h"
#include "bbstring.h"
#include "bbdebug.h"
#include "bbgc.h"
#include "bbarray.h"
#include "bbfunction.h"
#include "bbobject.h"
#include "bbvariant.h"
#include "bbtypeinfo.h"
#include "bbdeclinfo.h"

extern int bb_argc;

extern char **bb_argv;

extern void bb_print( bbString str );

extern void bb_printf( const char *fmt,...);

#endif
