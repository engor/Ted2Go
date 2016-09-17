
Namespace tinyxml2

#Import "native/tinyxml2.cpp"
#Import "native/tinyxml2.h"
#Import "native/glue.h"

Extern

enum XMLError="tinyxml2::"

    XML_SUCCESS
    XML_NO_ATTRIBUTE
    XML_WRONG_ATTRIBUTE_TYPE
    XML_ERROR_FILE_NOT_FOUND
    XML_ERROR_FILE_COULD_NOT_BE_OPENED
    XML_ERROR_FILE_READ_ERROR
    XML_ERROR_ELEMENT_MISMATCH
    XML_ERROR_PARSING_ELEMENT
    XML_ERROR_PARSING_ATTRIBUTE
    XML_ERROR_IDENTIFYING_TAG
    XML_ERROR_PARSING_TEXT
    XML_ERROR_PARSING_CDATA
    XML_ERROR_PARSING_COMMENT
    XML_ERROR_PARSING_DECLARATION
    XML_ERROR_PARSING_UNKNOWN
    XML_ERROR_EMPTY_DOCUMENT
    XML_ERROR_MISMATCHED_ELEMENT
    XML_ERROR_PARSING
    XML_CAN_NOT_CONVERT_TEXT
    XML_NO_TEXT_NODE

End

Class XMLAttribute Extends Void="tinyxml2::XMLAttribute"

	Method Name:String() Extension="tinyxml2::bbAttributeName"

	Method Value:String() Extension="tinyxml2::bbAttributeValue"
	
	Method NextAttribute:XMLAttribute() Extension="tinyxml2::bbAttributeNext"

End

Class XMLNode Extends Void="tinyxml2::XMLNode"

	Method GetDocument:XMLDocument()
	
	Method ToElement:XMLElement()
	
	Method ToText:XMLText()
	
	Method ToComment:XMLComment()
	
	Method ToDocument:XMLDocument()
	
	Method ToDeclaration:XMLDeclaration()
	
	Method ToUnknown:XMLUnknown()
	
	Method NoChildren:Bool()

	Method Parent:XMLNode()
	
	Method FirstChild:XMLNode()
	
	Method FirstChildElement:XMLElement()
	
	Method LastChild:XMLNode()
	
	Method LastChildElement:XMLElement()
	
	Method PreviousSibling:XMLNode()
	
	Method PreviousSiblingElement:XMLElement()
	
	Method NextSibling:XMLNode()
	
	Method NextSiblingElement:XMLElement()
	
	Method Value:String() Extension="tinyxml2::bbNodeValue"
End

Class XMLDocument Extends XMLNode="tinyxml2::XMLDocument"

	Method Parse:XMLError( xml:CString )
	
	Method PrintDocument()="Print"
	
	Method Error:Bool()
	
	Method ErrorID:XMLError()
	
	Method Destroy() Extension="tinyxml2::bbDocumentDestroy"
End

Class XMLElement Extends XMLNode="tinyxml2::XMLElement"

	Method Name:String() Extension="tinyxml2::bbElementName"
	
	Method Attribute:String( name:String,value:String="" ) Extension="tinyxml2::bbElementAttribute"
	
	Method IntAttribute:Int( name:CString )
	
	Method UnsignedAttribute:UInt( name:CString )
	
	Method BoolAttribute:Bool( name:CString )
	
	Method DoubleAttribute:Double( name:CString )
	
	Method FloatAttribute:Float( name:CString )
	
	Method QueryIntAttribute:XMLError( name:CString,value:Int Ptr )
	
	Method QueryUnsignedAttribute:XMLError( name:CString,value:UInt Ptr )
	
	Method QueryBoolAttribute:XMLError( name:CString,value:Bool Ptr )
	
	Method QueryDoubleAttribute:XMLError( name:CString,value:Double Ptr )
	
	Method QueryFloatAttribute:XMLError( name:CString,value:Float Ptr )
	
	Method QueryAttribute:Int( name:CString,value:Int Ptr )
	
	Method FirstAttribute:XMLAttribute() Extension="tinyxml2::bbElementFirstAttribute"

	Method GetText:String() Extension="tinyxml2::bbElementGetText"
	
End

Class XMLComment Extends XMLNode="tinyxml2::XMLComment"
End

Class XMLDeclaration Extends XMLNode="tinyxml2::XMLDeclaration"
End

Class XMLText Extends XMLNode="tinyxml2::XMLText"

	Method CData:Bool()
	
End

Class XMLUnknown Extends XMLNode="tinyxml2::XMLUnknown"
End
