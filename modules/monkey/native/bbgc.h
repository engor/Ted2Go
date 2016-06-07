
#ifndef BB_GC_H
#define BB_GC_H

#include "bbstd.h"
#include "bbtypes.h"
#include "bbmemory.h"

//how much to allocate before a sweep occurs
//#define BBGC_TRIGGER 0
//#define BBGC_TRIGGER 64
//#define BBGC_TRIGGER 256
//#define BBGC_TRIGGER 65536
//#define BBGC_TRIGGER 1*1024*1024
#define BBGC_TRIGGER 4*1024*1024
//#define BBGC_TRIGGER 16*1024*1024

//mark while allocating, slower but smoother...
#define BBGC_INCREMENTAL 1

//reclaim all memory after a sweep, lumpier...
//#define BBGC_AGGRESSIVE 1

//check for use of deleted objects, MUCH leakier...
//#define BBGC_DEBUG 1

#if BBGC_DEBUG
#define BBGC_VALIDATE( P ) \
	if( (P) && (P)->flags==3 ){ \
		printf( "Attempt to use deleted object %p of type '%s'\n",(P),(P)->typeName() ); \
		fflush( stdout ); \
		abort(); \
	}
#else
#define BBGC_VALIDATE( P )
#endif

struct bbGCNode;
struct bbGCFiber;
struct bbGCFrame;
struct bbGCRoot;

namespace bbGC{

	extern bbGCRoot *roots;
	
	extern bbGCNode *markQueue;
	extern bbGCNode *unmarkedList;
	
	extern bbGCFiber *fibers;
	extern bbGCFiber *currentFiber;
	
	extern int markedBit;
	extern int unmarkedBit;
	
	void init();
	
	void collect();
	
	bbGCNode *alloc( size_t size );
}

struct bbGCNode{
	bbGCNode *succ;
	bbGCNode *pred;
	size_t flags;		//0=lonely, 1/2=marked/unmarked; 3=destroyed

	bbGCNode(){
	}
	
	virtual ~bbGCNode(){
	}

	virtual void gcMark(){
	}
	
	virtual void dbEmit(){
	}
	
	virtual const char *typeName(){
		return "bbGCNode";
	}
};

struct bbGCFiber{

	bbGCFiber *succ;
	bbGCFiber *pred;
	bbGCFrame *frames;
	bbGCNode *ctoring;
	
	bbGCFiber():succ( this ),pred( this ),frames( nullptr ),ctoring( nullptr ){
	}
	
	void link(){
		succ=bbGC::fibers;
		pred=bbGC::fibers->pred;
		bbGC::fibers->pred=this;
		pred->succ=this;
	}
	
	void unlink(){
		pred->succ=succ;
		succ->pred=pred;
	}
};

struct bbGCFrame{
	bbGCFrame *succ;
	
	bbGCFrame():succ( bbGC::currentFiber->frames ){
		bbGC::currentFiber->frames=this;
	}
	
	~bbGCFrame(){
		bbGC::currentFiber->frames=succ;
	}

	virtual void gcMark(){
	}
};

struct bbGCRoot{
	bbGCRoot *succ;
	
	bbGCRoot():succ( bbGC::roots ){
		bbGC::roots=this;
	}
	
	virtual void gcMark(){
	}
};

namespace bbGC{
	
	inline void insert( bbGCNode *p,bbGCNode *succ ){
		p->succ=succ;
		p->pred=succ->pred;
		p->pred->succ=p;
		succ->pred=p;
	}

	inline void remove( bbGCNode *p ){	
		p->pred->succ=p->succ;
		p->succ->pred=p->pred;
	}

	inline void enqueue( bbGCNode *p ){
		BBGC_VALIDATE( p )

		if( !p || p->flags!=unmarkedBit ) return;
		
		remove( p );
		p->succ=markQueue;
		markQueue=p;
		
		p->flags=markedBit;
	}
	
	inline void beginCtor( bbGCNode *p ){
		p->succ=currentFiber->ctoring;
		currentFiber->ctoring=p;
	}
	
	inline void endCtor( bbGCNode *p ){
		currentFiber->ctoring=p->succ;
#if BBGC_INCREMENTAL
		p->succ=markQueue;
		markQueue=p;
		p->flags=markedBit;
#else
		p->flags=unmarkedBit;
		insert( p,unmarkedList );
#endif
	}
}

template<class T> struct bbGCVar{

	public:
	
	T *_ptr;
	
	void enqueue(){
#if BBGC_INCREMENTAL
		bbGC::enqueue( dynamic_cast<bbGCNode*>( _ptr ) );
#endif
	}
	
	bbGCVar():_ptr( nullptr ){
	}
	
	bbGCVar( T *p ):_ptr( p ){
		enqueue();
	}
	
	bbGCVar( const bbGCVar &p ):_ptr( p._ptr ){
		enqueue();
	}
	
	bbGCVar &operator=( T *p ){
		_ptr=p;
		enqueue();
		return *this;
	}
	
	bbGCVar &operator=( const bbGCVar &p ){
		_ptr=p._ptr;
		enqueue();
		return *this;
	}
	
	T *get()const{
		return _ptr;
	}
	
	T *operator->()const{
		return _ptr;
	}
	
	operator T*()const{
		return _ptr;
	}
};

template<class T> struct bbGCRootVar : public bbGCVar<T>,public bbGCRoot{
	
	using bbGCVar<T>::_ptr;
	using bbGCVar<T>::enqueue;

	bbGCRootVar(){
	}
	
	bbGCRootVar( T *p ){
		_ptr=p;
		enqueue();
	}
	
	bbGCRootVar( const bbGCVar<T> &p ){
		_ptr=p._ptr;
		enqueue();
	}
	

	bbGCRootVar &operator=( T *p ){
		_ptr=p;
		enqueue();
		return *this;
	}
	
	bbGCRootVar &operator=( const bbGCVar<T> &p ){
		_ptr=p._ptr;
		enqueue();
		return *this;
	}
	
	virtual void gcMark(){
		bbGC::enqueue( dynamic_cast<bbGCNode*>( _ptr ) );
	}
};

inline void bbGCMark( bbBool ){}
inline void bbGCMark( bbByte ){}
inline void bbGCMark( bbUByte ){}
inline void bbGCMark( bbShort ){}
inline void bbGCMark( bbUShort ){}
inline void bbGCMark( bbInt ){}
inline void bbGCMark( bbUInt ){}
inline void bbGCMark( bbLong ){}
inline void bbGCMark( bbULong ){}
inline void bbGCMark( bbFloat ){}
inline void bbGCMark( bbDouble ){}

template<class T> void bbGCMark( const T &t ){
}

template<class T> void bbGCMark( const bbGCVar<T> &v ){
	bbGC::enqueue( dynamic_cast<bbGCNode*>( v._ptr ) );
}

template<class T> void bbGCMark( T *p ){
	bbGC::enqueue( dynamic_cast<bbGCNode*>( p ) );
}

template<class T,class C> T bb_object_cast( const bbGCVar<C> &p ){
	return dynamic_cast<T>( p._ptr );
}

template<class T,class C> T bb_object_cast( C *p ){
	return dynamic_cast<T>( p );
}

#endif
