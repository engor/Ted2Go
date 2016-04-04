
#include "externs.h"

int G;

void F(){
	puts( "::F()" );
}

C::C(){
	puts( "C::C()" );
}

C::C( D *d ):_d( d ){
	puts( "C::C( D* )" );
}
	
void C::gcMark(){
	bbGCMark( _d );
}

D::D(){
	puts( "D::D()" );
}

void D::M(){
	puts( "D::M()" );
}

const char *D::M2( const char *str ){
	return "Goodbye!";
}

void D::gcMark(){
	C::gcMark();
}

T::T(){
	puts( "T::T()" );
}
	
T::T( int x ){
	puts( "T::T( int )" );
}

T::~T(){
	puts( "T::~T()" );
}

bool T::operator==( T *that ){
	puts( "T::operator==(T*)" );
	return this==that;
}

void glue_E( C *c ){
	puts( "::glue_E( C* )" );
}