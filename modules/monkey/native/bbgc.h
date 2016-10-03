
#ifndef BB_GC_H
#define BB_GC_H

#include "bbstd.h"
#include "bbtypes.h"
#include "bbmemory.h"
#include "bbfunction.h"

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
struct bbGCTmp;

namespace bbGC{

	extern bbGCRoot *roots;
	
	extern bbGCTmp *freeTmps;

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
	
	virtual const char *typeName()const{
		return "bbGCNode";
	}
};

struct bbGCFiber{

	bbGCFiber *succ;
	bbGCFiber *pred;
	bbGCFrame *frames;
	bbGCNode *ctoring;
	bbGCTmp *tmps;
	bbFunction<void()> entry;
	
	bbGCFiber():succ( this ),pred( this ),frames( nullptr ),ctoring( nullptr ),tmps( nullptr ){
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

struct bbGCTmp{
	bbGCTmp *succ;
	bbGCNode *node;
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
	
	inline void pushTmp( bbGCNode *p ){
		bbGCTmp *tmp=freeTmps;
		if( !tmp ) tmp=new bbGCTmp;
		tmp->node=p;
		tmp->succ=currentFiber->tmps;
		currentFiber->tmps=tmp;
//		puts( "pushTmp" );
	}
	
	inline void popTmps( int n ){
//		printf( "popTmps %i\n",n );
		while( n-- ){
			bbGCTmp *tmp=currentFiber->tmps;
			currentFiber->tmps=tmp->succ;
			tmp->succ=freeTmps;
			freeTmps=tmp;
		}
	}
	
	template<class T> T *tmp( T *p ){
		pushTmp( p );
		return p;
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

template<class T> void bbGCMark( const T &t ){}

template<class T> void bbGCMark( const bbGCVar<T> &v ){
	bbGC::enqueue( dynamic_cast<bbGCNode*>( v._ptr ) );
}

template<class T> void bbGCMarkPtr( T *p ){
	bbGC::enqueue( dynamic_cast<bbGCNode*>( p ) );
}

#endif
