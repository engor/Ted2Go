
Namespace ted2go


Class JsonDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_view=New JsonDocumentView( Self )
		
		_doc=_view.Document
		
		_browser=New JsonTreeView

		_doc.TextChanged+=Lambda()
		
			_browser.Value=JsonValue.Parse( _doc.Text )
			
			Dirty=True
		End
		
	End

	Protected
	
	Method OnLoad:Bool() Override
	
		Local json:=stringio.LoadString( Path )
		
		_doc.Text=json
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local json:=_doc.Text
		
		Return stringio.SaveString( json,Path )
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
	Method OnCreateBrowser:View() Override
	
		Return _browser
	End
	
	Method OnGetTextView:TextView( view:View ) Override
	
		Return Cast<TextView>( view )
	End
	
	Private
	
	Field _doc:TextDocument
	
	Field _view:JsonDocumentView
	
	Field _browser:JsonTreeView
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

Class JsonDocumentView Extends Ted2CodeTextView
	
	Method New( doc:Ted2Document )
		
		'very important to set FileType for init
		'formatter, highlighter and keywords
		FileType=doc.FileExtension
		FilePath=doc.Path
	End
	
End
