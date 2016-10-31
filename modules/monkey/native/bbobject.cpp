
#include "bbobject.h"
#include "bbdebug.h"
#include "bbarray.h"

bbNullCtor_t bbNullCtor;

// ***** bbObject *****

bbObject::~bbObject(){
}

const char *bbObject::typeName()const{
	return "monkey.Object";
}

// ***** bbInterface *****

bbInterface::~bbInterface(){
}