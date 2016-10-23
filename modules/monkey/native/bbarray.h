
#ifndef BB_ARRAY_H
#define BB_ARRAY_H

#include "bbgc.h"

template<class T,int D> struct bbArray{

	struct Rep : public bbGCNode{
	
		int _sizes[D];
		T _data[0];
		
		Rep(){
			memset( _sizes,0,sizeof(_sizes) );
		}
			
		Rep( int sizes[] ){
			bbGC::beginCtor( this );
				
			memcpy( _sizes,sizes,D*sizeof(int) );
				
			for( int i=0;i<_sizes[D-1];++i ) new( &_data[i] ) T();
		}
			
		~Rep(){
			for( int i=0;i<_sizes[D-1];++i ) _data[i].~T();
		}
	
		virtual const char *typeName()const{
			return "bbArray::Rep";
		}
			
		virtual void gcMark(){
			for( int i=0;i<_sizes[D-1];++i ) bbGCMark( _data[i] );
		}
	};
	
	Rep *_rep=nullptr;

	bbArray(){
	}
		
	template<class...Args> explicit bbArray( Args...args ){
		
		int sizes[]{ args... };
		for( int i=1;i<D;++i ) sizes[i]*=sizes[i-1];
			
		if( !sizes[D-1] ) return;
			
		bbGCNode *p=bbGC::alloc( sizeof( Rep )+sizes[D-1]*sizeof(T) );
	
		_rep=new( p ) Rep( sizes );
			
		bbGC::endCtor( _rep );
	}
		
	template<class...Args> explicit bbArray( std::initializer_list<T> init,Args...args ){
		
		int sizes[]{ args... };
		for( int i=1;i<D;++i ) sizes[i]*=sizes[i-1];
			
		if( !sizes[D-1] ) return;
			
		bbGCNode *p=bbGC::alloc( sizeof( Rep )+sizes[D-1]*sizeof(T) );
			
		_rep=new( p ) Rep( sizes );
			
		int i=0;
		for( auto it=init.begin();it!=init.end();++it ) _rep->_data[i++]=*it;
			
		bbGC::endCtor( _rep );
	}
		
	T *data(){
		return _rep->_data;
	}
		
	const T *data()const{
		return _rep->_data;
	}
		
	int length()const{
		return _rep ? _rep->_sizes[D-1] : 0;
	}
		
	int size( int q )const{
		bbDebugAssert( q>=0 && q<D,"Array dimension out of range" );
			
		return _rep ? (q ? _rep->_sizes[q]/_rep->_sizes[q-1] : _rep->_sizes[0]) : 0;
	}
		
	T &operator[]( int index ){
		bbDebugAssert( index>=0 && index<length(),"Array index out of range" );
			
		return data()[index];
	}
	
	T &at( int index ){
		bbDebugAssert( index>=0 && index<length(),"Array index out of range" );
				
		return data()[index];
	}
		
	//slower N-D version
	template<class...Args> T &at( Args...args ){
		
		const int indices[]{args...};
			
		int index=indices[0];
		bbDebugAssert( index>=0 && _rep,"Array index out of range" );
			
		for( int i=1;i<D;++i ){
			bbDebugAssert( indices[i]>=0 && index<_rep->_sizes[i-1],"Array index out of range" );
				
			index+=indices[i]*_rep->_sizes[i-1];
		}
			
		bbDebugAssert( index<length(),"Array index out of range" );
			
		return data()[index];
	}
		
	operator bool()const{
		
		return _rep;
	}
		
	bbArray<T,1> slice( int from )const{
	
		return slice( from,length() );
	}
		
	bbArray<T,1> slice( int from,int term )const{
		
		int length=this->length();
			
		if( from<0 ){
			from+=length;
			if( from<0 ) from=0;
		}else if( from>length ){
			from=length;
		}
			
		if( term<0 ){
			term+=length;
			if( term<from ) term=from;
		}else if( term<from ){
			term=from;
		}else if( term>length ){
			term=length;
		}
			
		int newlen=term-from;
			
		bbArray<T,1> r{newlen};
			
		for( int i=0;i<newlen;++i ) r.data()[i]=data()[from+i];
			
		return r;
	}
	
	bbArray<T,1> resize( int newLength )const{
		bbDebugAssert( newLength>=0,"Array Resize new length must not be negative" );
			
		int ncopy=length();
		if( ncopy>newLength ) ncopy=newLength;
	
		auto r=bbArray<T,1>( newLength );
			
		for( int i=0;i<ncopy;++i ) r.data()[i]=data()[i];
			
		return r;
	}
		
	void copyTo( bbArray<T,1> dst,int offset,int dstOffset,int count )const{
		bbDebugAssert( offset>=0 && dstOffset>=0 && count>=0 && offset+count<=length() && dstOffset+count<=dst.length(),"Array CopyTo parameters out of range" );
			
		if( dst._rep==_rep && dstOffset>offset ){
			for( int i=count-1;i>=0;--i ) dst.data()[dstOffset+i]=data()[offset+i];
		}else{
			for( int i=0;i<count;++i ) dst.data()[dstOffset+i]=data()[offset+i];
		}
	}
};

template<class T,int D> bbString bbDBType( bbArray<T,D> *p ){
	return bbDBType<T>()+"[]";
}

template<class T,int D> bbString bbDBValue( bbArray<T,D> *p ){
	char buf[64];
	sprintf( buf,"@%p",p->_rep );
	return buf;
}

template<class T,int D> void bbGCMark( bbArray<T,D> arr ){
	bbGC::enqueue( arr._rep );
}

#endif
