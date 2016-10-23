
#include "bbstring.h"
#include "bbarray.h"

bbString::Rep bbString::_nullRep;

namespace{

	int countUtf8Chars( const char *p,int sz ){
	
		const char *e=p+sz;
	
		int n=0;
	
		while( p!=e ){
			int c=*p++;
			
			if( c & 0x80 ){
				if( (c & 0xe0)==0xc0 ){
					if( p==e || (p[0] & 0xc0)!=0x80 ) return -1;
					p+=1;
				}else if( (c & 0xf0)==0xe0 ){
					if( p==e || p+1==e || (p[0] & 0xc0)!=0x80 || (p[1] & 0xc0)!=0x80 ) return -1;
					p+=2;
				}else{
					return -1;
				}
			}
			n+=1;
		}
		return n;
	}
	
	int countNullTerminatedUtf8Chars( const char *p,int sz ){
	
		const char *e=p+sz;
	
		int n=0;
	
		while( p!=e && *p ){
			int c=*p++;
			
			if( c & 0x80 ){
				if( (c & 0xe0)==0xc0 ){
					if( p==e || (p[0] & 0xc0)!=0x80 ) return -1;
					p+=1;
				}else if( (c & 0xf0)==0xe0 ){
					if( p==e || p+1==e || (p[0] & 0xc0)!=0x80 || (p[1] & 0xc0)!=0x80 ) return -1;
					p+=2;
				}else{
					return -1;
				}
			}
			n+=1;
		}
		return n;
	}
	
	void charsToUtf8( const bbChar *p,int n,char *dst,int size ){
	
		char *end=dst+size;
		
		const bbChar *e=p+n;
		
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
	
	void utf8ToChars( const char *p,bbChar *dst,int n ){
	
		while( n-- ){
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
			*dst++=c;
		}

	}
	
}

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

bbString::bbString( const void *p ){

	const char *cp=(const char*)p;

	if( !cp ){
		_rep=&_nullRep;
		return;
	}

	int sz=strlen( cp );

	int n=countNullTerminatedUtf8Chars( cp,sz );

	if( n==-1 || n==sz ){
		_rep=Rep::create( cp,sz );
		return;
	}
	_rep=Rep::alloc( n );
	utf8ToChars( cp,_rep->data,n );
}

bbString::bbString( const void *p,int sz ){

	const char *cp=(const char*)p;

	if( !cp ){
		_rep=&_nullRep;
		return;
	}

	int n=countUtf8Chars( cp,sz );

	if( n==-1 || n==sz ){
		_rep=Rep::create( cp,sz );
		return;
	}
	_rep=Rep::alloc( n );
	utf8ToChars( cp,_rep->data,n );
}

void bbString::toCString( void *buf,int size )const{

	charsToUtf8( _rep->data,_rep->length,(char*)buf,size );
}

void bbString::toWString( void *buf,int size )const{

	size=size/sizeof(wchar_t);
	if( size<=0 ) return;
	
	int sz=length();
	if( sz>size ) sz=size;
	
	for( int i=0;i<sz;++i ) ((wchar_t*)buf)[i]=data()[i];
	
	if( sz<size ) ((wchar_t*)buf)[sz]=0;
}

const char *bbString::c_str()const{

	static int _sz;
	static char *_tmp;
	
	int sz=utf8Length()+1;
	if( sz>_sz ){
		free( _tmp );
		_tmp=(char*)malloc( _sz=sz );
	}
	toCString( _tmp,sz );
	return _tmp;
}

bbString bbString::fromChar( int chr ){
	wchar_t chrs[]={ wchar_t(chr) };
	return bbString( chrs,1 );
}

bbArray<bbString> bbString::split( bbString sep )const{

	if( !sep.length() ){
		bbArray<bbString> bits=bbArray<bbString>( length() );
		for( int i=0;i<length();++i ){
			bits[i]=bbString( &data()[i],1 );
		}
		return bits;
	}
	
	int i=0,i2,n=1;
	while( (i2=find( sep,i ))!=-1 ){
		++n;
		i=i2+sep.length();
	}
	bbArray<bbString> bits=bbArray<bbString>( n );
	if( n==1 ){
		bits[0]=*this;
		return bits;
	}
	i=0;n=0;
	while( (i2=find( sep,i ))!=-1 ){
		bits[n++]=slice( i,i2 );
		i=i2+sep.length();
	}
	bits[n]=slice( i );
	return bits;
}

bbString bbString::join( bbArray<bbString> bits )const{

	if( bits.length()==0 ) return bbString();
	if( bits.length()==1 ) return bits[0];
	
	int len=length() * (bits.length()-1);
	for( int i=0;i<bits.length();++i ) len+=bits[i].length();
	
	Rep *rep=Rep::alloc( len );
	bbChar *p=rep->data;

	p=t_memcpy( p,bits[0].data(),bits[0].length() );
	
	for( int i=1;i<bits.length();++i ){
		p=t_memcpy( p,data(),length() );
		p=t_memcpy( p,bits[i].data(),bits[i].length() );
	}
	
	return rep;
}

