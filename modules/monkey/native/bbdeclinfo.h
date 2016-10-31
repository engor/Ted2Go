
#ifndef BB_DECLINFO_H
#define BB_DECLINFO_H

#include "bbtypeinfo.h"
#include "bbvariant.h"

#define BB_DECL_PUBLIC		0x000001
#define BB_DECL_PRIVATE		0x000002
#define BB_DECL_PROTECTED	0x000004
#define BB_DECL_INTERNAL	0x000008
#define BB_DECL_VIRTUAL		0x000100
#define BB_DECL_OVERRIDE	0x000200
#define BB_DECL_ABSTRACT	0x000400
#define BB_DECL_FINAL		0x000800
#define BB_DECL_EXTERN		0x001000
#define BB_DECL_EXTENSION	0x002000
#define BB_DECL_DEFAULT		0x004000
#define BB_DECL_GETTER		0x010000
#define BB_DECL_SETTER		0x020000
#define BB_DECL_OPERATOR	0x040000
#define BB_DECL_IFACEMEMBER	0x080000

#define BB_DECL_GETTABLE	0x10000000
#define BB_DECL_SETTABLE	0x20000000
#define BB_DECL_INVOKABLE	0x40000000

struct bbDeclInfo{

	bbString name;
	bbString meta;
	bbString kind;
	bbTypeInfo *type;
	int flags=0;
	
	bbString getName(){
		return name;
	}
	
	bbString getKind(){
		return kind;
	}
	
	bbTypeInfo *getType(){
		return type;
	}
	
	bbBool gettable(){ return flags & BB_DECL_GETTABLE; }

	bbBool settable(){ return flags & BB_DECL_SETTABLE; }

	bbBool invokable(){ return flags & BB_DECL_INVOKABLE; }

	bbArray<bbString> getMetaKeys();
	
	bbArray<bbString> getMetaData();
	
	bbString getMetaValue( bbString key );
	
	virtual bbString toString();

	virtual bbVariant get( bbVariant instance );
	
	virtual void set( bbVariant instance,bbVariant value );
	
	virtual bbVariant invoke( bbVariant instance,bbArray<bbVariant> params );
};

// ***** Global *****
//
template<class T> struct bbGlobalDeclInfo : public bbDeclInfo{

	T *ptr;
	
	bbGlobalDeclInfo( bbString name,T *ptr,bbString meta,bool isconst ):ptr( ptr ){
		this->name=name;
		this->meta=meta;
		this->kind=isconst ? "Const" : "Global";
		this->type=bbGetType<T>();
		this->flags=BB_DECL_GETTABLE|(isconst ? 0 : BB_DECL_SETTABLE);
	}
	
	bbVariant get( bbVariant instance ){
	
		return bbVariant( *ptr );
	}
	
	void set( bbVariant instance,bbVariant value ){
	
		*ptr=value.get<T>();
	}
};

template<class T> struct bbGlobalVarDeclInfo : public bbDeclInfo{

	bbGCVar<T> *ptr;
	
	bbGlobalVarDeclInfo( bbString name,bbGCVar<T> *ptr,bbString meta,bool isconst ):ptr( ptr ){
		this->name=name;
		this->meta=meta;
		this->kind=isconst ? "Const" : "Global";
		this->type=bbGetType<T>();
		this->flags=BB_DECL_GETTABLE|(isconst ? 0 : BB_DECL_SETTABLE);
	}
	
	bbVariant get( bbVariant instance ){
	
		return bbVariant( ptr->get() );
	}
	
	void set( bbVariant instance,bbVariant value ){
	
		*ptr=value.get<T*>();
	}
};


template<class T> bbDeclInfo *bbGlobalDecl( bbString name,T *ptr,bbString meta="" ){

	return new bbGlobalDeclInfo<T>( name,ptr,meta,false );
}

template<class T> bbDeclInfo *bbGlobalDecl( bbString name,bbGCVar<T> *ptr,bbString meta="" ){

	return new bbGlobalVarDeclInfo<T>( name,ptr,meta,false );
}

template<class T> bbDeclInfo *bbConstDecl( bbString name,T *ptr,bbString meta="" ){

	return new bbGlobalDeclInfo<T>( name,ptr,meta,true );
}

template<class T> bbDeclInfo *bbConstDecl( bbString name,bbGCVar<T> *ptr,bbString meta="" ){

	return new bbGlobalVarDeclInfo<T>( name,ptr,meta,true );
}

// ***** Field *****
//
template<class C,class T> struct bbFieldDeclInfo : public bbDeclInfo{

	T C::*ptr;
	
	bbFieldDeclInfo( bbString name,bbString meta,T C::*ptr ):ptr( ptr ){
		this->name=name;
		this->meta=meta;
		this->kind="Field";
		this->type=bbGetType<T>();
		this->flags=BB_DECL_GETTABLE|BB_DECL_SETTABLE;
	}
	
	bbVariant get( bbVariant instance ){
	
		C *p=instance.get<C*>();
		
		return bbVariant( p->*ptr );
	}
	
	void set( bbVariant instance,bbVariant value ){
	
		C *p=instance.get<C*>();
		
		p->*ptr=value.get<T>();
	}
};

template<class C,class T> struct bbFieldVarDeclInfo : public bbDeclInfo{

	bbGCVar<T> C::*ptr;
	
	bbFieldVarDeclInfo( bbString name,bbString meta,bbGCVar<T> C::*ptr ):ptr( ptr ){
		this->name=name;
		this->meta=meta;
		this->kind="Field";
		this->type=bbGetType<T*>();
		this->flags=BB_DECL_GETTABLE|BB_DECL_SETTABLE;
	}
	
	bbVariant get( bbVariant instance ){
	
		C *p=instance.get<C*>();
		
		return bbVariant( (p->*ptr).get() );
	}
	
	void set( bbVariant instance,bbVariant value ){
	
		C *p=instance.get<C*>();
		
		p->*ptr=value.get<T*>();
	}
};

template<class C,class T> bbDeclInfo *bbFieldDecl( bbString name,T C::*ptr,bbString meta="" ){

	return new bbFieldDeclInfo<C,T>( name,meta,ptr );
}

template<class C,class T> bbDeclInfo *bbFieldDecl( bbString name,bbGCVar<T> C::*ptr,bbString meta="" ){

	return new bbFieldVarDeclInfo<C,T>( name,meta,ptr );
}

// ***** Constructor *****
//
template<class C,class...A> struct bbCtorDeclInfo : public bbDeclInfo{

	bbCtorDeclInfo( bbString meta ){
		this->name="New";
		this->meta=meta;
		this->kind="Constructor";
		this->type=bbGetType<bbFunction<void(A...)>>();
		this->flags=BB_DECL_INVOKABLE;
	}
	
	template<int...I> C *invoke( bbArray<bbVariant> params,detail::seq<I...> ){
	
		return bbGCNew<C>( params[I].get<A>()... );
	}
	
	bbVariant invoke( bbVariant instance,bbArray<bbVariant> params ){
	
		return bbVariant( invoke( params,detail::gen_seq<sizeof...(A)>{} ) );
	}
};

template<class C,class...A> bbDeclInfo *bbCtorDecl( bbString meta="" ){

	return new bbCtorDeclInfo<C,A...>( meta );
}

// ***** Method *****
//
template<class C,class R,class...A> struct bbMethodDeclInfo : public bbDeclInfo{

	R (C::*ptr)(A...);
	
	bbMethodDeclInfo( bbString name,bbString meta,R (C::*ptr)(A...) ):ptr( ptr ){
		this->name=name;
		this->meta=meta;
		this->kind="Method";
		this->type=bbGetType<bbFunction<R(A...)>>();
		this->flags=BB_DECL_INVOKABLE;
	}
	
	template<int...I> R invoke( C *p,bbArray<bbVariant> params,detail::seq<I...> ){
	
		return (p->*ptr)( params[I].get<A>()... );
	}
	
	bbVariant invoke( bbVariant instance,bbArray<bbVariant> params ){
	
		C *p=instance.get<C*>();
		
		return bbVariant( invoke( p,params,detail::gen_seq<sizeof...(A)>{} ) );
	}
};

template<class C,class...A> struct bbMethodDeclInfo<C,void,A...> : public bbDeclInfo{

	typedef void R;

	R (C::*ptr)(A...);
	
	bbMethodDeclInfo( bbString name,bbString meta,R (C::*ptr)(A...) ):ptr( ptr ){
		this->name=name;
		this->meta=meta;
		this->kind="Method";
		this->type=bbGetType<bbFunction<R(A...)>>();
		this->flags=BB_DECL_INVOKABLE;
	}
	
	template<int...I> R invoke( C *p,bbArray<bbVariant> params,detail::seq<I...> ){
	
		return (p->*ptr)( params[I].get<A>()... );
	}

	bbVariant invoke( bbVariant instance,bbArray<bbVariant> params ){
	
		C *p=instance.get<C*>();
		
		invoke( p,params,detail::gen_seq<sizeof...(A)>{} );
		
		return {};
	}
};

template<class C,class R,class...A> bbDeclInfo *bbMethodDecl( bbString name,R (C::*ptr)(A...),bbString meta="" ){

	return new bbMethodDeclInfo<C,R,A...>( name,meta,ptr );
}

// ***** Property *****
//
template<class C,class T> struct bbPropertyDeclInfo : public bbDeclInfo{

	T (C::*getter)();
	
	void (C::*setter)(T);
	
	bbPropertyDeclInfo( bbString name,bbString meta,T(C::*getter)(),void(C::*setter)(T) ):getter( getter ),setter( setter ){
		this->name=name;
		this->meta=meta;
		this->kind="Property";
		this->type=bbGetType<T>();
		this->flags=(getter ? BB_DECL_GETTABLE : 0) | (setter ? BB_DECL_SETTABLE : 0);
	}
	
	bbVariant get( bbVariant instance ){
		if( !getter ) bbRuntimeError( "Property has not getter" );

		C *p=instance.get<C*>();
		
		return bbVariant( (p->*getter)() );
	}
	
	void set( bbVariant instance,bbVariant value ){
		if( !setter ) bbRuntimeError( "Property has not setter" );
		
		C *p=instance.get<C*>();
		
		(p->*setter)( value.get<T>() );
	}
};

template<class C,class T> bbDeclInfo *bbPropertyDecl( bbString name,T(C::*getter)(),void(C::*setter)(T),bbString meta="" ){

	return new bbPropertyDeclInfo<C,T>( name,meta,getter,setter );
}

// ***** Function *****
//
template<class R,class...A> struct bbFunctionDeclInfo : public bbDeclInfo{

	R (*ptr)(A...);
	
	bbFunctionDeclInfo( bbString name,bbString meta,R (*ptr)(A...) ):ptr( ptr ){
		this->name=name;
		this->meta=meta;
		this->kind="Function";
		this->type=bbGetType<bbFunction<R(A...)>>();
		this->flags=BB_DECL_INVOKABLE;
	}
	
	template<int...I> R invoke( bbArray<bbVariant> params,detail::seq<I...> ){
	
		return (*ptr)( params[I].get<A>()... );
	}
	
	bbVariant invoke( bbVariant instance,bbArray<bbVariant> params ){
	
		return bbVariant( invoke( params,detail::gen_seq<sizeof...(A)>{} ) );
	}
};

template<class...A> struct bbFunctionDeclInfo<void,A...> : public bbDeclInfo{

	typedef void R;

	R (*ptr)(A...);
	
	bbFunctionDeclInfo( bbString name,bbString meta,R (*ptr)(A...) ):ptr( ptr ){
		this->name=name;
		this->meta=meta;
		this->kind="Function";
		this->type=bbGetType<bbFunction<R(A...)>>();
		this->flags=BB_DECL_INVOKABLE;
	}
	
	template<int...I> R invoke( bbArray<bbVariant> params,detail::seq<I...> ){
	
		return (*ptr)( params[I].get<A>()... );
	}
	
	bbVariant invoke( bbVariant instance,bbArray<bbVariant> params ){
	
		invoke( params,detail::gen_seq<sizeof...(A)>{} );
		
		return {};
	}
};

template<class R,class...A> bbDeclInfo *bbFunctionDecl( bbString name,R (*ptr)(A...),bbString meta="" ){

	return new bbFunctionDeclInfo<R,A...>( name,meta,ptr );
}

template<class...Ds> bbDeclInfo **bbMembers( Ds...ds ){

	int n=sizeof...(Ds);
	bbDeclInfo *ts[]={ ds... };
	bbDeclInfo **ps=new bbDeclInfo*[n+1];
	for( int i=0;i<n;++i ) ps[i]=ts[i];
	ps[n]=0;
	
	return ps;
}

#endif
