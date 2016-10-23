
#ifndef BB_FUNCTION_H
#define BB_FUNCTION_H

#include "bbtypes.h"
//#include "bbgc.h"
#include "bbdebug.h"

template<class T> class bbFunction;

template<class R,class...A> struct bbFunction<R(A...)>{

	typedef R(*F)(A...);
	
	struct FunctionRep;
	struct SequenceRep;

	template<class C> struct MethodRep;
	
	static R castErr( A... ){
		puts( "Null Function Error" );
		exit( -1 );
		return R();
	}
	
	struct Rep{

		int refs=0;

		virtual ~Rep(){
		}
		
		virtual R invoke( A... ){
			return R();
		}
		
		virtual bool equals( Rep *rep ){
			return rep==this;
		}
		
		virtual int compare( Rep *rhs ){
			if( this<rhs ) return -1;
			if( this>rhs ) return 1;
			return 0;
		}
		
		virtual Rep *remove( Rep *rep ){
			if( equals( rep ) ) return &_nullRep;
			return this;
		}
		
		virtual void gcMark(){
		}
		
		void *operator new( size_t size ){
			return bbMalloc( size );
		}
		
		void operator delete( void *p ){
			bbFree( p );
		}
	};
	
	struct FunctionRep : public Rep{
	
		F p;
		
		FunctionRep( F p ):p( p ){
		}
		
		virtual R invoke( A...a ){
			return p( a... );
		}
		
		virtual bool equals( Rep *rhs ){
			FunctionRep *t=dynamic_cast<FunctionRep*>( rhs );
			return t && p==t->p;
		}
		
		virtual int compare( Rep *rhs ){
			FunctionRep *t=dynamic_cast<FunctionRep*>( rhs );
			if( t && p==t->p ) return 0;
			return Rep::compare( rhs );
		}
		
		virtual F Cast(){
			return p;
		}
	};
	
	template<class C> struct MethodRep : public Rep{
	
		typedef R(C::*T)(A...);
		C *c;
		T p;
		
		MethodRep( C *c,T p ):c(c),p(p){
		}
		
		virtual R invoke( A...a ){
			return (c->*p)( a... );
		}
		
		virtual bool equals( Rep *rhs ){
			MethodRep *t=dynamic_cast<MethodRep*>( rhs );
			return t && c==t->c && p==t->p;
		}

		virtual int compare( Rep *rhs ){
			MethodRep *t=dynamic_cast<MethodRep*>( rhs );
			if( t && c==t->c && p==t->p ) return 0;
			return Rep::compare( rhs );
		}
		
		virtual void gcMark(){
			bbGCMark( c );
		}
		
	};
	
	struct SequenceRep : public Rep{
	
		bbFunction lhs,rhs;
		
		SequenceRep( const bbFunction &lhs,const bbFunction &rhs ):lhs( lhs ),rhs( rhs ){
		}
		
		virtual R invoke( A...a ){
			lhs( a... );
			return rhs( a... );
		}
		
		virtual Rep *remove( Rep *rep ){
		
			if( rep==this ) return &_nullRep;
			
			Rep *lhs2=lhs._rep->remove( rep );
			Rep *rhs2=rhs._rep->remove( rep );
			
			if( lhs2==lhs._rep && rhs2==rhs._rep ) return this;
			if( lhs2!=&_nullRep && rhs2 !=&_nullRep ) return new SequenceRep( lhs2,rhs2 );
			if( lhs2!=&_nullRep ) return lhs2;
			if( rhs2!=&_nullRep ) return rhs2;

			return &_nullRep;
		}
		
		virtual void gcMark(){
			lhs._rep->gcMark();
			rhs._rep->gcMark();
		}
	};
	
	Rep *_rep;
	
	static Rep _nullRep;
	
	void retain()const{
		++_rep->refs;
	}
	
	void release(){
		if( !--_rep->refs && _rep!=&_nullRep ) delete _rep;
	}
	
	bbFunction( Rep *rep ):_rep( rep ){
		retain();
	}
	
	public:
	
	bbFunction():_rep( &_nullRep ){
	}
	
	bbFunction( const bbFunction &p ):_rep( p._rep ){
		retain();
	}
	
	template<class C> bbFunction( C *c,typename MethodRep<C>::T p ):_rep( new MethodRep<C>(c,p) ){
		retain();
	}
	
	bbFunction( F p ):_rep( new FunctionRep( p ) ){
		retain();
	}
	
	~bbFunction(){
		release();
	}
	
	bbFunction &operator=( const bbFunction &p ){
		p.retain();
		release();
		_rep=p._rep;
		return *this;
	}
	
	bbFunction operator+( const bbFunction &rhs )const{
		if( _rep==&_nullRep ) return rhs;
		if( rhs._rep==&_nullRep ) return *this;
		return new SequenceRep( *this,rhs );
	}
	
	bbFunction operator-( const bbFunction &rhs )const{
		return _rep->remove( rhs._rep );
	}
	
	bbFunction &operator+=( const bbFunction &rhs ){
		*this=*this+rhs;
		return *this;
	}
	
	bbFunction &operator-=( const bbFunction &rhs ){
		*this=*this-rhs;
		return *this;
	}

	bbBool operator==( const bbFunction &rhs )const{
		return _rep->equals( rhs._rep );
	}
	
	bbBool operator!=( const bbFunction &rhs )const{
		return !_rep->equals( rhs._rep );
	}
	
	operator bbBool()const{
		return _rep==&_nullRep;
	}

	R operator()( A...a )const{
		return _rep->invoke( a... );
	}
	
	//cast to simple static function ptr
	//
	operator F()const{
		FunctionRep *t=dynamic_cast<FunctionRep*>( _rep );
		if( t ) return t->p;
		return castErr;
	}
};

template<class R,class...A> typename bbFunction<R(A...)>::Rep bbFunction<R(A...)>::_nullRep;

template<class C,class R,class...A> bbFunction<R(A...)> bbMethod( C *c,R(C::*p)(A...) ){
	return bbFunction<R(A...)>( c,p );
}

template<class C,class R,class...A> bbFunction<R(A...)> bbMethod( const bbGCVar<C> &c,R(C::*p)(A...) ){
	return bbFunction<R(A...)>( c.get(),p );
}

template<class R,class...A> bbFunction<R(A...)> bbMakefunc( R(*p)(A...) ){
	return bbFunction<R(A...)>( p );
}

template<class R,class...A> void bbGCMark( const bbFunction<R(A...)> &t ){
	t._rep->gcMark();
}

template<class R,class...A> int bbCompare( const bbFunction<R(A...)> &x,const bbFunction<R(A...)> &y ){
	return x._rep->compare( y._rep );
}

template<class R,class...A> bbString bbDBType( bbFunction<R(A...)> *p ){
	return bbDBType<R>()+"()";
}

template<class R,class...A> bbString bbDBValue( bbFunction<R(A...)> *p ){
	return "function?????";
}

#endif
