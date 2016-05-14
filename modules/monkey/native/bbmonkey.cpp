
#include <signal.h>

#if _WIN32

#include <windows.h>

#elif __APPLE__

#include <execinfo.h>
#include <dlfcn.h>
#include <cxxabi.h>

#endif

#include "bbmonkey.h"

namespace{

	void sighandler( int sig  ){
	
		const char *err="Unknown signal";
		switch( sig ){
		case SIGSEGV:err="Memory access violation";break;
		case SIGILL:err="Illegal instruction";
		case SIGFPE:err="Floating point exception";
	#if !_WIN32
		case SIGBUS:err="Bus error";
	#endif	
		}
		
		bbAssert( false,err );
		
		printf( "Caught signal:%s\n",err );
		
#if __APPLE__

		printf( "Stack trace:\n" );	
		
		void *stack[128];

		int frames=backtrace( stack,128 );
		
		for( int i=0;i<frames;++i ){
		
			Dl_info info{};
			
			if( dladdr( stack[i],&info ) ){
			
				if( info.dli_sname ){
				
					char buf[1024];
					size_t length=1024;
					int status=0;
					
					const char *str=abi::__cxa_demangle( info.dli_sname,buf,&length,&status );
					
					if( str ){
						printf( "%s\n",str );
					}else{
						printf( "%s\n",info.dli_sname );
					}
				}
			}
		}
#endif

		fflush( stdout );
		exit( -1 );
	}
}

int bb_argc;
char **bb_argv;

void bbMain();

int main( int argc,char **argv ){

	bb_argc=argc;
	bb_argv=argv;
	
	signal( SIGSEGV,sighandler );
	signal( SIGILL,sighandler );
	signal( SIGFPE,sighandler );

#if !_WIN32
	signal( SIGBUS,sighandler );
#endif

//	printf( "bbMain() : sizeof(bbBool)=%i sizeof(bbByte)=%i sizeof(bbShort)=%i sizeof(bbInt)=%i, sizeof(bbLong)=%i, sizeof(bbChar)=%i sizeof(void*)=%i, sizeof(size_t)=%i\n",(int)sizeof(bbBool),(int)sizeof(bbByte),(int)sizeof(bbShort),(int)sizeof(bbInt),(int)sizeof(bbLong),(int)sizeof(bbChar),(int)sizeof(void*),(int)sizeof(size_t) );
//	fflush( stdout );

	try{
	
		bbGC::init();
		
		bbDB::init();

		{		
			bbDBFrame( "_void()","" );
			
			for( bbInit *init=bbInit::first;init;init=init->succ ){
	//			printf( "Executing initializer '%s'\n",init->info );fflush( stdout );
				init->init();
			}
		}
		
		bbMain();
		
	}catch( bbException *ex ){
	
		printf( "\n***** Uncaught Monkey 2 Exception: %s *****\n\n",ex->message().c_str() );
		
		for( int i=0;i<ex->debugStack()->length();++i ){
			printf( "%s\n",ex->debugStack()->at( i ).c_str() );
		}

	}catch( bbThrowable *t ){
	
		printf( "\n***** Uncaught Monkey 2 Throwable *****\n\n" );

	}catch(...){
	
		printf( "***** Uncaught Native Exception *****\n" );fflush( stdout );
//		throw;
	}
	
	return 0;
}
