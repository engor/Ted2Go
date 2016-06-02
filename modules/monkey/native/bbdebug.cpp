
#include "bbdebug.h"
#include "bbarray.h"

#if _WIN32
#include <windows.h>
#else
#include <signal.h>
#endif

namespace bbDB{

	int nextSeq;
	
	bbDBContext *currentContext;
	
#if _WIN32
	BOOL WINAPI stopHandler( DWORD dwCtrlType ){
		if( dwCtrlType==CTRL_BREAK_EVENT ){
//			printf( "CTRL_BREAK_EVENT\n" );fflush( stdout );
			currentContext->stopped=0;
			return TRUE;
		}
		return FALSE;
	}
#else
	void sighandler( int sig ){
//		printf( "SIGTSTP\n" );fflush( stdout );
		currentContext->stopped=0;
	}
#endif
	
	void init(){
	
		currentContext=new bbDBContext;
		currentContext->init();
		
#if _WIN32
		SetConsoleCtrlHandler( stopHandler,TRUE );
#else		
		signal( SIGTSTP,sighandler );
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

			printf( ">%s;%s;%i;%i\n",f->decl,f->srcFile,f->srcPos,f->seq );
			
			for( bbDBVar *v=f->locals;v!=ev;++v ){
				emitVar( v );
			}

			ev=f->locals;
		}
	}
	
	void emitObject( bbObject *p ){
		if( p ) p->dbEmit();
		printf( "\n" );
		fflush( stdout );
	}
	
	void stop(){

		currentContext->stopped=0;
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
			case '@':emitObject( (bbObject*)strtol( e+1,0,16 ) );continue;
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
