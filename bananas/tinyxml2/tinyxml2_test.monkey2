
#Import "<tinyxml2>"
#Import "<std>"

#Import "dream.xml"

Using std..
Using tinyxml2..

Function Dump( node:XMLNode,indent:String )

	Print indent+node.Value()
	
	Local child:=node.FirstChild()
	
	While child
	
		Dump( child,indent+"  " )
		
		child=child.NextSibling()
	Wend

End

Function Main()

	Local xml:=LoadString( "asset::dream.xml" )
	
	Local doc:=New XMLDocument
	
	If doc.Parse( xml )<>XMLError.XML_SUCCESS
		Print "Failed to parse"
		Return
	Endif
	
	Print "Parsed!"
	
	doc.PrintDocument()
	
'	Dump( doc,"" )	'Their's looks better!
	
	doc.Destroy()
	
	Print "Bye!"
	
End
