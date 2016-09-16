
#ifndef BB_TIMYXML2_GLUE_H
#define BB_TINYXML2_GLUE_H

#include "tinyxml2.h"

#include <bbmonkey.h>

namespace tinyxml2{

	bbString bbAttributeName( XMLAttribute *attribute ){
		return bbString::fromUtf8String( attribute->Name() );
	}
	
	bbString bbAttributeValue( XMLAttribute *attribute ){
		return bbString::fromUtf8String( attribute->Value() );
	}
	
	XMLAttribute *bbAttributeNext( XMLAttribute *attribute ){
		return const_cast<XMLAttribute*>( attribute->Next() );
	}
	
	bbString bbNodeValue( XMLNode *node ){
		return bbString::fromUtf8String( node->Value() );
	}
	
	bbString bbElementName( XMLElement *element ){
		return bbString::fromUtf8String( element->Name() );
	}
	
	bbString bbElementAttribute( XMLElement *element,bbString name,bbString value ){
		bbUtf8String cstr( value );
		const char *p=0;
		if( value.length() ) p=cstr;
		return bbString::fromUtf8String( element->Attribute( bbUtf8String( name ),p ) );
	}
	
	XMLAttribute *bbElementFirstAttribute( XMLElement *element ){
		return const_cast<XMLAttribute*>( element->FirstAttribute() );
	}
	
	bbString bbElementGetText( XMLElement *element ){
		return bbString::fromUtf8String( element->GetText() );
	}

	void bbDocumentDestroy( XMLDocument *doc ){
		delete doc;
	}
}

#endif
