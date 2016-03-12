
#ifndef BB_MONKEY_H
#define BB_MONKEY_H

#include "bbstd.h"
#include "bbtypes.h"
#include "bbmemory.h"
#include "bbstring.h"
#include "bbgc.h"
#include "bbfunction.h"
#include "bbarray.h"
#include "bbobject.h"
#include "bbinit.h"
#include "bbdebug.h"

extern int bb_argc;
extern char **bb_argv;

template<class T> int bbCompare( T x,T y ){
	if( y>x ) return -1;
	return x>y;
}

#endif
