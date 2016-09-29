
#include "bbassert.h"
#include "bbdebug.h"

void bbRuntimeError( const bbString &msg ){
	bbDB::error( msg );
}