
#ifndef BB_TIMER_H
#define BB_TIMER_H

#include <bbmonkey.h>

class bbTimer : public bbObject{
public:

	bbTimer( int freq,bbFunction<void()> fired );
	
	bool suspended();
	
	void setSuspended( bool suspended );
	
	void reset();
	
	void cancel();
	
private:
	
	struct Rep;
	Rep *_rep;
	
	static unsigned sdl_timer_callback( unsigned interval,void *param );
};

#endif
