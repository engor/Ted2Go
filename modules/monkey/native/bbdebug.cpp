
#include "bbdebug.h"
#include "bbarray.h"

namespace bbDB{

	bbDBFrame *frames;
	bbDBVar localsBuf[1024];
	bbDBVar *locals=localsBuf;
	int srcpos;
	bool stopper;
	
	void dumpStack(){
	
		bbDBVar *ev=locals;
		
		for( bbDBFrame *f=frames;f;f=f->succ ){

			printf( "%s\n",f->decl );
			
			for( bbDBVar *v=f->locals;v!=ev;++v ){
				char id[64],type[64],value[128];
				strcpy( id,v->ident().c_str() );
				strcpy( type,v->typeName().c_str() );
				strcpy( value,v->getValue().c_str() );
				printf( "   %s:%s=%s\n",id,type,value );
			}

			ev=f->locals;
		}
	}
	
	void stop(){
		dumpStack();
	}
	
	void stopped(){
		dumpStack();
		stopper=false;
	}
	
	bbArray<bbString> *stack(){
	
		int n=0;
		for( bbDBFrame *frame=frames;frame;frame=frame->succ ) ++n;
		
		//TODO: Fix GC issues! Can't have a free local like this in case bbString ctors cause gc sweep!!!!
		bbArray<bbString> *st=bbArray<bbString>::create( n );
		
		int i=0;
		for( bbDBFrame *frame=frames;frame;frame=frame->succ ){
			st->at( i++ )=BB_T( frame->srcFile )+" ["+bbString( frame->srcPos>>12 )+"] "+frame->decl;
		}
		
		return st;
	}
}

bbString bbDBVar::ident()const{
	const char *p=strchr( decl,':' );
	return bbString( decl,p-decl );
}

bbString bbDBVar::typeName()const{
	const char *p=strchr( decl,':' )+1;
	return bbTypeName( p );
}

bbString bbDBVar::getValue()const{
	const char *p=strchr( decl,':' )+1;
	switch( *p ){
	case 'i':return bbString( *(int*)ptr );
	case 'f':return bbString( *(float*)ptr );
	case 's':return "\""+bbString( *(bbString*)ptr )+"\"";
	case 'A':return "[...]";
	}
	
	return "????";
}

