
#ifndef BB_MEMORY_H
#define BB_MEMORY_H

#include "bbtypes.h"

void *bbMalloc( size_t size );

size_t bbMallocSize( const void *p );

void bbFree( void *p );

#endif
