
#include "app.h"

#include "../../../std/async/native/async.h"

#include <SDL.h>

namespace bbApp{

	void postEventFilter( bbAsync::Event *event ){

		SDL_UserEvent uevent;
		uevent.type=SDL_USEREVENT;
		uevent.code=0;
		uevent.data1=event;
		uevent.data2=0;
	
		if( SDL_PeepEvents( (SDL_Event*)&uevent,1,SDL_ADDEVENT,SDL_FIRSTEVENT,SDL_LASTEVENT )!=1 ){
			printf( "SDL_PeepEvents error!\n" );fflush( stdout );
		}
	}

	void init(){

		bbAsync::setPostEventFilter( postEventFilter );
	}
}
