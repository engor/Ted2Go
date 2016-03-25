
#ifndef BB_OBJECT_H
#define BB_OBJECT_H

#include "bbgc.h"
#include "bbstring.h"

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

struct bbException : public bbThrowable{

	bbException();
	
	bbException( bbString message );
	
	bbString message()const{
		return _message;
	}
	
	bbArray<bbString> *debugStack()const{
		return _debugStack;
	}
	
	private:
	
	bbGCVar<bbArray<bbString>> _debugStack;
	
	bbString _message;
};

struct bbInterface{

	virtual ~bbInterface(){
	}
};

template<class T,class...A> T *bbGCNew( A...a ){
	T *p=new T( a... );
	bbGC::endCtor( p );
	return p;
}

#endif
