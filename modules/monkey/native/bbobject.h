
#ifndef BB_OBJECT_H
#define BB_OBJECT_H

#include "bbgc.h"

class bbObject : public bbGCNode{
public:
	bbObject(){
		bbGC::beginCtor( this );
	}
	
	virtual ~bbObject(){
	}
	
	virtual const char *typeName(){
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

class bbInterface{
public:
	virtual ~bbInterface(){
	}
};

template<class T,class...A> T *bbGCNew( A...a ){
	T *p=new T( a... );
	bbGC::endCtor( p );
	return p;
}

#endif
