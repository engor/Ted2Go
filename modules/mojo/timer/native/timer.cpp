
#include "timer.h"

#include <SDL.h>

bbInt	g_mojo_app_AppInstance_AddAsyncCallback(bbFunction<void()> l_func);
void	g_mojo_app_AppInstance_RemoveAsyncCallback( bbInt id );
void	g_mojo_app_AppInstance_EnableAsyncCallback( bbInt id );
void	g_mojo_app_AppInstance_DisableAsyncCallback( bbInt id );

struct bbTimer::Rep{

	int _freq;
	int	_interval;
	int _remainder;
	int _accumulator;

	bool _suspended;
	bool _cancelled;
	bool _reset;
	
	int _callback;
	int _timer;
};

namespace{

	const int INVOKE=0x40000000;
	const int REMOVE=0x80000000;

	void postEvent( int code ){
		SDL_UserEvent event;
		event.type=SDL_USEREVENT;
		event.code=code;
		event.data1=0;
		event.data2=0;
		
		if( SDL_PeepEvents( (SDL_Event*)&event,1,SDL_ADDEVENT,SDL_FIRSTEVENT,SDL_LASTEVENT )!=1 ){
			printf(" SDL_PeepEvents error!\n" );fflush( stdout );
		}
	}
}

bbTimer::bbTimer( int freq,bbFunction<void()> fired ){

	int p=1000/freq;

	_rep=new Rep;

	_rep->_freq=freq;
	_rep->_interval=p;
	_rep->_remainder=1000-p*freq;
	_rep->_accumulator=0;
	_rep->_suspended=true;
	_rep->_cancelled=false;
	_rep->_reset=false;
	
	_rep->_callback=g_mojo_app_AppInstance_AddAsyncCallback( fired );
	
	setSuspended( false );
}

bool bbTimer::suspended(){
	if( !_rep ) return false;
	
	return _rep->_suspended;
}

void bbTimer::setSuspended( bool suspended ){
	if( !_rep ) return;
	
	if( suspended==_rep->_suspended ) return;
	
	if( _rep->_suspended=suspended ){
	
		SDL_RemoveTimer( _rep->_timer );
	
		g_mojo_app_AppInstance_DisableAsyncCallback( _rep->_callback );

	}else{

		g_mojo_app_AppInstance_EnableAsyncCallback( _rep->_callback );
	
		_rep->_timer=SDL_AddTimer( _rep->_interval,sdl_timer_callback,(void*)_rep );

	}
}

void bbTimer::reset(){
	if( !_rep ) return;
	
	_rep->_reset=true;
}

void bbTimer::cancel(){
	if( !_rep ) return;

	g_mojo_app_AppInstance_RemoveAsyncCallback( _rep->_callback );

	_rep->_suspended=true;
	_rep->_cancelled=true;
	
	_rep=nullptr;
}

unsigned bbTimer::sdl_timer_callback( unsigned interval,void *param ){
	
	bbTimer::Rep *rep=(bbTimer::Rep*)param;
	
	if( rep->_suspended ){
		if( rep->_cancelled ) delete rep;
		return 0;
	}
	
	/*
	if( rep->_reset ){
		rep->_reset=false;
		rep->_accumulator=0;
		return SDL_GetTicks()+interval;
	}
	*/
	
	postEvent( rep->_callback|INVOKE );
	
	rep->_accumulator+=rep->_remainder;
	if( rep->_accumulator>=rep->_freq ){
		rep->_accumulator-=rep->_freq;
		return rep->_interval+1;
	}
	
	return rep->_interval;
}
