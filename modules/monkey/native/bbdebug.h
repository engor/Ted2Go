
#ifndef BB_DEBUG_H
#define BB_DEBUG_H

#include "bbstring.h"

struct bbDBFiber;

struct bbDBFrame;

struct bbDBVar;

//subclasses can't add data!
struct bbDBType{
	virtual bbString name(){ return "<?>"; }
	virtual bbString value( void *var ){ return "?????"; }
//	virtual void members( bbDBVar *var,bbDBVar **vars ){}
};

template<class T> bbDBType *bbDBTypeOf( T* ){
	static bbDBType _type;
	return &_type;
}

template<class T> bbDBType *bbDBTypeOf( T** ){
	struct type : public bbDBType{
		bbString name(){ return bbDBTypeOf( (T*)0 )->name()+" Ptr"; }
	};
	static type _type;
	return &_type;
}

template<class T> bbDBType *bbDBTypeOf(){
	return bbDBTypeOf( (T*)0 );
}

struct bbDBVar{
	const char *name;
	bbDBType *type;
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
	
	bbDBFrame( const char *decl,const char *srcFile ):succ( bbDB::currentContext->frames ),locals( bbDB::currentContext->locals ),decl( decl ),srcFile( srcFile ){
		bbDB::currentContext->frames=this;
		--bbDB::currentContext->stopped;
	}
	
	~bbDBFrame(){
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

template<class T> void bbDBLocal( const char *name,T *var ){
	bbDB::currentContext->locals->name=name;
	bbDB::currentContext->locals->type=bbDBTypeOf<T>();
	bbDB::currentContext->locals->var=var;
	++bbDB::currentContext->locals;
}

template<> bbDBType *bbDBTypeOf( void* );

template<> bbDBType *bbDBTypeOf( bbInt* );

template<> bbDBType *bbDBTypeOf( bbString* );

#endif
