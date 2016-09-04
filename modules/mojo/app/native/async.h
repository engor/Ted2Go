
#ifndef BB_MOJO_APP_ASYNC_H
#define BB_MOJO_APP_ASYNC_H

#include <bbmonkey.h>

//Call on GUI thread only!
//
int bbAddAsyncCallback( bbFunction<void()> callback );

//Can call on any thread...queued for later execution by GUI thread.
//
void bbInvokeAsyncCallback( int callback,bool remove );

void bbRemoveAsyncCallback( int callback );

void bbAppFiberSleep( int millis );

void bbAppSetPostEventFilter();

#endif
