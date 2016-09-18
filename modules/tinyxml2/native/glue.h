
#ifndef BB_TINYXML2_GLUE_H
#define BB_TINYXML2_GLUE_H

#include "tinyxml2.h"

#include <bbmonkey.h>

namespace tinyxml2{

	bbString bbAttributeName( XMLAttribute *attribute );
	
	bbString bbAttributeValue( XMLAttribute *attribute );
	
	XMLAttribute *bbAttributeNext( XMLAttribute *attribute );
	
	bbString bbNodeValue( XMLNode *node );
	
	bbString bbElementName( XMLElement *element );
	
	bbString bbElementAttribute( XMLElement *element,bbString name,bbString value );
	
	XMLAttribute *bbElementFirstAttribute( XMLElement *element );
	
	bbString bbElementGetText( XMLElement *element );

	void bbDocumentDestroy( XMLDocument *doc );
}

#endif
