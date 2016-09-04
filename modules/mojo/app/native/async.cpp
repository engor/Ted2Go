
#include "async.h"

#include "../../../std/async/native/async.h"

#include "../../../std/fiber/native/fiber.h"

#include <SDL.h>

#include <thread>
#include <chrono>

bbInt g_mojo_app_AppInstance_AddAsyncCallback( bbFunction<void()> callback );

namespace{

	const int INVOKE=0x40000000;
	const int REMOVE=0x80000000;

	static void postEvent( int code ){
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

int bbAddAsyncCallback( bbFunction<void()> callback ){

	return g_mojo_app_AppInstance_AddAsyncCallback( callback );
}

void bbInvokeAsyncCallback( int callback,bool remove ){

	int code=callback|INVOKE;
	
	if( remove ) code|=REMOVE;
	
	postEvent( code );
}

void bbRemoveAsyncCallback( int callback ){

	int code=callback|REMOVE;
	
	postEvent( code );
}

void bbAppFiberSleep( int millis ){

	int timeout=SDL_GetTicks()+millis;

	struct Resumer : public bbFunction<void()>::Rep{
		
		int fiber;

		Resumer():fiber( bbFiber::getCurrentFiber() ){
		}
			
		void invoke(){
			bbFiber::resumeFiber( fiber );
		}
	};
		
	bbFunction<void()> resumer( new Resumer );
		
	int resume=bbAddAsyncCallback( resumer );
		
	std::thread( [=](){
	
		int dur=timeout-SDL_GetTicks();
		
		if( dur>0 ) SDL_Delay( dur );
			
		bbInvokeAsyncCallback( resume,true );
		
	} ).detach();
		
	bbFiber::suspendCurrentFiber();
}

void bbAppPostEventFilter( bbAsync::Event *event ){

	SDL_UserEvent uevent;
	uevent.type=SDL_USEREVENT;
	uevent.code=0;
	uevent.data1=event;
	uevent.data2=0;

	if( SDL_PeepEvents( (SDL_Event*)&uevent,1,SDL_ADDEVENT,SDL_FIRSTEVENT,SDL_LASTEVENT )!=1 ){
		printf( "SDL_PeepEvents error!\n" );fflush( stdout );
	}
}

void bbAppSetPostEventFilter(){

	bbAsync::setPostEventFilter( bbAppPostEventFilter );
}

