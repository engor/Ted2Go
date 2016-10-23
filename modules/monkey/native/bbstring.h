
#ifndef BB_STRING_H
#define BB_STRING_H

#include "bbtypes.h"
#include "bbassert.h"
#include "bbmemory.h"

class bbCString;

class bbString{

	struct Rep{
		int refs;
		int length;
		bbChar data[0];
		
		static Rep *alloc( int length ){
			if( !length ) return &_nullRep;
			Rep *rep=(Rep*)bbMalloc( sizeof(Rep)+length*sizeof(bbChar) );
			rep->refs=1;
			rep->length=length;
			return rep;
		}
		
		template<class C> static Rep *create( const C *p,int length ){
			Rep *rep=alloc( length );
			for( int i=0;i<length;++i ) rep->data[i]=p[i];
			return rep;
		}
		
		template<class C> static Rep *create( const C *p ){
			const C *e=p;
			while( *e ) ++e;
			return create( p,e-p );
		}
	};
	
	Rep *_rep;

	static Rep _nullRep;
	
	void retain()const{
		++_rep->refs;
	}
	
	void release(){
		if( !--_rep->refs && _rep!=&_nullRep ) bbFree( _rep );
	}
	
	bbString( Rep *rep ):_rep( rep ){
	}
	
	template<class C> static int t_memcmp( const C *p1,const C *p2,int count ){
		return memcmp( p1,p2,count*sizeof(C) );
	}

	//returns END of dst!	
	template<class C> static C *t_memcpy( C *dst,const C *src,int count ){
		return (C*)memcpy( dst,src,count*sizeof(C) )+count;
	}
	
	public:
	
	const char *c_str()const;
	
	bbString():_rep( &_nullRep ){
	}
	
	bbString( const bbString &s ):_rep( s._rep ){
		retain();
	}
	
	bbString( const void *data );
	
	bbString( const void *data,int length );
	
	bbString( const bbChar *data ):_rep( Rep::create( data ) ){
	}
	
	bbString( const bbChar *data,int length ):_rep( Rep::create( data,length ) ){
	}

	bbString( const wchar_t *data ):_rep( Rep::create( data ) ){
	}
	
	bbString( const wchar_t *data,int length ):_rep( Rep::create( data,length ) ){
	}

	explicit bbString( bbInt n ){
		char data[64];
		sprintf( data,"%i",n );
		_rep=Rep::create( data );
	}
	
	explicit bbString( bbUInt n ){
		char data[64];
		sprintf( data,"%u",n );
		_rep=Rep::create( data );
	}
	
	explicit bbString( bbLong n ){
		char data[64];
		sprintf( data,"%lld",n );
		_rep=Rep::create( data );
	}
	
	explicit bbString( bbULong n ){
		char data[64];
		sprintf( data,"%llu",n );
		_rep=Rep::create( data );
	}
	
	explicit bbString( float n ){
		char data[64];
		sprintf( data,"%.9g",n );
		_rep=Rep::create( data );
	}
	
	explicit bbString( double n ){
		char data[64];
		sprintf( data,"%.17g",n );
		_rep=Rep::create( data );
	}
	
	~bbString(){
		release();
	}
	
	const bbChar *data()const{
		return _rep->data;
	}
	
	int length()const{
		return _rep->length;
	}
	
	bbChar operator[]( int index )const{
		bbDebugAssert( index>=0 && index<length(),"String character index out of range" );
		return data()[index];
	}
	
	bbString operator+()const{
		return *this;
	}
	
	bbString operator-()const{
		Rep *rep=Rep::alloc( length() );
		const bbChar *p=data()+length();
		for( int i=0;i<rep->length;++i ) rep->data[i]=*--p;
		return rep;
	}
	
	bbString operator+( const bbString &str ){
	
		if( !length() ) return str;
		if( !str.length() ) return *this;
		
		Rep *rep=Rep::alloc( length()+str.length() );
		t_memcpy( rep->data,data(),length() );
		t_memcpy( rep->data+length(),str.data(),str.length() );

		return rep;
	}
	
	bbString operator+( const char *str ){
		return operator+( bbString( str ) );
	}
	
	bbString operator*( int n ){
		Rep *rep=Rep::alloc( length()*n );
		bbChar *p=rep->data;
		for( int j=0;j<n;++j ){
			for( int i=0;i<_rep->length;++i ) *p++=data()[i];
		}
		return rep;
	}
	
	bbString &operator=( const bbString &str ){
		str.retain();
		release();
		_rep=str._rep;
		return *this;
	}
	
	template<class C> bbString &operator=( const C *data ){
		release();
		_rep=Rep::create( data );
		return *this;
	}
	
	bbString &operator+=( const bbString &str ){
		*this=*this+str;
		return *this;
	}
	
	bbString &operator+=( const char *str ){
		return operator+=( bbString( str ) );
	}
	
	int find( bbString str,int from=0 )const{
		if( from<0 ) from=0;
		for( int i=from;i<=length()-str.length();++i ){
			if( !t_memcmp( data()+i,str.data(),str.length() ) ) return i;
		}
		return -1;
	}
	
	int findLast( const bbString &str,int from=0 )const{
		if( from<0 ) from=0;
		for( int i=length()-str.length();i>=from;--i ){
			if( !t_memcmp( data()+i,str.data(),str.length() ) ) return i;
		}
		return -1;
	}
	
	bool contains( const bbString &str )const{
		return find( str )!=-1;
	}
	
	bbString slice( int from )const{
		int length=this->length();
		if( from<0 ){
			from+=length;
			if( from<0 ) from=0;
		}else if( from>length ){
			from=length;
		}
		if( !from ) return *this;
		return bbString( data()+from,length-from );
	}
	
	bbString slice( int from,int term )const{
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
		if( !from && term==length ) return *this;
		return bbString( data()+from,term-from );
	}

	bbString left( int count )const{
		return slice( 0,count );
	}
	
	bbString right( int count )const{
		return slice( -count );
	}
	
	bbString mid( int from,int count )const{
		return slice( from,from+count );
	}
	
	bool startsWith( const bbString &str )const{
		if( str.length()>length() ) return false;
		return t_memcmp( data(),str.data(),str.length() )==0;
	}
	
	bool endsWith( const bbString &str )const{
		if( str.length()>length() ) return false;
		return t_memcmp( data()+(length()-str.length()),str.data(),str.length() )==0;
	}
	
	bbString toUpper()const{
		Rep *rep=Rep::alloc( length() );
		for( int i=0;i<length();++i ) rep->data[i]=std::toupper( data()[i] );
		return rep;
	}
	
	bbString toLower()const{
		Rep *rep=Rep::alloc( length() );
		for( int i=0;i<length();++i ) rep->data[i]=std::tolower( data()[i] );
		return rep;
	}
	
	bbString capitalize()const{
		if( !length() ) return &_nullRep;
		Rep *rep=Rep::alloc( length() );
		rep->data[0]=std::toupper( data()[0] );
		for( int i=1;i<length();++i ) rep->data[i]=data()[i];
		return rep;
	}
	
	bbString trim()const{
		const bbChar *beg=data();
		const bbChar *end=data()+length();
		while( beg!=end && *beg<=32 ) ++beg;
		while( beg!=end && *(end-1)<=32 ) --end;
		if( end-beg==length() ) return *this;
		return bbString( beg,end-beg );
	}
	
	bbString trimStart()const{
		const bbChar *beg=data();
		const bbChar *end=data()+length();
		while( beg!=end && *beg<=32 ) ++beg;
		if( end-beg==length() ) return *this;
		return bbString( beg,end-beg );
	}
	
	bbString trimEnd()const{
		const bbChar *beg=data();
		const bbChar *end=data()+length();
		while( beg!=end && *(end-1)<=32 ) --end;
		if( end-beg==length() ) return *this;
		return bbString( beg,end-beg );
	}
	
	bbString dup( int n )const{
		Rep *rep=Rep::alloc( length()*n );
		bbChar *p=rep->data;
		for( int j=0;j<n;++j ){
			for( int i=0;i<_rep->length;++i ) *p++=data()[i];
		}
		return rep;
	}
	
	bbString replace( const bbString &str,const bbString &repl )const{
	
		int n=0;
		for( int i=0;; ){
			i=find( str,i );
			if( i==-1 ) break;
			i+=str.length();
			++n;
		}
		if( !n ) return *this;
		
		Rep *rep=Rep::alloc( length()+n*(repl.length()-str.length()) );
		
		bbChar *dst=rep->data;
		
		for( int i=0;; ){
		
			int i2=find( str,i );
			if( i2==-1 ){
				t_memcpy( dst,data()+i,(length()-i) );
				break;
			}
			
			t_memcpy( dst,data()+i,(i2-i) );
			dst+=(i2-i);
			
			t_memcpy( dst,repl.data(),repl.length() );
			dst+=repl.length();
			
			i=i2+str.length();
		}
		return rep;
	}
	
	bbArray<bbString> split( bbString sep )const;
	
	bbString join( bbArray<bbString> bits )const;
	
	int compare( const bbString &t )const{
		int len=length()<t.length() ? length() : t.length();
		for( int i=0;i<len;++i ){
			if( int n=data()[i]-t.data()[i] ) return n;
		}
		return length()-t.length();
	}
	
	bool operator<( const bbString &t )const{
		return compare( t )<0;
	}
	
	bool operator>( const bbString &t )const{
		return compare( t )>0;
	}
	
	bool operator<=( const bbString &t )const{
		return compare( t )<=0;
	}
	
	bool operator>=( const bbString &t )const{
		return compare( t )>=0;
	}
	
	bool operator==( const bbString &t )const{
		return compare( t )==0;
	}
	
	bool operator!=( const bbString &t )const{
		return compare( t )!=0;
	}
	
	operator bbBool()const{
		return length();
	}
	
	operator bbInt()const{
		return std::atoi( c_str() );
	}
	
	operator bbByte()const{
		return operator bbInt() & 0xff;
	}
	
	operator bbUByte()const{
		return operator bbInt() & 0xffu;
	}
	
	operator bbShort()const{
		return operator bbInt() & 0xffff;
	}
	
	operator bbUShort()const{
		return operator bbInt() & 0xffffu;
	}
	
	operator bbUInt()const{
		bbUInt n;
		sscanf( c_str(),"%u",&n );
		return n;
	}
	
	operator bbLong()const{
		bbLong n;
		sscanf( c_str(),"%lld",&n );
		return n;
	}
	
	operator bbULong()const{
		bbULong n;
		sscanf( c_str(),"%llu",&n );
		return n;
	}
	
	operator float()const{
		return std::atof( c_str() );
	}
	
	operator double()const{
		return std::atof( c_str() );
	}
	
	int utf8Length()const;
	
	void toCString( void *buf,int size )const;

	void toWString( void *buf,int size )const;
	
	static bbString fromChar( int chr );
	
	static bbString fromCString( const void *data ){ return bbString( data ); }
	
	static bbString fromCString( const void *data,int size ){ return bbString( data,size ); }
	
	static bbString fromWString( const void *data ){ return bbString( (const wchar_t*)data ); }
	
	static bbString fromWString( const void *data,int size ){ return bbString( (const wchar_t*)data,size ); }
};

class bbCString{
	char *_data;
	
	public:

	bbCString( const bbString &str ){
		int size=str.utf8Length()+1;
		_data=(char*)malloc( size );
		str.toCString( _data,size );
	}
	
	~bbCString(){
		free( _data );
	}
	
	operator char*()const{
		return _data;
	}
	
	operator signed char*()const{
		return (signed char*)_data;
	}
	
	operator unsigned char*()const{
		return (unsigned char*)_data;
	}
};

class bbWString{
	wchar_t *_data;
	
	public:
	
	bbWString( const bbString &str ){
		int size=(str.length()+1)*sizeof(wchar_t);
		_data=(wchar_t*)malloc( size );
		str.toWString( _data,size );
	}
	
	~bbWString(){
		free( _data );
	}
	
	operator wchar_t*()const{
		return _data;
	}
};

template<class C> bbString operator+( const C *str,const bbString &str2 ){
	return bbString::fromCString( str )+str2;
}

inline bbString BB_T( const char *p ){
	return bbString::fromCString( p );
}

#endif
