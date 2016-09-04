
#ifndef BB_ARRAY_H
#define BB_ARRAY_H

#include "bbgc.h"
#include "bbdebug.h"
#include "bbobject.h"

template<class T,int D> class bbArray : public bbGCNode{

	int _sizes[D];
	T _data[0];
		
	bbArray(){
		memset( _sizes,0,sizeof(_sizes) );
	}
	
	bbArray( int sizes[] ){
		bbGC::beginCtor( this );
		
		memcpy( _sizes,sizes,D*sizeof(int) );
		
		for( int i=0;i<_sizes[D-1];++i ) new( &_data[i] ) T();
	}
	
	~bbArray(){
		for( int i=0;i<_sizes[D-1];++i ) _data[i].~T();
	}
	
	virtual void gcMark(){
		for( int i=0;i<_sizes[D-1];++i ) bbGCMark( _data[i] );	
	}
	
	public:
	
	virtual const char *typeName()const{
		return "bbArray";
	}
	
	template<class...Args> static bbArray *create( Args...args ){
	
		int sizes[]{ args... };
		for( int i=1;i<D;++i ) sizes[i]*=sizes[i-1];
		
		if( !sizes[D-1] ) return nullptr;
		
		bbGCNode *p=bbGC::alloc( sizeof( bbArray )+sizes[D-1]*sizeof(T) );
		
		bbArray *r=new( p ) bbArray( sizes );
		
		bbGC::endCtor( r );
		
		return r;
	}
	
	template<class C,class...Args> static bbArray *create( std::initializer_list<C> init,Args...args ){
	
		int sizes[]{ args... };
		for( int i=1;i<D;++i ) sizes[i]*=sizes[i-1];
		
		if( !sizes[D-1] ) return nullptr;
		
		bbGCNode *p=bbGC::alloc( sizeof( bbArray )+sizes[D-1]*sizeof(T) );
		
		bbArray *r=new( p ) bbArray( sizes );
		
		int i=0;
		for( auto it=init.begin();it!=init.end();++it ) r->_data[i++]=*it;
		
		bbGC::endCtor( r );
		
		return r;
	}
	
	T *data(){
		return _data;
	}
	
	const T *data()const{
		return _data;
	}
	
	int length()const{
		return this ? _sizes[D-1] : 0;
	}
	
	int size( int q )const{
		bbDebugAssert( q<D,"Array dimension out of range" );
		return this ? (q ? _sizes[q]/_sizes[q-1] : _sizes[0]) : 0;
	}
	
	bbArray<T,1> *slice( int from )const{
		return slice( from,length() );
	}
	
	bbArray<T,1> *slice( int from,int term )const{
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
		bbArray<T,1> *r=create( newlen );
		for( int i=0;i<newlen;++i ) r->data()[i]=data()[from+i];
		return r;
	}
	
	void copyTo( bbArray<T,1> *dst,int offset,int dstOffset,int count )const{
		int length=this->length();
		if( offset<0 ){
			offset=0;
		}else if( offset>length ){
			offset=length;
		}
		int dstLength=dst->length();
		if( dstOffset<0 ){
			dstOffset=0;
		}else if( dstOffset>dstLength ){
			dstOffset=dstLength;
		}

		if( offset+count>length ) count=length-offset;
		if( dstOffset+count>dstLength) count=dstLength-dstOffset;
		
		if( dst==this && dstOffset>offset ){
			for( int i=count-1;i>=0;--i ) dst->data()[dstOffset+i]=data()[offset+i];
		}else{
			for( int i=0;i<count;++i ) dst->data()[dstOffset+i]=data()[offset+i];
		}
	}
	
	//fast 1D version	
	T &at( int index ){
		bbDebugAssert( index>=0 && index<length(),"Array index out of range" );
		return data()[index];
	}
	
	//slower N-D version
	template<class...Args> T &at( Args...args ){
	
		const int indices[]{args...};
		
		int index=indices[0];
		bbDebugAssert( index>=0,"Array index out of range" );
		
		for( int i=1;i<D;++i ){
			bbDebugAssert( indices[i]>=0 && index<_sizes[i-1],"Array index out of range" );
			index+=indices[i]*_sizes[i-1];
		}
		
		bbDebugAssert( index<length(),"Array index out of range" );
		return data()[index];
	}
	
	T &get( int index ){
		if( index<0 || index>=length() ) puts( "Out of range" );
		return data()[index];
	}
	
	operator bool()const{
		return length();
	}
	
	void dbEmit(){
		int n=length();
		if( n>100 ) n=100;
		bbString t=bbDBType<T>();
		for( int i=0;i<n;++i ){
			bbString e=BB_T("[")+bbString( i )+"]:"+t+"="+bbDBValue( &at(i) );
			puts( e.c_str() );
		}
	}
};

template<class T,int N> bbString bbDBType( bbArray<T,N> **p ){
	return bbDBType<T>()+"[]";
}

template<class T,int N> bbString bbDBValue( bbArray<T,N> **p ){
	char buf[64];
	sprintf( buf,"@%p",*p );
	return buf;
}

#endif
