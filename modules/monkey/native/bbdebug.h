
#ifndef BB_DEBUG_H
#define BB_DEBUG_H

#include "bbstring.h"

struct bbDBFiber;
struct bbDBFrame;
struct bbDBVarType;
struct bbDBVar;

inline bbString bbDBType( void *p ){
	return "Void";
}

inline bbString bbDBValue( void *p ){
	return "?????";
}

inline bbString bbDBType( bbInt *p ){
	return "Int";
}

inline bbString bbDBValue( bbInt *p ){
	return bbString( *p );
}

inline bbString bbDBType( bbFloat *p ){
	return "Float";
}

inline bbString bbDBValue( bbFloat *p ){
	return bbString( *p );
}

inline bbString bbDBType( bbString *p ){
	return "String";
}

inline bbString bbDBValue( bbString *p ){
	return BB_T("\"")+(*p)+"\"";
}

template<class T> bbString bbDBType( T **p ){
	return bbDBType( (void*)0 )+" Ptr";
}

template<class T> bbString bbDBType(){
	return bbDBType( (T*)0 );
}

struct bbDBVarType{
	virtual bbString type()=0;
	virtual bbString value( void *p )=0;
};

template<class T> struct bbDBVarType_t : public bbDBVarType{

	bbString type(){
		return bbDBType( (T*)0 );
	}
	
	bbString value( void *p ){
		return bbDBValue( (T*)p );
	}
	
	static bbDBVarType_t info;
};

template<class T> bbDBVarType_t<T> bbDBVarType_t<T>::info;

struct bbDBVar{

	const char *name;
	bbDBVarType *type;
	void *var;
};

struct bbDBContext{

	bbDBFrame *frames=nullptr;
	bbDBVar *localsBuf=nullptr;
	bbDBVar *locals=nullptr;
	int stopped;

	~bbDBContext();
	
	void init();
};

namespace bbDB{

	extern int nextSeq;

	extern bbDBContext *currentContext;
	
	void init();
	
	void stop();
	
	void stopped();
	
	bbArray<bbString> *stack();
}

struct bbDBFrame{
	bbDBFrame *succ;
	bbDBVar *locals;
	const char *decl;
	const char *srcFile;
	int srcPos;
	int seq;
	
	bbDBFrame( const char *decl,const char *srcFile ):succ( bbDB::currentContext->frames ),locals( bbDB::currentContext->locals ),decl( decl ),srcFile( srcFile ){
		bbDB::currentContext->frames=this;
		--bbDB::currentContext->stopped;
		seq=++bbDB::nextSeq;
	}
	
	~bbDBFrame(){
		++bbDB::nextSeq;
		++bbDB::currentContext->stopped;
		bbDB::currentContext->locals=locals;
		bbDB::currentContext->frames=succ;
	}
};

struct bbDBBlock{
	bbDBVar *locals;
	bbDBBlock():locals( bbDB::currentContext->locals ){
		--bbDB::currentContext->stopped;
	}
	~bbDBBlock(){
		++bbDB::currentContext->stopped;
		bbDB::currentContext->locals=locals;
	}
};

inline void bbDBStmt( int srcPos ){
	bbDB::currentContext->frames->srcPos=srcPos;
	if( bbDB::currentContext->stopped>=0 ) bbDB::stopped();
}

template<class T> void bbDBEmit( const char *name,T *var ){
	bbDBVarType *type=&bbDBVarType_t<T>::info;
	puts( (BB_T( name )+":"+type->type()+"="+type->value( var )).c_str() );
}

template<class T> void bbDBEmit( const char *name,bbGCVar<T> *p ){
	T *var=p->get();return bbDBEmit( name,&var );
}

template<class T> void bbDBLocal ( const char *name,T *var ){
	bbDB::currentContext->locals->name=name;
	bbDB::currentContext->locals->type=&bbDBVarType_t<T>::info;
	bbDB::currentContext->locals->var=var;
	++bbDB::currentContext->locals;
}

#endif
