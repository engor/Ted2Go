
#ifndef BB_DECLINFO_H
#define BB_DECLINFO_H

#include "bbtypeinfo.h"
#include "bbvariant.h"

struct bbDeclInfo{

	bbString name;
	bbString kind;
	bbTypeInfo *type;
	
	bbString getName(){
		return name;
	}
	
	bbString getKind(){
		return kind;
	}
	
	bbTypeInfo *getType(){
		return type;
	}
	
	virtual bbString toString();

	virtual bbVariant get( bbVariant instance );
	
	virtual void set( bbVariant instance,bbVariant value );
	
	virtual bbVariant invoke( bbVariant instance,bbArray<bbVariant> params );
};

// ***** Global *****
//
template<class T> struct bbGlobalDeclInfo : public bbDeclInfo{

	T *ptr;
	
	bbGlobalDeclInfo( bbString name,T *ptr ):ptr( ptr ){
		this->name=name;
		this->kind="Global";
		this->type=bbGetType<T>();
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
	
	bbGlobalVarDeclInfo( bbString name,bbGCVar<T> *ptr ):ptr( ptr ){
		this->name=name;
		this->kind="Global";
		this->type=bbGetType<T>();
	}
	
	bbVariant get( bbVariant instance ){
	
		return bbVariant( ptr->get() );
	}
	
	void set( bbVariant instance,bbVariant value ){
	
		*ptr=value.get<T*>();
	}
};


template<class T> bbDeclInfo *bbGlobalDecl( bbString name,T *ptr ){

	return new bbGlobalDeclInfo<T>( name,ptr );
}

template<class T> bbDeclInfo *bbGlobalDecl( bbString name,bbGCVar<T> *ptr ){

	return new bbGlobalVarDeclInfo<T>( name,ptr );
}

// ***** Field *****
//
template<class C,class T> struct bbFieldDeclInfo : public bbDeclInfo{

	T C::*ptr;
	
	bbFieldDeclInfo( bbString name,T C::*ptr ):ptr( ptr ){
		this->name=name;
		this->kind="Field";
		this->type=bbGetType<T>();
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
	
	bbFieldVarDeclInfo( bbString name,bbGCVar<T> C::*ptr ):ptr( ptr ){
		this->name=name;
		this->kind="Field";
		this->type=bbGetType<T*>();
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

template<class C,class T> bbDeclInfo *bbFieldDecl( bbString name,T C::*ptr ){

	return new bbFieldDeclInfo<C,T>( name,ptr );
}

template<class C,class T> bbDeclInfo *bbFieldDecl( bbString name,bbGCVar<T> C::*ptr ){

	return new bbFieldVarDeclInfo<C,T>( name,ptr );
}

// ***** Constructor *****
//
template<class C,class...A> struct bbCtorDeclInfo : public bbDeclInfo{

	bbCtorDeclInfo(){
		this->name="New";
		this->kind="Constructor";
		this->type=bbGetType<bbFunction<void(A...)>>();
	}
	
	template<int...I> C *invoke( bbArray<bbVariant> params,detail::seq<I...> ){
	
		return bbGCNew<C>( params[I].get<A>()... );
	}
	
	bbVariant invoke( bbVariant instance,bbArray<bbVariant> params ){
	
		return bbVariant( invoke( params,detail::gen_seq<sizeof...(A)>{} ) );
	}
};

template<class C,class...A> bbDeclInfo *bbCtorDecl(){

	return new bbCtorDeclInfo<C,A...>();
}

// ***** Method *****
//
template<class C,class R,class...A> struct bbMethodDeclInfo : public bbDeclInfo{

	R (C::*ptr)(A...);
	
	bbMethodDeclInfo( bbString name,R (C::*ptr)(A...) ):ptr( ptr ){
		this->name=name;
		this->kind="Method";
		this->type=bbGetType<bbFunction<R(A...)>>();
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
	
	bbMethodDeclInfo( bbString name,R (C::*ptr)(A...) ):ptr( ptr ){
		this->name=name;
		this->kind="Method";
		this->type=bbGetType<bbFunction<R(A...)>>();
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

template<class C,class R,class...A> bbDeclInfo *bbMethodDecl( bbString name,R (C::*ptr)(A...) ){

	return new bbMethodDeclInfo<C,R,A...>( name,ptr );
}

// ***** Function *****
//
template<class R,class...A> struct bbFunctionDeclInfo : public bbDeclInfo{

	R (*ptr)(A...);
	
	bbFunctionDeclInfo( bbString name,R (*ptr)(A...) ):ptr( ptr ){
		this->name=name;
		this->kind="Function";
		this->type=bbGetType<bbFunction<R(A...)>>();
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
	
	bbFunctionDeclInfo( bbString name,R (*ptr)(A...) ):ptr( ptr ){
		this->name=name;
		this->kind="Function";
		this->type=bbGetType<bbFunction<R(A...)>>();
	}
	
	template<int...I> R invoke( bbArray<bbVariant> params,detail::seq<I...> ){
	
		return (*ptr)( params[I].get<A>()... );
	}
	
	bbVariant invoke( bbVariant instance,bbArray<bbVariant> params ){
	
		invoke( params,detail::gen_seq<sizeof...(A)>{} );
		
		return {};
	}
};

template<class R,class...A> bbDeclInfo *bbFunctionDecl( bbString name,R (*ptr)(A...) ){

	return new bbFunctionDeclInfo<R,A...>( name,ptr );
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
