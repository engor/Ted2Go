
#include "async.h"

namespace bbAsync{

	typedef std::chrono::duration<double> secs_t;
	typedef std::chrono::high_resolution_clock clock_t;
	typedef std::chrono::time_point<clock_t,secs_t> time_t;

	struct DelayedEvent{
		DelayedEvent *succ;
		Event *event;
		time_t time;
	};

	DelayedEvent *que;
	DelayedEvent *free_que;
	std::mutex que_mutex;
	std::condition_variable que_condvar;
	
	void initQue(){
	
		static bool inited;
		if( inited ) return;
		inited=true;
	
		std::thread( [](){
		
			std::unique_lock<std::mutex> lock( que_mutex );
			
			for(;;){
			
				if( que ){
					que_condvar.wait_for( lock,que->time-clock_t::now() );
				}else{
					que_condvar.wait( lock );
				}

				//prevent spamming...?				
				time_t now=clock_t::now();
				
				while( que && que->time<=now ){
					
					DelayedEvent *devent=que;
	
					devent->event->post();
					
					que=devent->succ;
					
					devent->succ=free_que;
					
					free_que=devent;
				}
			}
	
		} ).detach();
	}

	void (*postEventFilter)( Event* );
	
	void setPostEventFilter( void(*filter)(Event*) ){

		postEventFilter=filter;
	}

	void Event::post(){

		postEventFilter( this );
	}
	
	void Event::post( double delay ){
	
		time_t now=clock_t::now();
		
		initQue();
		
		{
			std::unique_lock<std::mutex> lock( que_mutex );
			
			DelayedEvent *devent=free_que;
			if( devent ){
				free_que=devent->succ;
			}else{
				devent=new DelayedEvent;
			}
			
			devent->event=this;
			devent->time=now+secs_t( delay );
	
			DelayedEvent *succ,**pred=&que;
			
			while( succ=*pred ){
				if( devent->time<succ->time ) break;
				pred=&succ->succ;
			}
			
			devent->succ=succ;
			*pred=devent;
		}
		
		que_condvar.notify_one();
	}
}
