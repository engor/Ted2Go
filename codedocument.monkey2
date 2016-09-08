
Namespace ted2go


Global AutoComplete:AutocompleteDialog

Class CodeDocumentView Extends Ted2CodeTextView

	Method New( doc:CodeDocument )
	
		_doc=doc
		
		Document=_doc.TextDocument
		
		ContentView.Style.Border=New Recti( -4,-4,4,4 )
		
		AddView( New GutterView( Self ),"left" )

		'very important to set FileType for init
		'formatter, highlighter and keywords
		FileType = doc.FileType
		
		'AutoComplete
		If AutoComplete = Null Then AutoComplete = New AutocompleteDialog("")
		AutoComplete.OnChoosen += Lambda(text:String)
			If App.KeyView = Self
				SelectText(Cursor,Cursor-AutoComplete.Ident.Length)
				ReplaceText(text)
			Endif
		End
		
	End
	
	Property CharsToShowAutoComplete:Int()
		Return 2
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
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		'ctrl+space - show autocomplete list
		If event.Type = EventType.KeyDown
			If event.Key = Key.Space And event.Modifiers & Modifier.Control
				ShowAutocomplete()
				Return
			End
		Endif
		
		Super.OnKeyEvent( event )
		
		'show autocomplete list after some typed chars
		If event.Type = EventType.KeyChar
			Local ident := IdentBeforeCursor()
			'Print "ident "+ident
			If ident.Length >= CharsToShowAutoComplete
				ShowAutocomplete(ident)
			Else
				HideAutocomplete()
			Endif
		Endif
		
	End
	
	Method ShowAutocomplete(ident:String = "")
		'check ident
		If ident = "" Then ident = IdentBeforeCursor()
		'check scope
		
		'show
		AutoComplete.Show(ident, FileType)
	End
	
	Method HideAutocomplete()
		AutoComplete.Hide()
	End
	
	
	Private
	
	Field _doc:CodeDocument
	

End


Class CodeDocument Extends Ted2Document

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

	
		_view=New CodeDocumentView( Self )
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

	Field _view:CodeDocumentView

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

Class CodeDocumentType Extends Ted2DocumentType

	Property Name:String() Override
		Return "CodeDocumentType"
	End
	
	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".monkey2",".cpp",".h",".hpp",".hxx",".c",".cxx",".m",".mm",".s",".asm",".html",".js",".css",".php",".md",".xml",".ini",".sh",".bat",".glsl")
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New CodeDocument( path )
	End
	
	Private
	
	Global _instance:=New CodeDocumentType
	
End

