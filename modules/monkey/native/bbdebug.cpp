
#include "bbdebug.h"
#include "bbarray.h"

#if _WIN32
#include <windows.h>
#include <thread>
#else
#include <signal.h>
#endif

typedef void(*dbEmit_t)(void*);

namespace bbDB{

	int nextSeq;
	
	bbDBContext *currentContext;
	
#if !_WIN32
	void breakHandler( int sig ){
		currentContext->stopped=0x10000000;
	}
#endif

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
				
#ifndef NDEBUG
		error( err );
		exit( 0 );
#endif
		printf( "Caught signal:%s\n",err );
		exit( -1 );
	}
	
	void init(){
	
		currentContext=new bbDBContext;
		currentContext->init();
		
		signal( SIGSEGV,sighandler );
		signal( SIGILL,sighandler );
		signal( SIGFPE,sighandler );

#if _WIN32

		if( HANDLE breakEvent=OpenEvent( EVENT_ALL_ACCESS,false,"MX2_BREAK_EVENT" ) ){
//			printf( "Found BREAK_EVENT!\n" );fflush( stdout );
		    std::thread( [=](){
		    	for( ;; ){
		    		WaitForSingleObject( breakEvent,INFINITE );
//	    			printf( "Break event!\n" );fflush( stdout );
		    		currentContext->stopped=0x10000000;
		    	}
		    } ).detach();
		}
	
#else		
		signal( SIGBUS,sighandler );
		signal( SIGTSTP,breakHandler );
#endif
	}
	
	void emitVar( bbDBVar *v ){
		bbString id=v->name;
		bbString type=v->type->type();
		bbString value=v->type->value( v->var );
		bbString t=id+":"+type+"="+value+"\n";
		printf( t.c_str() );
	}
	
	void emitStack(){
		bbDBVar *ev=currentContext->locals;
		
		for( bbDBFrame *f=currentContext->frames;f;f=f->succ ){

			printf( ">%s;%s;%i;%i\n",f->decl,f->srcFile,f->srcPos>>12,f->seq );
			
			for( bbDBVar *v=f->locals;v!=ev;++v ){
				emitVar( v );
			}

			ev=f->locals;
		}
	}
	
	void stop(){

		currentContext->stopped=0;
	}
	
	void emit( const char *e ){
	
		if( const char *p=strchr( e,':' ) ){
			dbEmit_t dbEmit=(dbEmit_t)( strtol( p+1,0,16 ) );
			dbEmit( (void*)strtol( e,0,16 ) );
		}else{
			bbGCNode *node=(bbGCNode*)strtol( e,0,16 );
			node->dbEmit();
		}
		
		puts( "" );
		fflush( stdout );
	}
	
	void stopped(){

		printf( "{{!DEBUG!}}\n" );
		
		emitStack();

		printf( "\n" );
		fflush( stdout );
		
		for(;;){
		
			char buf[256];
			char *e=fgets( buf,256,stdin );
			if( !e ) exit( -1 );
			
			switch( e[0] ){
			case 's':currentContext->stopped=0;return;
			case 'e':currentContext->stopped=1;return;
			case 'l':currentContext->stopped=-1;return;
			case 'r':currentContext->stopped=-0x10000000;return;
			case '@':emit( e+1 );continue;
			case 'q':exit( 0 );return;
			}
			printf( "Unrecognized debug cmd: %s\n",buf );fflush( stdout );
			exit( -1 );
		}
	}
	
	void error( bbString msg ){
		
		printf( "\n%s\n",msg.c_str() );
		stopped();

	}
	
	bbArray<bbString> *stack(){
	
		int n=0;
		for( bbDBFrame *frame=currentContext->frames;frame;frame=frame->succ ) ++n;
		
		//TODO: Fix GC issues! Can't have a free local like this in case bbString ctors cause gc sweep!!!!
		bbArray<bbString> *st=bbArray<bbString>::create( n );
		
		int i=0;
		for( bbDBFrame *frame=currentContext->frames;frame;frame=frame->succ ){
			st->at( i++ )=BB_T( frame->srcFile )+" ["+bbString( frame->srcPos>>12 )+"] "+frame->decl;
		}
		
		return st;
	}
}

void bbDBContext::init(){
	if( !localsBuf ) localsBuf=new bbDBVar[16384];
	locals=localsBuf;
	frames=nullptr;
	stopped=0;
}

bbDBContext::~bbDBContext(){
	delete[] localsBuf;
}

bbString bbDBValue( bbString *p ){
	bbString t=*p,dd="";
	if( t.length()>100 ){
		t=t.slice( 0,100 );
		dd="...";
	}
	t=t.replace( "\"","~q" );
	t=t.replace( "\n","~n" );
	t=t.replace( "\r","~r" );
	t=t.replace( "\t","~t" );
	return BB_T("\"")+t+"\""+dd;
}
