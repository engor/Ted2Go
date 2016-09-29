
#ifndef BBASSERT_H
#define BBASSERT_H

#include "bbtypes.h"

void bbRuntimeError( const bbString &str );

#define bbAssert( COND,MSG ) (void)((COND) || (bbRuntimeError(MSG),0))

#ifdef NDEBUG
#define bbDebugAssert( COND,MSG )
#else
#define bbDebugAssert( COND,MSG ) (void)((COND) || (bbRuntimeError(MSG),0))
#endif

#endif
