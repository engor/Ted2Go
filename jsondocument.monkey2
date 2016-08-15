
Namespace ted2

Class JsonTree Extends TreeView

	Class Node Extends TreeView.Node
	
		Method New( jval:JsonValue,parent:TreeView.Node,prefix:String="" )
			Super.New( "",parent )
		
			If Not jval
				Text=prefix+"null"
				Return
			Endif
		
			Local jobj:=Cast<JsonObject>( jval )
			If jobj
				Local obj:=jval.ToObject()
				Text=prefix+"{"+obj.Count()+"}"
				For Local it:=Eachin obj
					New Node( it.Value,Self,it.Key+":" )
				Next
				Return
			Endif
			
			Local jarr:=Cast<JsonArray>( jval )
			If jarr
				Local arr:=jarr.ToArray()
				Text=prefix+"["+arr.Length+"]"
				For Local i:=0 Until arr.Length
					New Node( arr[i],Self,String( i )+":" )
				Next
				Return
			Endif
			
			Local jstr:=Cast<JsonString>( jval )
			If jstr
				Text=prefix+"~q"+jstr.ToString()+"~q"
				Return
			End
			
			Local jnum:=Cast<JsonNumber>( jval )
			If jnum
				Text=prefix+String( jnum.ToNumber() )
				Return
			Endif
			
			Local jbool:=Cast<JsonBool>( jval )
			If jbool
				Text=prefix+( jbool.ToBool() ? "true" Else "false" )
				Return
			Endif
			
			Text="?????"
		End
		
	End
	
	Method New()
		RootNodeVisible=False
		RootNode.Expanded=True
	End
	
	Property Value:JsonValue()
	
		Return _value
	
	Setter( jval:JsonValue )
	
		RootNode.RemoveAllChildren()
		
		New Node( jval,RootNode )
	End
	
	Private
	
	Field _value:JsonValue
	
End

Class JsonDocumentView Extends DockingView

	Method New( doc:TextDocument )
	
		_textView=New TextView( doc )
		
		doc.TextChanged+=Lambda()
		
			_jsonTree.Value=JsonValue.Parse( _textView.Text )
		End

		_jsonTree=New JsonTree
				
		AddView( _jsonTree,"right",300,True )
		
		ContentView=_textView
	End
	
	Property TextView:TextView()
	
		Return _textView
	End
	
	Property JsonTree:JsonTree()
	
		Return _jsonTree
	End
	
	Private
	
	Field _textView:TextView
	Field _jsonTree:JsonTree

End

Class JsonDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_doc=New TextDocument
		
		_doc.TextChanged+=Lambda()
			Dirty=True
		End
		
		_view=New JsonDocumentView( _doc )
	End

	Protected
	
	Method OnLoad:Bool() Override
	
		Local json:=stringio.LoadString( Path )
		
		_doc.Text=json
		
		Local jval:=JsonValue.Parse( json )
		
		_view.JsonTree.Value=jval
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local json:=_doc.Text
		
		Return stringio.SaveString( json,Path )
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
	Method OnGetTextView:TextView( view:View ) Override
	
		Return Cast<JsonDocumentView>( view ).TextView
	End
	
	Private
	
	Field _doc:TextDocument
	
	Field _view:JsonDocumentView
End
