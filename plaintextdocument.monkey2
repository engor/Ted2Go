
Namespace ted2go


Class PlainTextDocumentView Extends TextView

	Method New( doc:PlainTextDocument )

		_doc=doc
		
		Document=_doc.TextDocument
		
		AddView( New GutterView( Self ),"left" )
		
		ContentView.Style.Border=New Recti( -4,-4,4,4 )
		
		CursorColor=New Color( 0,.5,1 )

		SelectionColor=New Color( .4,.4,.4 )
	End
	
	Private
	
	Field _doc:PlainTextDocument
	
End

Class PlainTextDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_doc=New TextDocument
		
		_doc.TextChanged=Lambda()
			Dirty=True
		End
		
		_view=New PlainTextDocumentView( Self )
	End
	
	Property TextDocument:TextDocument()
	
		Return _doc
	End
	
	Protected
	
	Method OnLoad:Bool() Override
	
		Local text:=stringio.LoadString( Path )
		
		_doc.Text=text
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local text:=_doc.Text
		
		Return stringio.SaveString( text,Path )
	End
	
	Method OnCreateView:PlainTextDocumentView() Override
	
		Return _view
	End
	
	Private
	
	Field _doc:TextDocument
	
	Field _view:PlainTextDocumentView

End

Class PlainTextDocumentType Extends Ted2DocumentType

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[](".txt" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New PlainTextDocument( path )
	End
	
	Private
	
	Global _instance:=New PlainTextDocumentType
	
End
