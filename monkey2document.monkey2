
Namespace ted2


Class Monkey2DocumentView Extends Ted2CodeTextView

	Method New( doc:Monkey2Document )
	
		_doc=doc
		
		Document=_doc.TextDocument
		
		ContentView.Style.Border=New Recti( -4,-4,4,4 )
		
		AddView( New GutterView( Self ),"left" )

		FileType = doc.FileType
		
		Keywords = KeywordsManager.Get(FileType)
		Highlighter = HighlightersManager.Get(FileType)
		
		Document.TextHighlighter = Highlighter.Painter
	End
	
	Protected
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		Local color:=canvas.Color
		
		If _doc._errors.Length
		
			canvas.Color=New Color( .5,0,0 )
			
			For Local err:=Eachin _doc._errors
				canvas.DrawRect( 0,err.line*LineHeight,Width,LineHeight )
			Next
			
		Endif
		
		If _doc._debugLine<>-1

			Local line:=_doc._debugLine
			If line<0 Or line>=Document.NumLines Return
			
			canvas.Color=New Color( 0,.5,0 )
			canvas.DrawRect( 0,line*LineHeight,Width,LineHeight )
			
		Endif
		
		canvas.Color=color
		
		Super.OnRenderContent( canvas )
	End
	
	Private
	
	Field _doc:Monkey2Document
	

End


Class Monkey2Document Extends Ted2Document

	Method New( path:String )
		Super.New( path )
	
		_doc=New TextDocument
		
		_doc.TextChanged=Lambda()
			Dirty=True
		End
		
		_doc.LinesModified=Lambda( first:Int,removed:Int,inserted:Int )
			Local put:=0
			For Local get:=0 Until _errors.Length
				Local err:=_errors[get]
				If err.line>=first
					If err.line<first+removed 
						err.removed=True
						Continue
					Endif
					err.line+=(inserted-removed)
				Endif
				_errors[put]=err
				put+=1
			Next
			_errors.Resize( put )
		End

	
		_view=New Monkey2DocumentView( Self )
	End
	
	Property TextDocument:TextDocument()
	
		Return _doc
	End
	
	Property DebugLine:Int()
	
		Return _debugLine
	
	Setter( debugLine:Int )
		If debugLine=_debugLine Return
		
		_debugLine=debugLine
		If _debugLine=-1 Return
		
		_view.GotoLine( _debugLine )
	End
	
	Property Errors:Stack<BuildError>()
	
		Return _errors
	End
	
	Private

	Field _doc:TextDocument

	Field _view:Monkey2DocumentView

	Field _errors:=New Stack<BuildError>

	Field _debugLine:Int=-1
	
	Method OnLoad:Bool() Override
	
		Local text:=stringio.LoadString( Path )
		
		_doc.Text=text
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local text:=_doc.Text
		
		Return stringio.SaveString( text,Path )
	
	End
	
	Method OnCreateView:View() Override
	
		Return _view
	End
	
End

Class Monkey2DocumentType Extends Ted2DocumentType

	Property Name:String() Override
		Return "Monkey2DocumentType"
	End
	
	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".monkey2",".ogg",".cpp",".h",".hpp")
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New Monkey2Document( path )
	End
	
	Private
	
	Global _instance:=New Monkey2DocumentType
	
End

