
#include "glue.h"

namespace tinyxml2{

	bbString bbAttributeName( XMLAttribute *attribute ){
		return bbString::fromCString( attribute->Name() );
	}
	
	bbString bbAttributeValue( XMLAttribute *attribute ){
		return bbString::fromCString( attribute->Value() );
	}
	
	XMLAttribute *bbAttributeNext( XMLAttribute *attribute ){
		return const_cast<XMLAttribute*>( attribute->Next() );
	}
	
	bbString bbNodeValue( XMLNode *node ){
		return bbString::fromCString( node->Value() );
	}
	
	bbString bbElementName( XMLElement *element ){
		return bbString::fromCString( element->Name() );
	}
	
	bbString bbElementAttribute( XMLElement *element,bbString name,bbString value ){
		bbCString cstr( value );
		const char *p=0;
		if( value.length() ) p=cstr;
		return bbString::fromCString( element->Attribute( bbCString( name ),p ) );
	}
	
	XMLAttribute *bbElementFirstAttribute( XMLElement *element ){
		return const_cast<XMLAttribute*>( element->FirstAttribute() );
	}
	
	bbString bbElementGetText( XMLElement *element ){
		return bbString::fromCString( element->GetText() );
	}

	void bbDocumentDestroy( XMLDocument *doc ){
		delete doc;
	}
}

