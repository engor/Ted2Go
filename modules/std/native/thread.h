
#ifndef BB_THREAD_H
#define BB_THREAD_H

#include <bbstd.h>

#if BB_THREADED

#include <bbobject.h>
#include <bbfunction.h>

typedef bbFunction<void()> bbThreadFunc;

struct semaphore{
	int count{};
	std::mutex mutex;
	std::condition_variable cond_var;
	
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

class bbThread : public bbObject{

	bbThreadFunc _func;
	
	std::thread _thread;
	
	semaphore _sema;
	
	static __thread bbThread *_current;
	
	static void entry( bbThread *current ){
	
		_current=current;

		bbGCThread gcThread( _current );
		
		_current->_sema.signal();
		
		_current->_func();
	}
	
	public:

	bbThread(){
	}
		
	bbThread( bbThreadFunc func ):_func( func ),_thread( entry,this ){
		_sema.wait();
	}
	
	void gcMark(){
		bbGCMark( _func );
	}
	
	void Join(){
		_thread.join();
	}
	
	void Detach(){
		_thread.detach();
	}
	
	static void Sleep( double seconds ){
		std::this_thread::sleep_for( std::chrono::nanoseconds( bbLong( seconds * 1000000000.0 ) ) );
	}
	
	static bbThread *Current(){
		return _current;
	}
	
	static void Yield_(){
		std::this_thread::yield();
	}
	
	static int HardwareThreads(){
		return std::thread::hardware_concurrency();
	}
};

#endif

#endif
