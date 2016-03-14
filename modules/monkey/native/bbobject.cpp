
#include "bbobject.h"
#include "bbdebug.h"
#include "bbarray.h"

bbThrowable::bbThrowable(){

	int n=0;
	for( bbDBFrame *frame=bbDB::frames;frame;frame=frame->succ ) ++n;
	
	_debugStack=bbArray<bbString>::create( n );
	
	int i=0;
	for( bbDBFrame *frame=bbDB::frames;frame;frame=frame->succ ){
		_debugStack->at( i++ )=BB_T( frame->srcFile )+" ["+bbString( frame->srcPos>>12 )+"] "+frame->decl;
	}
}
