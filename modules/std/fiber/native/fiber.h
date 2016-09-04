
#ifndef BB_FIBER_H
#define BB_FIBER_H

#include <bbmonkey.h>

namespace bbFiber{

	typedef bbFunction<void()> Entry;

	int startFiber( Entry entry );
	
	int createFiber( Entry entry );
	
	void resumeFiber( int fiber );
	
	void terminateFiber( int fiber );
	
	void suspendCurrentFiber();
	
	void currentFiberSleep( double seconds );
	
	int getCurrentFiber();
}

#endif
