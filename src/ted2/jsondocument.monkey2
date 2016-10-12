
Namespace ted2

Class JsonDocumentView Extends DockingView

	Method New( doc:TextDocument )
	
		_textView=New TextView( doc )
		
		doc.TextChanged+=Lambda()
		
			_jsonTree.Value=JsonValue.Parse( _textView.Text )
		End

		_jsonTree=New JsonTreeView
				
		AddView( _jsonTree,"right",300,True )
		
		ContentView=_textView
	End
	
	Property TextView:TextView()
	
		Return _textView
	End
	
	Property JsonTree:JsonTreeView()
	
		Return _jsonTree
	End
	
	Private
	
	Field _textView:TextView
	Field _jsonTree:JsonTreeView

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

Class JsonDocumentType Extends Ted2DocumentType

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".json" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New JsonDocument( path )
	End
	
	Private
	
	Global _instance:=New JsonDocumentType
	
End
