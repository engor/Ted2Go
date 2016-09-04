
#include "time.h"

#if _WIN32

#include <windows.h>

#else

#include <sys/time.h>

#endif

namespace bbTime{

#if _WIN32

	long start;
	double freq;
	
	double now(){
	
		LARGE_INTEGER icounter;
		QueryPerformanceCounter( &icounter );
		long counter=icounter.QuadPart;
		
		if( !start ){
			start=counter;
			LARGE_INTEGER ifreq;
			QueryPerformanceFrequency( &ifreq );
			freq=double( ifreq.QuadPart );
			return 0;
		}
		
		counter-=start;
		return double( counter )/freq;
	}
	
	void sleep( double seconds ){
	
		Sleep( seconds * 1000 );
	}
	
#else

	long start;
	
	double now(){
	
		timeval tv;
		gettimeofday( &tv,0 );
		long counter=tv.tv_sec*1000000+tv.tv_usec;
		
		if( !start ){
			start=counter;
			return 0;
		}
		
		counter-=start;
		return double( counter )/1000000.0;
	}
	
	void sleep( double seconds ){
	
		sleep( seconds * 1000 );
//		usleep( seconds * 1000000 );
	}
	
	
#endif

}
