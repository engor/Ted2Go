
//v1001

#include <utility>

#include "bbgc.h"

// For testing only...
// #define BBGC_DISABLED 1

//For future ref...
#if BB_THREADED

//fast but unpredictable
//#define BBGC_LOCK while( bbGC::spinlock.test_and_set( std::memory_order_acquire ) ) std::this_thread::yield();
//#define BBGC_UNLOCK bbGC::spinlock.clear( std::memory_order_release );

//pretty slow...
//#define BBGC_LOCK bbGC::mutex.lock();
//#define BBGC_UNLOCK bbGC::mutex.unlock();

//better...a 'Benaphore' apparently...
#define BBGC_LOCK \
	if( ++bbGC::locks>1 ){ \
		std::unique_lock<std::mutex> lock( bbGC::mutex ); \
		bbGC::cond_var.wait( lock,[]{ return bbGC::sem_count>0;} ); \
		--bbGC::sem_count; \
	}

#define BBGC_UNLOCK \
	if( --bbGC::locks>0 ){ \
		std::unique_lock<std::mutex> lock( bbGC::mutex ); \
		++bbGC::sem_count; \
		bbGC::cond_var.notify_one(); \
	}
	
	int sem_count;
	std::mutex mutex;
	std::atomic_int locks;
	std::condition_variable cond_var;
	std::atomic_flag spinlock=ATOMIC_FLAG_INIT;
	
#endif

namespace bbGC{

	int markedBit;
	int unmarkedBit;

	bbGCNode *markQueue;
	bbGCNode *markedList;
	bbGCNode *unmarkedList;
	
	bbGCRoot *roots;
	
	bbGCFiber *fibers;
	bbGCFiber *currentFiber;

	bbGCNode markLists[2];
	bbGCNode freeList;
	
	size_t markedBytes;
	size_t unmarkedBytes;
	size_t allocedBytes;
	
	void init(){
		static bool done;
		if( done ) return;
		done=true;
		
		markedBit=1;
		markedList=&markLists[0];
		markedList->succ=markedList->pred=markedList;
		
		unmarkedBit=2;
		unmarkedList=&markLists[1];
		unmarkedList->succ=unmarkedList->pred=unmarkedList;
		
		freeList.succ=freeList.pred=&freeList;
		
		fibers=new bbGCFiber;
		
		currentFiber=fibers;
	}
	
	void destroy( bbGCNode *p ){
	
//		printf( "destroying: %s %p\n",p->typeName(),p );
		
#if BBGC_DEBUG

		p->flags=3;

#else
		p->~bbGCNode();
			
		bbFree( p );
#endif
	}
	
	void reclaim( size_t size=0x7fffffff ){
	
		while( freeList.succ!=&freeList ){
		
			bbGCNode *p=freeList.succ;
			
			size_t psize=bbMallocSize( p );
			
			remove( p );
			destroy( p );

			if( psize>=size ) break;
			size-=psize;
		}
	}
	
	void mark( bbGCNode *p ){
		if( !p || p->flags==markedBit ) return;
		
		remove( p );
		insert( p,markedList );
		
		p->flags=markedBit;
		
		markedBytes+=bbMallocSize( p );

		p->gcMark();
	}
	
	void markRoots(){
	
		for( bbGCRoot *root=roots;root;root=root->succ ){
		
			root->gcMark();
		}
	}
	
	void markFrames(){
	
		bbGCFiber *fiber=fibers;
		
		for(;;){

			for( bbGCFrame *frame=fiber->frames;frame;frame=frame->succ ){
			
				frame->gcMark();
			}
			
			for( bbGCNode *node=fiber->ctoring;node;node=node->succ ){
			
				node->gcMark();
			}
			
			fiber=fiber->succ;
			if( fiber==fibers ) break; 
		}
	}
	
	void markQueued( size_t tomark=0x7fffffff ){
	
		while( markQueue && markedBytes<tomark ){

			bbGCNode *p=markQueue;
			markQueue=p->succ;
			
			insert( p,markedList );
			
			markedBytes+=bbMallocSize( p );
			
//			printf( "marking %s\n",p->typeName() );fflush( stdout );
			
			p->gcMark();
		}
	}

	void sweep(){
	
//		puts( "bbGC::sweep()" );fflush( stdout );
	
		markFrames();
	
		markQueued();
		
		if( unmarkedList->succ!=unmarkedList ){
			
			//append unmarked to end of free queue
			unmarkedList->succ->pred=freeList.pred;
			unmarkedList->pred->succ=&freeList;
			freeList.pred->succ=unmarkedList->succ;
			freeList.pred=unmarkedList->pred;
			
			//clear unmarked
			unmarkedList->succ=unmarkedList->pred=unmarkedList;
		}
		
		std::swap( markedList,unmarkedList );
		std::swap( markedBit,unmarkedBit );
		
		unmarkedBytes=markedBytes;

		markedBytes=0;
		
		allocedBytes=0;
		
		markRoots();
	}
	
	bbGCNode *alloc( size_t size ){

#ifndef BBGC_DISABLED
	
		if( allocedBytes>=BBGC_TRIGGER ){

			sweep();
		
#if BBGC_AGGRESSIVE
			reclaim();
#endif
		}else{
		
#if BBGC_INCREMENTAL

//			size_t tomark=double( allocedBytes ) / double( BBGC_TRIGGER ) * double( unmarkedBytes + allocedBytes );

			size_t tomark=double( allocedBytes ) / double( BBGC_TRIGGER ) * double( unmarkedBytes + BBGC_TRIGGER );
	
			markQueued( tomark );
#endif
		}

#endif
	
		bbGCNode *p=(bbGCNode*)bbMalloc( size );
		
		*((void**)p)=(void*)0xcafebabe;
		
		p->flags=0;
		
		size=bbMallocSize( p );
		
		allocedBytes+=size;
		
#if !BBGC_AGGRESSIVE
		reclaim( size );
#endif
		return p;
	}
	
	void collect(){
	
		sweep();

		reclaim();
		
//		printf( "GCCollect: in use=%i\n",(int)unmarkedBytes );fflush( stdout );
	}
}
