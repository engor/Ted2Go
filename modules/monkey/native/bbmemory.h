
#ifndef BB_MEMORY_H
#define BB_MEMORY_H

#include "bbtypes.h"

extern size_t bbMallocedBytes;

void *bbMalloc( size_t size );

size_t bbMallocSize( void *p );

void bbFree( void *p );

#endif
