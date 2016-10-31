
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

bbArray<bbString> bbDeclInfo::getMetaKeys(){

	if( !meta.length() ) return {};

	bbString eol="~\n";

	int n=1,i0=0;
	while( i0<meta.length() ){
		int i1=meta.find( eol,i0 );
		if( i1==-1 ) break;
		i0=i1+2;
		n+=1;
	}
	
	bbArray<bbString> keys( n );
	
	i0=0;
	for( int i=0;i<n;++i ){
		int i1=meta.find( "=",i0 );
		keys[i]=meta.slice( i0,i1 );
		i0=meta.find( eol,i1+1 )+2;
	}
	
	return keys;
}

bbString bbDeclInfo::getMetaValue( bbString key ){

	if( !meta.length() ) return {};
	
	bbString eol="~\n";

	key+="=";

	int i0=0;
	if( !meta.startsWith( key ) ){
		i0=meta.find( eol+key )+2;
		if( i0==1 ) return {};
	}
	
	i0+=key.length();

	int i1=meta.find( eol,i0 );
	if( i1==-1 ) return meta.slice( i0 );
	return meta.slice( i0,i1 );
}
