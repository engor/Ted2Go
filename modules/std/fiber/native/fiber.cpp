
#include "fiber.h"

#include <thread>
#include <mutex>
#include <condition_variable>

namespace{

	const int MaxFibers=1024;
	const int FiberIdMask=MaxFibers-1;

	struct Semaphore{
	
		int count;
		std::mutex mutex;
		std::condition_variable cond_var;
		
		Semaphore( int count=0 ):count( count ){
		}
		
		void wait(){
			std::unique_lock<std::mutex> lock( mutex );
			while( !count ) cond_var.wait( lock );
			--count;
		}
		
		void signal(){
			std::unique_lock<std::mutex> lock( mutex );
			++count;
			cond_var.notify_one();
		}
	};
	
	struct Fiber{
		int id;
		bbGCFiber *gcFiber;
		bbDBContext *dbContext;
		Semaphore semaphore;
		Fiber *canceled;
	};
	
	struct TerminateEx{
	};
	
	Fiber fibers[MaxFibers];
	bbGCFiber gcFibers[MaxFibers];
	bbDBContext dbContexts[MaxFibers];
	
	Fiber *currentFiber;
	
	int readyStack[256];
	int *readyStackSp=readyStack;
	
	void init(){

		static bool done;
		if( done ) return;
		done=true;

		for( int i=1;i<MaxFibers;++i ){
			fibers[i].id=-i;
			fibers[i].gcFiber=&gcFibers[i];
			fibers[i].dbContext=&dbContexts[i];
		}
		
		fibers[0].id=0;
		fibers[0].gcFiber=bbGC::currentFiber;
		fibers[0].dbContext=bbDB::currentContext;
		
		currentFiber=&fibers[0];
	}
	
	//not too sexy yet..
	Fiber *allocFiber(){
		for( int i=1;i<MaxFibers;++i ){
			if( fibers[i].id>=0 ) continue;
			Fiber *fiber=&fibers[i];
			fiber->dbContext->init();
			fiber->id=(-fiber->id)+MaxFibers;
			fiber->canceled=nullptr;
			return fiber;
		}
		printf( "Out of fibers!\n" );
		exit( -1 );
	}
	
	void freeFiber( Fiber *fiber ){
		fiber->id=-fiber->id;
	}
	
	Fiber *getFiber( int fiberid ){
		
		Fiber *fiber=&fibers[fiberid & FiberIdMask];
		
		if( fiber->id!=fiberid ){
			printf( "Invalid fiber id\n" );fflush( stdout );
			exit( -1 );
		}
		
		return fiber;
	}
	
	void pushReadyStack(){
	
		if( readyStackSp==readyStack+256 ){
			printf( "Fiber stack overflow\n" );fflush( stdout );
			exit( -1 );
		}
		*readyStackSp++=currentFiber->id;
	}
	
	Fiber *popReadyStack(){
	
		while( readyStackSp!=readyStack ){
			Fiber *fiber=getFiber( *--readyStackSp );
			if( fiber ) return fiber;
		}
		printf( "Fiber stack underflow\n" );
		fflush( stdout );
		exit( -1 );
	}
	
	void switchToFiber( Fiber *fiber ){

		Fiber *current=currentFiber;
		
		currentFiber=fiber;
		bbGC::currentFiber=fiber->gcFiber;
		bbDB::currentContext=fiber->dbContext;
		fiber->semaphore.signal();
		
		current->semaphore.wait();
		if( current->canceled ) throw new TerminateEx;
	}
}

namespace bbFiber{

	int CreateFiber( Entry entry ){
		init();

		Fiber *fiber=allocFiber();
		
		std::thread thread( [=](){
		
			fiber->semaphore.wait();
			
			Fiber *nextFiber=fiber->canceled;
			
			if( !nextFiber ){

				fiber->gcFiber->link();
				
				try{
				
					entry();
					
					nextFiber=popReadyStack();
					
				}catch( TerminateEx ){
				
					nextFiber=fiber->canceled;
				}
				
				fiber->gcFiber->unlink();
			}
			
			freeFiber( fiber );
			
			currentFiber=nextFiber;
			bbGC::currentFiber=nextFiber->gcFiber;
			bbDB::currentContext=nextFiber->dbContext;
			nextFiber->semaphore.signal();
		} );
		
		thread.detach();
		
		return fiber->id;
	}
	
	int StartFiber( Entry entry ){
	
		int fiberid=CreateFiber( entry );
		
		ResumeFiber( fiberid );
		
		return fiberid;
	}
	
	void ResumeFiber( int fiberid ){
	
		Fiber *fiber=getFiber( fiberid );
		if( !fiber ) return;
		
		pushReadyStack();
		
		switchToFiber( fiber );
	}
	
	void TerminateFiber( int fiberid ){
	
		Fiber *fiber=getFiber( fiberid );
		if( !fiber ) return;
		
		fiber->canceled=currentFiber;
		
		switchToFiber( fiber );
	}
	
	void SuspendCurrentFiber(){
	
		Fiber *fiber=popReadyStack();
		
		switchToFiber( fiber );
	}
	
	int GetCurrentFiber(){
		init();
		
		return currentFiber->id;
	}
}
