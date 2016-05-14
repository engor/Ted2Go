
#include "bbdebug.h"
#include "bbarray.h"

#if _WIN32
#include <windows.h>
#else
#include <signal.h>
#endif

namespace bbDB{

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
	
	void emitStack(){
		bbDBVar *ev=currentContext->locals;
		
		for( bbDBFrame *f=currentContext->frames;f;f=f->succ ){

			printf( ">%s;%s;%i\n",f->decl,f->srcFile,f->srcPos );
			
			for( bbDBVar *v=f->locals;v!=ev;++v ){
				char id[64],type[64],value[128];
				strcpy( id,v->name );
				strcpy( type,v->type->name().c_str() );
				strcpy( value,v->type->value( v->var ).c_str() );
				printf( "%s:%s=%s\n",id,type,value );
			}

			ev=f->locals;
		}
	}
	
	void stop(){

		currentContext->stopped=0;
	}
	
	void stopped(){

		printf( "{{!DEBUG!}}\n" );
		
		emitStack();

		printf( "\n" );
		fflush( stdout );
		
		char buf[256];
		char *e=fgets( buf,256,stdin );
		if( !e ) exit( -1 );
		
		switch( e[0] ){
		case 's':currentContext->stopped=0;return;
		case 'e':currentContext->stopped=1;return;
		case 'l':currentContext->stopped=-1;return;
		case 'r':currentContext->stopped=-0x10000000;return;
		case 'q':
			printf( "Quitting!!!!!\n" );fflush( stdout );
			exit( 0 );
		}
		printf( "???? %s\n",buf );fflush( stdout );
		exit( -1 );
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

template<> bbDBType *bbDBTypeOf( void* ){
	struct type : public bbDBType{
		bbString name(){ return "Void"; }
	};
	static type _type;
	return &_type;
}

template<> bbDBType *bbDBTypeOf( bbInt* ){
	struct type : public bbDBType{
		bbString name(){ return "Int"; }
		bbString value( void *var ){ return *(bbInt*)var; }
	};
	static type _type;
	return &_type;
}

template<> bbDBType *bbDBTypeOf( bbString* ){
	struct type : public bbDBType{
		bbString name(){ return "String"; }
		bbString value( void *var ){ return BB_T("\"")+*(bbString*)var+BB_T( "\"" ); }
	};
	static type _type;
	return &_type;
}
