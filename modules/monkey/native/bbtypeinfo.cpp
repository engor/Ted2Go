
#include "bbtypeinfo.h"
#include "bbdeclinfo.h"

namespace{

	bbClassTypeInfo *_classes;
}

#define BB_PRIM_GETTYPE( TYPE,ID ) bbTypeInfo *bbGetType( TYPE const& ){ \
	static bbPrimTypeInfo info( ID ); \
	return &info; \
}

BB_PRIM_GETTYPE( bbBool,"Bool" )
BB_PRIM_GETTYPE( bbByte,"Byte" )
BB_PRIM_GETTYPE( bbUByte,"UShort" )
BB_PRIM_GETTYPE( bbShort,"Short" )
BB_PRIM_GETTYPE( bbUShort,"UShort" )
BB_PRIM_GETTYPE( bbInt,"Int" )
BB_PRIM_GETTYPE( bbUInt,"UInt" )
BB_PRIM_GETTYPE( bbLong,"Long" )
BB_PRIM_GETTYPE( bbULong,"ULong" )
BB_PRIM_GETTYPE( bbFloat,"Float" )
BB_PRIM_GETTYPE( bbDouble,"Double" )
BB_PRIM_GETTYPE( bbString,"String" )
BB_PRIM_GETTYPE( bbCString,"CString" )
BB_PRIM_GETTYPE( bbVariant,"Variant" )

// ***** bbTypeInfo *****

bbString bbTypeInfo::toString(){
	return name;
}

bbTypeInfo *bbTypeInfo::pointeeType(){
	bbRuntimeError( "Type '"+name+"' is not a pointer type" );
	return 0; 
}
	
bbTypeInfo *bbTypeInfo::elementType(){
	bbRuntimeError( "Type '"+name+"' is not an array type" );
	return 0;
}
	
int bbTypeInfo::arrayRank(){
	bbRuntimeError( "Type '"+name+"' is not an array type" );
	return 0;
}
	
bbTypeInfo *bbTypeInfo::returnType(){
	bbRuntimeError( "Type '"+name+"' is not a function type" );
	return 0; 
}
	
bbArray<bbTypeInfo*> bbTypeInfo::paramTypes(){
	bbRuntimeError( "Type '"+name+"' is not a function type" );
	return {};
}
	
bbTypeInfo *bbTypeInfo::superType(){
	bbRuntimeError( "Type '"+name+"' is not a class type" );
	return 0;
}
	
bbArray<bbTypeInfo*> bbTypeInfo::interfaceTypes(){
	bbRuntimeError( "Type '"+name+"' is not a class or interface type" );
	return {};
}
	
bbBool bbTypeInfo::extendsType( bbTypeInfo *type ){
	bbRuntimeError( "Type '"+name+"' is not a class or interface type" );
	return false;
}
	
bbArray<bbDeclInfo*> bbTypeInfo::getDecls(){
	bbRuntimeError( "Type '"+name+"' is not a class or interface type" );
	return {};
}

bbDeclInfo *bbTypeInfo::getDecl( bbString name ){

	bbArray<bbDeclInfo*> decls=getDecls();
	bbDeclInfo *found=0;

	for( int i=0;i<decls.length();++i ){
		bbDeclInfo *decl=decls[i];
		if( decl->name!=name ) continue;
		if( found ) return 0;
		found=decl;
	}

	return found;
}

bbArray<bbDeclInfo*> bbTypeInfo::getDecls( bbString name ){

	bbArray<bbDeclInfo*> decls=getDecls();

	int n=0;
	for( int i=0;i<decls.length();++i ){
		if( decls[i]->name==name ) ++n;
	}
	if( !n ) return {};
	
	bbArray<bbDeclInfo*> rdecls;
	
	int j=0;
	for( int i=0;i<decls.length();++i ){
		if( decls[i]->name==name) rdecls[j++]=decls[i];
	}
	return rdecls;
}

bbDeclInfo *bbTypeInfo::getDecl( bbString name,bbTypeInfo *type ){

	bbArray<bbDeclInfo*> decls=getDecls();

	for( int i=0;i<decls.length();++i ){
		bbDeclInfo *decl=decls[i];
		if( decl->name==name && decl->type==type ) return decl;
	}
	
	return 0;
}

bbTypeInfo *bbTypeInfo::getType( bbString cname ){

	for( bbClassTypeInfo *c=_classes;c;c=c->_succ ){
		if( c->name==cname ) return c;
	}
	
	return 0;
}

bbArray<bbTypeInfo*> bbTypeInfo::getTypes(){

	int n=0;
	for( bbClassTypeInfo *c=_classes;c;c=c->_succ ) ++n;
	
	bbArray<bbTypeInfo*> types( n );
	
	int i=0;
	for( bbClassTypeInfo *c=_classes;c;c=c->_succ ) types[i++]=c;
	
	return types;
}


// ***** bbUnknownTypeInfo *****

bbUnknownTypeInfo::bbUnknownTypeInfo(){
	this->name=BB_T("Unknown@")+bbString( bbLong( this ) );
	this->kind="Unknown";
}


// ***** bbVoidTypeInfo *****

bbVoidTypeInfo bbVoidTypeInfo::instance;

bbVoidTypeInfo::bbVoidTypeInfo(){
	this->name="Void";
	this->kind="Void";
}


// ***** bbObjectTypeInfo *****

bbObjectTypeInfo bbObjectTypeInfo::instance;

bbObjectTypeInfo::bbObjectTypeInfo(){
	this->name="Object";
	this->kind="Class";
}
	
bbTypeInfo *bbObjectTypeInfo::superType(){
	return 0;
}
	
bbBool bbObjectTypeInfo::extendsType( bbTypeInfo *type ){
	return type==&instance;
}
	
bbArray<bbDeclInfo*> bbObjectTypeInfo::getDecls(){
	return {};
}

bbTypeInfo *bbObject::typeof()const{

	return &bbObjectTypeInfo::instance;
}


// ***** bbPrimTypeInfo *****

bbPrimTypeInfo::bbPrimTypeInfo( bbString name ){
	this->name=name;
	this->kind="Primitive";
}


// ***** bbClassDecls *****

bbClassDecls::bbClassDecls( bbClassTypeInfo *classType ){
	_succ=classType->_decls;
	classType->_decls=this;
}

bbDeclInfo **bbClassDecls::decls(){

	if( !_decls ){
		_decls=initDecls();
		bbDeclInfo **p=_decls;
		while( *p ) ++p;
		_numDecls=p-_decls;
	}
	
	return _decls;
}

int bbClassDecls::numDecls(){
	if( !_decls ) decls();
	return _numDecls;
}

// ***** bbClassTypeInfo *****

bbClassTypeInfo::bbClassTypeInfo( bbString name,bbString kind ){
//	printf( "ClassTypeInfo:%s\n",name.c_str() );
	this->name=name;
	this->kind=kind;
	_succ=_classes;
	_classes=this;
}

bbTypeInfo *bbClassTypeInfo::superType(){
	return 0;
}

bbArray<bbTypeInfo*> bbClassTypeInfo::interfaceTypes(){
	return {};
}

bbBool bbClassTypeInfo::extendsType( bbTypeInfo *type ){

	if( type==this ) return true;
	
	bbArray<bbTypeInfo*> ifaces=interfaceTypes();
	
	for( int i=0;i<ifaces.length();++i ){

		if( ifaces[i]->extendsType( type ) ) return true;
	}
	
	if( bbTypeInfo *super=superType() ) return super->extendsType( type );
	
	return false;
}

bbArray<bbDeclInfo*> bbClassTypeInfo::getDecls(){

	int n=0;
	for( bbClassDecls *m=_decls;m;m=m->_succ ) n+=m->numDecls();
	
	bbArray<bbDeclInfo*> rdecls( n );
	
	int i=0;
	for( bbClassDecls *m=_decls;m;m=m->_succ ){
		bbDeclInfo **decls=m->decls();
		int n=m->numDecls();
		for( int j=0;j<n;++j ) rdecls[i++]=decls[j];
	}
	
	return rdecls;
}

bbClassTypeInfo *bbClassTypeInfo::getNamespace( bbString name ){

	for( bbClassTypeInfo *nmspace=_classes;nmspace;nmspace=nmspace->_succ ){
		if( nmspace->name==name ) return nmspace;
	}
	
	bbClassTypeInfo *nmspace=new bbClassTypeInfo( name,"Namespace" );
	return nmspace;
}
