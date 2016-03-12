
#ifndef BB_DEBUG_H
#define BB_DEBUG_H

#include "bbstring.h"

struct bbRuntimeError{

	bbString msg;
	
	bbRuntimeError( bbString msg ):msg( msg ){
	}
};

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
