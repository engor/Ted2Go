
#ifndef BB_INIT_H
#define BB_INIT_H

//Simple list of stuff to get inited before main is run

struct bbInit{
	bbInit *succ;
	const char *info;
	void (*init)();
	
	static bbInit *first;
	
	bbInit( const char *info,void(*init)() );
};

#endif
