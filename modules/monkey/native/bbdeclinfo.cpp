
#include "bbdeclinfo.h"

// ***** bbDeclInfo ****

bbString bbDeclInfo::toString(){
	return kind+" "+name+":"+(type ? type->name : "?????");
}

bbVariant bbDeclInfo::get( bbVariant instance ){
	bbRuntimeError( "Decl is not gettable" );
	return {};
}
	
void bbDeclInfo::set( bbVariant instance,bbVariant value ){
	bbRuntimeError( "Decl is not settable" );
}
	
bbVariant bbDeclInfo::invoke( bbVariant instance,bbArray<bbVariant> params ){
	bbRuntimeError( "Decl is not invokable" );
	return {};
}
