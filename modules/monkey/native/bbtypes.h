
#ifndef BB_TYPES_H
#define BB_TYPES_H

#include "bbstd.h"

typedef bool bbBool;
typedef signed char bbByte;
typedef unsigned char bbUByte;
typedef signed short bbShort;
typedef unsigned short bbUShort;
typedef signed int bbInt;
typedef unsigned int bbUInt;
typedef signed long long bbLong;
typedef unsigned long long bbULong;
typedef float bbFloat;
typedef double bbDouble;

typedef unsigned short bbChar;

class bbString;

template<class T> class bbFunction;

template<class T,int D=1> class bbArray;

template<class T> struct bbGCVar;

struct bbVariant;
struct bbTypeInfo;
struct bbDeclInfo;

namespace detail{

	template<int...I> struct seq { };
	
    template<int N, int...I> struct gen_seq : gen_seq<N-1,N-1,I...> { };
	
    template<int...I> struct gen_seq<0,I...> : seq<I...> { };
    
	template<typename T> struct remove_pointer { typedef T type; };

	template<typename T> struct remove_pointer<T*> { typedef typename remove_pointer<T>::type type; };
}

bbString bbTypeName( const char *type );

template<class X,class Y> int bbCompare( X x,Y y ){
	if( y>x ) return -1;
	return x>y;
}

#endif
