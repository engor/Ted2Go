
#include "bbmemory.h"

#include <cstring>

static size_t malloced;

static void *pools[256>>3];

void *bbMalloc( size_t size ){

	size+=sizeof(size_t);
	
	size=(size+7)&~7;
	
	size_t *p;
/*	
	if( size<256 && pools[size>>3] ){
		p=(size_t*)pools[size>>3];
		pools[size>>3]=*((void**)p);
	}else{
		p=(size_t*)malloc( size );
	}
*/
	p=(size_t*)malloc( size );
	
	memset( p,0,size );
	
	*p=size;

	malloced+=size;
	
//	printf( "Malloced:%p, size=%i, total=%i\n",p,size,malloced );
//	fflush( stdout );

	return p+1;
}

size_t bbMallocSize( const void *q ){
	return *((const size_t*)q-1);
}

void bbFree( void *q ){

	if( !q ) return;

	size_t *p=(size_t*)q-1;
	
	size_t size=*p;
	
	//free( p );
	
	/*
	if( size<256 ){
		*((void**)p)=pools[size>>3];
		pools[size>>3]=p;
	}else{
		free( p );
	}
	*/
	
	malloced-=size;
	
//	printf( "Freed:%p, size=%i, total=%i\n",p,size,malloced );
//	fflush( stdout );
}
