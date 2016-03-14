
#ifndef BB_ASSERT_H
#define BB_ASSERT_H

#include "bbobject.h"

inline void bbAssert( bool cond ){
	if( !cond ) throw new bbRuntimeError( "Assert failed" );
}

inline void bbAssert( bool cond,bbString msg ){
	if( !cond ) throw new bbRuntimeError( msg );
}

inline void bbDebugAssert( bool cond ){
	if( !cond ) throw new bbRuntimeError( "Assert failed" );
}

inline void bbDebugAssert( bool cond,bbString msg ){
	if( !cond ) throw new bbRuntimeError( msg );
}

#endif
