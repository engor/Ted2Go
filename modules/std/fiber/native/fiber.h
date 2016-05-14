
#ifndef BB_STD_FIBER_H
#define BB_STD_FIBER_H

#include <bbmonkey.h>

namespace bbFiber{

	typedef bbFunction<void()> Entry;
	
	int  StartFiber( Entry entry );
	
	int  CreateFiber( Entry entry );
	
	void ResumeFiber( int fiber );
	
	void TerminateFiber( int fiber );
	
	void SuspendCurrentFiber();
	
	int  GetCurrentFiber();
}

#endif

