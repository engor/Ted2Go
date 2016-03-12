
#ifndef BB_VARIANT_H
#define BB_VARIANT_H

class bbVariant{

	struct RepBase{
		virtual ~RepBase(){
		}
	};
	
	template<class T> struct Rep : public RepBase{
		T t;
	};
	
	RepBase *_rep;
	
	void retain()const{
		++_rep->refs;
	}
	
	void release(){
		if( !--_rep->refs ) {}//delete rep;
	}
	
	public:
	
	template<class T> bbVariant( const T &t ):_rep( new Rep<T>( t ) ){
		retain();
	}
	
	bbVariant( const bbVariant &t ):_rep( t._rep ){
		retain();
	}
	
	bbVariant &operator=( const bbVariant &t ){
		t.retain();
		release();
		_rep=t._rep;
		return *this;
	}
	
	template<class T> T get()const{
		Rep<T> *p=dynamic_cast<Rep<T>*>( _rep );
		return p->t;
	}
};


#endif
