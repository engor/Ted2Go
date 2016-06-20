
#ifndef BB_OBJECT_H
#define BB_OBJECT_H

#include "bbgc.h"
#include "bbstring.h"
#include "bbdebug.h"

struct bbObject : public bbGCNode{

	bbObject(){
		bbGC::beginCtor( this );
	}
	
	virtual ~bbObject(){
	}
	
	virtual const char *typeName()const{
		return "monkey.Object";
	}
	
	void *operator new( size_t size ){
		return bbGC::alloc( size );
	}
	
	//NOTE! We need this in case ctor throws an exception. delete never otherwise called...
	//
	void operator delete( void *p ){
		bbGC::endCtor( (bbObject*)(p) );
	}
};

struct bbThrowable : public bbObject{
};

struct bbInterface{

	virtual ~bbInterface(){
	}
};

struct bbNullCtor_t{
};

extern bbNullCtor_t bbNullCtor;

template<class T,class...A> T *bbGCNew( A...a ){
	T *p=new T( a... );
	bbGC::endCtor( p );
	return p;
}

inline bbDBAssertSelf( void *p ){
	bbDebugAssert( p,"'Self' is null" );
}

inline bbString bbDBObjectValue( bbObject *p ){
	char buf[64];
	sprintf( buf,"@%p",p );
	return buf;
}

inline bbString bbDBInterfaceValue( bbInterface *p ){
	return bbDBObjectValue( dynamic_cast<bbObject*>( p ) );
}

template<class T> bbString bbDBStructValue( T *p ){
	char buf[64];
	sprintf( buf,"@%p:%p",p,&T::dbEmit );
	return buf;
}

inline bbString bbDBType( bbObject **p ){
	return "Object";
}

inline bbString bbDBValue( bbObject **p ){
	return bbDBObjectValue( *p );
}

#endif
