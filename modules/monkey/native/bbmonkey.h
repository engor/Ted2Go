
#ifndef BB_MONKEY_H
#define BB_MONKEY_H

#include "bbstd.h"
#include "bbtypes.h"
#include "bbmemory.h"
#include "bbstring.h"
#include "bbdebug.h"
#include "bbassert.h"
#include "bbgc.h"
#include "bbarray.h"
#include "bbfunction.h"
#include "bbobject.h"
#include "bbinit.h"

extern int bb_argc;
extern char **bb_argv;

template<class T> int bbCompare( T x,T y ){
	if( y>x ) return -1;
	return x>y;
}

#endif
