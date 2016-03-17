
#include "bbtypes.h"

#include "bbstring.h"

namespace{

	bbString typeName( const char *&p );
	
	bbString funcName( const char *&p ){
	
		bbString retType=typeName( p ),argTypes;
		while( *p && *p!='E' ){
			if( argTypes.length() ) argTypes+=",";
			argTypes+=typeName( p );
		}
		if( *p ) ++p;
		
		return retType+"("+argTypes+")";
	}

	bbString arrayName( const char *&p ){
	
		int rank=1;
		if( *p>'0' && *p<='9' ) rank=(*p++)-'0';
		
		bbString e=typeName( p );
		
		return e+bbString( "[,,,,,,,,,",rank )+"]";
	}
	
	bbString className( const char *&p ){
		bbString name;
		
		const char *p0=p;

		for( ;; ){
		
			if( !*p ) return name+bbString( p0,p-p0 );
			
			if( *p++!='_' ) continue;
			
			name+=bbString( p0,p-p0-1 );
			
			char c=*p++;
			
			if( c=='0' ){
			
				name+="_";
				
			}else if( c=='1' ){

				bbString types;
				while( *p && *p!='E' ){
					if( types.length() ) types+=",";
					types+=typeName( p );
				}
				name+="<"+types+">";
				if( !*p ) return name;
				++p;
				
			}else if( c=='2' ){
			
				return name;
				
			}else{
			
				name+=".";
				p0=p-1;
				continue;
			}
			
			p0=p;
		}
	}
	
	bbString typeName( const char *&p ){
		switch( *p++ ){
		case 'v':return "Void";
		case 'z':return "Bool";
		case 'i':return "Int";
		case 'f':return "Float";
		case 's':return "String";
		case 'F':return funcName( p );
		case 'A':return arrayName( p );
		case 'T':return className( p );
		case 'P':return typeName( p )+" Ptr";
		}
		return "?!?!?";
	}
}

bbString bbTypeName( const char *type ){
	return typeName( type );
}
