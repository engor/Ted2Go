
#include "bbobject.h"
#include "bbdebug.h"
#include "bbarray.h"

bbNullCtor_t bbNullCtor;

bbException::bbException(){

	_debugStack=bbDB::stack();
}

bbException::bbException( bbString message ):bbException(){

	_message=message;
}

template<> bbDBType *bbDBTypeOf( bbObject** ){
	struct type : public bbDBType{
		bbString name(){ return "Object"; }
	};
	static type _type;
	return &_type;
}

