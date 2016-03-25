
#include "bbobject.h"
#include "bbdebug.h"
#include "bbarray.h"

bbException::bbException(){

	_debugStack=bbDB::stack();
}

bbException::bbException( bbString message ):bbException(){

	_message=message;
}
