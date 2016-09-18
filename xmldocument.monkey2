
Namespace ted2go


Class XmlDocumentView Extends DockingView

	Method New( doc:TextDocument )
	
		_textView=New TextView( doc )
		
		doc.TextChanged+=Lambda()
		
			_treeView.RootNode.RemoveAllChildren()
			
			Local xml:=_textView.Text
			
			Local doc := New XMLDocument()
			
			If doc.Parse( xml ) <> XMLError.XML_SUCCESS
				Return
			Endif
 
			_treeView.RootNode.Text = "XML Document"
 
			AddXMLNodeToTree( doc,_treeView.RootNode )
		
		End
		
		_treeView=New TreeView

		AddView( _treeView,"right",300,True )
		
		ContentView=_textView
	End
	
	Property TextView:TextView()
	
		Return _textView
	End
	
	Property TreeView:TreeView()
	
		Return _treeView
	End
	
	Private
	
	Field _textView:TextView
	
	Field _treeView:TreeView
	
	Method AddXMLNodeToTree(xmlNode:XMLNode, parent:TreeView.Node)
	
		Local str := ""
	
		Local xmlElement := xmlNode.ToElement()
		
		If xmlElement
		
			str += "<" + xmlNode.Value()
			
			Local attrib := xmlElement.FirstAttribute()
			While attrib 
				str += " " + attrib.Name() + "=~q" + attrib.Value() + "~q "
				attrib=attrib.NextAttribute()
			wend
			
			str += ">"
		Else
			str += xmlNode.Value()
		Endif
 
		Local treeNode:TreeView.Node
	
		If str
			treeNode = New TreeView.Node(str, parent)
		Endif
		
		Local xmlChild := xmlNode.FirstChild()
	
		While xmlChild
		
			If Not xmlChild.NoChildren()
				If treeNode Then parent = treeNode
			Endif
		
			AddXMLNodeToTree(xmlChild, parent)
			
			xmlChild = xmlChild.NextSibling()
	
		Wend
	
	End

End

Class XmlDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_doc=New TextDocument
		
		_doc.TextChanged+=Lambda()
			Dirty=True
		End
		
		_view=New XmlDocumentView( _doc )
	End

	Protected
	
	Method OnLoad:Bool() Override
	
		Local xml:=stringio.LoadString( Path )
		
		_doc.Text=xml
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local xml:=_doc.Text
		
		Return stringio.SaveString( xml,Path )
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
	Method OnGetTextView:TextView( view:View ) Override
	
		Return Cast<XmlDocumentView>( view ).TextView
	End
	
	Private
	
	Field _doc:TextDocument
	
	Field _view:XmlDocumentView
End

Class XmlDocumentType Extends Ted2DocumentType

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".xml" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New XmlDocument( path )
	End
	
	Private
	
	Global _instance:=New XmlDocumentType
	
End
