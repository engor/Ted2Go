
#include "bbstring.h"
#include "bbarray.h"

bbString::Rep bbString::_nullRep;

int bbString::utf8Length()const{

	const bbChar *p=data();
	const bbChar *e=p+length();
	
	int n=0;
	
	while( p<e ){
		bbChar c=*p++;
		if( c<0x80 ){
			n+=1;
		}else if( c<0x800 ){
			n+=2;
		}else{
			n+=3;
		}
	}

	return n;
}

void bbString::toCString( void *buf,int size )const{
	if( size<=0 ) return;
	
	int sz=length();
	if( sz>size ) sz=size;
	
	for( int i=0;i<sz;++i ) ((char*)buf)[i]=data()[i];
	
	if( sz<size ) ((char*)buf)[sz]=0;
}

void bbString::toWString( void *buf,int size )const{

	size=size/sizeof(wchar_t);
	if( size<=0 ) return;
	
	int sz=length();
	if( sz>size ) sz=size;
	
	for( int i=0;i<sz;++i ) ((wchar_t*)buf)[i]=data()[i];
	
	if( sz<size ) ((wchar_t*)buf)[sz]=0;
}

void bbString::toUtf8String( void *buf,int size )const{

	char *dst=(char*)buf;
	char *end=dst+size;
	
	const bbChar *p=data();
	const bbChar *e=p+length();
	
	while( p<e && dst<end ){
		bbChar c=*p++;
		if( c<0x80 ){
			*dst++=c;
		}else if( c<0x800 ){
			if( dst+2>end ) break;
			*dst++=0xc0 | (c>>6);
			*dst++=0x80 | (c & 0x3f);
		}else{
			if( dst+3>end ) break;
			*dst++=0xe0 | (c>>12);
			*dst++=0x80 | ((c>>6) & 0x3f);
			*dst++=0x80 | (c & 0x3f);
		}
	}
	if( dst<end ) *dst++=0;
}

const char *bbString::c_str()const{

	static int _sz;
	static char *_tmp;
	
	int sz=length()+1;
	if( sz>_sz ){
		free( _tmp );
		_tmp=(char*)malloc( _sz=sz );
	}
	
	for( int i=0;i<length();++i ) _tmp[i]=data()[i];
	_tmp[length()]=0;
	return _tmp;
}

bbString bbString::fromChar( int chr ){
	bbChar buf[]={(bbChar)chr,0};
	return buf;
}

bbString bbString::fromCString( const void *data,int size ){
	if( !data ) return bbString();
	const char *p=(const char*)data;
	const char *e=p;
	while( e!=p+size && *e ) ++e;
	return bbString( p,e-p );
}

bbString bbString::fromWString( const void *data,int size ){
	if( !data ) return bbString();
	size/=sizeof(wchar_t);
	const wchar_t *p=(const wchar_t*)data;
	const wchar_t *e=p;
	while( e!=p+size && *e ) ++e;
	return bbString( p,e-p );
}

bbString bbString::fromUtf8String( const void *data,int size ){
	if( !data ) return bbString();

	const char *p=(const char*)data;
	const char *e=p+size;

	int len=0;
		
	while( p!=e && *p ){
		int c=*p++;
		
		if( c & 0x80 ){
			if( (c & 0xe0)==0xc0 ){
				if( p==e || (p[0] & 0xc0)!=0x80 ) break;
				p+=1;
			}else if( (c & 0xf0)==0xe0 ){
				if( p+1==e || (p[0] & 0xc0)!=0x80 || (p[1] & 0xc0)!=0x80 ) break;
				p+=2;
			}else{
				break;
			}
		}
		len+=1;
	}
	
	p=(const char*)data;
	
	Rep *rep=Rep::alloc( len );
	bbChar *d=rep->data;
	
	while( len-- ){
		int c=*p++;
		
		if( c & 0x80 ){
			if( (c & 0xe0)==0xc0 ){
				c=((c & 0x1f)<<6) | (p[0] & 0x3f);
				p+=1;
			}else if( (c & 0xf0)==0xe0 ){
				c=((c & 0x0f)<<12) | ((p[0] & 0x3f)<<6) | (p[1] & 0x3f);
				p+=2;
			}
		}
		*d++=c;
	}
	
	return rep;
}

bbArray<bbString> *bbString::split( bbString sep )const{

	if( !sep.length() ){
		bbArray<bbString> *bits=bbArray<bbString>::create( length() );
		for( int i=0;i<length();++i ){
			bits->at(i)=bbString( &data()[i],1 );
		}
		return bits;
	}
	
	int i=0,i2,n=1;
	while( (i2=find( sep,i ))!=-1 ){
		++n;
		i=i2+sep.length();
	}
	bbArray<bbString> *bits=bbArray<bbString>::create( n );
	if( n==1 ){
		bits->at(0)=*this;
		return bits;
	}
	i=0;n=0;
	while( (i2=find( sep,i ))!=-1 ){
		bits->at(n++)=slice( i,i2 );
		i=i2+sep.length();
	}
	bits->at(n)=slice( i );
	return bits;
}

bbString bbString::join( bbArray<bbString> *bits )const{

	if( bits->length()==0 ) return bbString();
	if( bits->length()==1 ) return bits->at(0);
	
	int len=length() * (bits->length()-1);
	for( int i=0;i<bits->length();++i ) len+=bits->at(i).length();
	
	Rep *rep=Rep::alloc( len );
	bbChar *p=rep->data;

	p=t_memcpy( p,bits->at(0).data(),bits->at(0).length() );
	
	for( int i=1;i<bits->length();++i ){
		p=t_memcpy( p,data(),length() );
		p=t_memcpy( p,bits->at(i).data(),bits->at(i).length() );
	}
	
	return rep;
}

