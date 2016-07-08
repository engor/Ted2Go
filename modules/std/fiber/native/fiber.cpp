
#include "fiber.h"
#include "fcontext.h"

namespace bbFiber{

	const int MAX_FIBERS=1024;
	
	const size_t STACK_SIZE=65536;	//woho

	const size_t STACK_BUF_SIZE=65536;
	
	struct Fiber{
	
		Fiber *succ;
		int id;
				
		unsigned char *stack;
		bbGCFiber *gcFiber;
		bbDBContext *dbContext;
		
		Entry entry;
		fcontext_t fcontext;
		fcontext_t fcontext2;
	};
	
	Fiber *fibers;
	Fiber *freeFibers;
	Fiber *mainFiber;
	Fiber *currFiber;
	
	unsigned char *stackBuf,*stackEnd;
	
	unsigned char *allocStack(){
		
		if( stackBuf==stackEnd ){
			stackBuf=alloc_fcontext_stack( STACK_BUF_SIZE,false );
			stackEnd=stackBuf+STACK_BUF_SIZE;
		}
		
		unsigned char *p=stackBuf;
		stackBuf+=STACK_SIZE;
		
		return p;
	}
	
	void init(){
	
		if( fibers ) return;
		
		fibers=new Fiber[MAX_FIBERS];
		bbGCFiber *gcFibers=new bbGCFiber[MAX_FIBERS];
		bbDBContext *dbContexts=new bbDBContext[MAX_FIBERS];
	
		for( int i=0;i<MAX_FIBERS;++i ){
			fibers[i].id=i;
			fibers[i].succ=&fibers[i+1];
			fibers[i].stack=nullptr;
			fibers[i].gcFiber=&gcFibers[i];
			fibers[i].dbContext=&dbContexts[i];
			fibers[i].fcontext=nullptr;
			fibers[i].fcontext2=nullptr;
		}
		fibers[MAX_FIBERS-1].succ=nullptr;
		freeFibers=&fibers[1];
		
		mainFiber=&fibers[0];
		mainFiber->gcFiber=bbGC::currentFiber;
		mainFiber->dbContext=bbDB::currentContext;
		
		currFiber=mainFiber;
	}
	
	Fiber *getFiber( int id ){
	
		if( !fibers ) return nullptr;
		
		Fiber *fiber=&fibers[id & (MAX_FIBERS-1)];
		
		if( fiber->id==id ) return fiber;
		
		return nullptr;
	}
	
	Fiber *allocFiber(){
	
		if( !fibers ) init();
	
		Fiber *fiber=freeFibers;
		if( !fiber ) return nullptr;
		
		if( !fiber->stack ) fiber->stack=allocStack();
		
		freeFibers=fiber->succ;
		
		fiber->id+=MAX_FIBERS;
		
		return fiber;
	}
	
	fcontext_t freeFiber( Fiber *fiber ){
	
		fcontext_t fcontext=fiber->fcontext2;
		
		fiber->id+=MAX_FIBERS;
		
		fiber->succ=freeFibers;
		freeFibers=fiber;
		
		return fcontext;
	}
	
	void setCurrFiber( Fiber *fiber ){

		bbGC::currentFiber=fiber->gcFiber;
		bbDB::currentContext=fiber->dbContext;
		currFiber=fiber;
	}
	
	void fiberEntry( transfer_t t ){
	
		Fiber *fiber=(Fiber*)t.data;
		
		fiber->fcontext2=t.fcontext;
		fiber->dbContext->init();
		fiber->gcFiber->link();
		
		setCurrFiber( fiber );
		
		fiber->entry();
		
		fiber->gcFiber->unlink();
		
		jump_fcontext( freeFiber( fiber ),nullptr );
	}
	
	// ***** API *****

	int createFiber( Entry entry ){
	
		Fiber *fiber=allocFiber();
		if( !fiber ) return 0;
		
		fiber->entry=entry;
		fiber->fcontext=make_fcontext( fiber->stack+STACK_SIZE,STACK_SIZE,fiberEntry );
		
		return fiber->id;
	}
	
	void resumeFiber( int id ){
	
		Fiber *fiber=getFiber( id );
		if( !fiber ){
			bbDB::error( "Invalid fiber id" );
			return;
		}
		
		Fiber *curr=currFiber;
		
		fiber->fcontext=jump_fcontext( fiber->fcontext,fiber ).fcontext;
		
		setCurrFiber( curr );
	}
	
	void suspendCurrentFiber(){
	
		if( currFiber==mainFiber ){
			bbDB::error( "Can't suspend main fiber" );
			return;
		}
	
		Fiber *fiber=currFiber;
		
		fiber->fcontext2=jump_fcontext( fiber->fcontext2,nullptr ).fcontext;
		
		setCurrFiber( fiber );
	}
	
	int startFiber( bbFunction<void()> entry ){
	
		int id=createFiber( entry );
		
		if( id ) resumeFiber( id );
		
		return id;
	}
	
	void terminateFiber( int id ){
	
	}
	
	int getCurrentFiber(){
	
		if( fibers ) return currFiber->id;
		
		return 0;
	}
}
