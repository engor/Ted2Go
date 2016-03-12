
#ifndef BB_ARRAY_H
#define BB_ARRAY_H

#include "bbtypes.h"
#include "bbgc.h"

template<class T,int D=1> class bbArray : public bbGCNode{

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
	
	const char *typeName(){
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
	T &at( int index )const{
		if( index<0 || index>=length() ) puts( "Out of range" );
		return data()[index];
	}
	
	template<class...Args> T &at( Args...args ){
	
		//debug only...
		if( !this ) puts( "Out of range" );
		
		int indices[]{args...};
		int index=indices[0];
		for( int i=1;i<D;++i ){
			if( index>=_sizes[i-1] ) puts( "Out of range!" );
			index+=indices[i]*_sizes[i-1];
		}
		if( index>=length() ) puts( "Out of range" );
		return data()[index];
	}
	
	T &get( int index ){
		if( index<0 || index>=length() ) puts( "Out of range" );
		return data()[index];
	}
	
	operator bool()const{
		return length();
	}
};

// ***** OLD *****

/*
template<class T,int D=1> class bbArray{

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
		
		virtual void gcMark(){
			for( int i=0;i<_sizes[D-1];++i ) bbGCMark( _data[i] );	
		}
		
		const char *typeName(){
			return "bbArray";
		}
		
	};
	
	Rep *_rep=nullptr;
	
	friend void bbGCMark( bbArray &t ){

		bbGC::enqueue( t._rep );
	}
	
	void enqueue(){
	
#if BBGC_INCREMENTAL
		bbGC::enqueue( _rep );
#endif
	}

	public:
	
	bbArray(){
	}
	
	bbArray( const bbArray &p ):_rep( p._rep ){

		enqueue();
	}
	
	template<class...Args> bbArray( Args...args ){
	
		int sizes[]{ args... };
		for( int i=1;i<D;++i ) sizes[i]*=sizes[i-1];
		
		if( !sizes[D-1] ) return;
		
		bbGCNode *p=bbGC::alloc( sizeof( Rep )+sizes[D-1]*sizeof(T) );
		
		_rep=new( p ) Rep( sizes );
		
		bbGC::endCtor( _rep );
	}
	
	template<class C,class...Args> bbArray( const C *init,Args...args ){
	
		int sizes[]{ args... };
		for( int i=1;i<D;++i ) sizes[i]*=sizes[i-1];
		
		if( !sizes[D-1] ) return;
		
		bbGCNode *p=bbGC::alloc( sizeof( Rep )+sizes[D-1]*sizeof(T) );
		
		_rep=new( p ) Rep( sizes );
		
		for( int i=0;i<sizes[D-1];++i ) _rep->_data[i]=*init++;
		
		bbGC::endCtor( _rep );
	}
	
	template<class C,class...Args> bbArray( std::initializer_list<C> init,Args...args ){
	
		int sizes[]{ args... };
		for( int i=1;i<D;++i ) sizes[i]*=sizes[i-1];
		
		if( !sizes[D-1] ) return;
		
		bbGCNode *p=bbGC::alloc( sizeof( Rep )+sizes[D-1]*sizeof(T) );
		
		_rep=new( p ) Rep( sizes );
		
		int i=0;
		for( auto it=init.begin();it!=init.end();++it ) _rep->_data[i++]=*it;
		
		bbGC::endCtor( _rep );
	}
	
	bbArray &operator=( const bbArray &p ){
		_rep=p._rep;
		
		enqueue();
		
		return *this;
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
		return _rep ? (q ? _rep->_sizes[q]/_rep->_sizes[q-1] : _rep->_sizes[0]) : 0;
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
		bbArray<T,1> p( newlen );
		for( int i=0;i<newlen;++i ) p.data()[i]=data()[from+i];
		return p;
	}

	T &operator[]( int index ){
		if( index<0 || index>=length() ) puts( "OUT OF RANGE" );
		return data()[index];
	}
	
	const T &operator[]( int index )const{
		if( index<0 || index>=length() ) puts( "OUT OF RANGE" );
		return data()[index];
	}
	
	template <class...Args> T &at( Args...args ){
		int indices[]{args...};
		int index=indices[0];
		for( int i=1;i<D;++i ){
			if( index>=_rep->_sizes[i-1] ) puts( "Out of range!" );
			index+=indices[i]*_rep->_sizes[i-1];
		}
		if( index>=length() ) puts( "Out of range" );
		return data()[index];
	}
	
	T &get( int index ){
		if( index<0 || index>=length() ) puts( "Out of range" );
		return data()[index];
	}
	
	operator bool()const{
		return length();
	}
};
*/

#endif
