
#include "bbmemory.h"

#include <cstring>

namespace{

	void *pools[32];
	
	unsigned char *poolBuf;
	size_t poolBufSize;
}

size_t bbMallocedBytes;

void *bbMalloc( size_t size ){

	size=(size+sizeof( size_t )+7)&~7;
	
	void *p;
	
	if( size<256 ){
		if( pools[size>>3] ){
			p=pools[size>>3];
			pools[size>>3]=*(void**)p;
		}else{
			if( size>poolBufSize ){
				if( poolBufSize ){
					*(void**)poolBuf=pools[poolBufSize>>3];
					pools[poolBufSize>>3]=poolBuf;
				}
				poolBufSize=65536;
				poolBuf=(unsigned char*)::malloc( poolBufSize );
			}
			p=poolBuf;
			poolBuf+=size;
			poolBufSize-=size;
		}
	}else{
		p=::malloc( size );
	}
	
	bbMallocedBytes+=size;

	size_t *q=(size_t*)p;
	*q++=size;
	return q;
}

size_t bbMallocSize( void *p ){

	if( p ) return *((size_t*)p-1);
	
	return 0;
}

void bbFree( void *p ){

	if( !p ) return;
	
	size_t *q=(size_t*)p-1;
	
	size_t size=*q;
	
	bbMallocedBytes-=size;

	if( size<256 ){
		*(void**)q=pools[size>>3];
		pools[size>>3]=q;
	}else{
		::free( q );
	}

}
