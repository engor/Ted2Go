
#ifndef BB_TEST_EXTERNS_H
#define BB_TEST_EXTERNS_H

#include <bbmonkey.h>

class C;
class D;
class T;

extern int G;

extern void F();

enum E{
	E1,
	E2,
	E3
};

class C : public bbObject{

	bbGCVar<D> _d;

public:
	
	C();
	C( D *d );
	
	void gcMark();
};

class D : public C{

public:

	D();
	
	void M();
	
	const char *M2( const char *str );
	
	void gcMark();
};

class T{

public:

	T();
	T( int x );
	
	~T();
};

void glue_E( C *c );

#endif