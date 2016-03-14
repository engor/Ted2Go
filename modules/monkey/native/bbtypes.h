
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

bbString bbTypeName( const char *type );

#endif
