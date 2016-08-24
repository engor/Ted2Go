
#include "bbmonkey.h"

#include <stdarg.h>

int bb_argc;
char **bb_argv;

void bbMain();

#ifdef __ANDROID__

#include <android/log.h>

void bb_print( bbString str ){
	__android_log_print( ANDROID_LOG_INFO,"MX2","%s",str.c_str() );
}

void bb_printf( const char *fmt,... ){
	va_list args;
	va_start( args,fmt );
	__android_log_vprint( ANDROID_LOG_INFO,"MX2",fmt,args );
	va_end( args );
}

#else

void bb_print( bbString str ){
	puts( str.c_str() );fflush( stdout );
}

void bb_printf( const char *fmt,... ){
	va_list args;
	va_start( args,fmt );
	vprintf( fmt,args );
	va_end( args );
	fflush( stdout );
}

#endif

#ifdef __ANDROID__

extern "C" int SDL_main( int argc,char *argv[] ){

#else

int main( int argc,char **argv ){

#endif

	bb_argc=argc;
	bb_argv=argv;
	
	try{
	
		bbGC::init();
		
		bbDB::init();

		{		
			bbDBFrame( "_void()","" );
			
			for( bbInit *init=bbInit::first;init;init=init->succ ){
				init->init();
			}
		}
		
		bbMain();
	
	}catch( bbThrowable *t ){
	
		printf( "\n***** Uncaught Monkey 2 Throwable *****\n\n" );

	}catch(...){
	
		printf( "***** Uncaught Native Exception *****\n" );fflush( stdout );
		throw;
	}
	
	return 0;
}
