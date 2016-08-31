
Namespace ted2


Class Monkey2DocumentView Extends Ted2TextView

	Method New( doc:Monkey2Document )
	
		_doc=doc
		
		Document=_doc.TextDocument
		
		ContentView.Style.Border=New Recti( -4,-4,4,4 )
		
		AddView( New GutterView( Self ),"left" )

		CursorColor=New Color( 0,.5,1 )
		SelectionColor=New Color( .4,.4,.4 )
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
	
	Method Capitalize()
	
		Local cursor:=Cursor
		
		Local state:=Document.LineState( Document.FindLine( cursor ) )
		If state<>-1 Return
		
		Local text:=Text
		Local start:=cursor
		While start And IsIdent( text[start-1] )
			start-=1
		Wend
		While start<text.Length And IsDigit( text[start] )
			start+=1
		Wend
		
		If start<text.Length 
			Local color:=Document.Colors[start]
			If color<>Highlighter.COLOR_KEYWORD And color<>Highlighter.COLOR_IDENT Return
		Endif
		
		Local ident:=text.Slice( start,cursor )
		If Not ident Return
		
		Local kw := _doc.Keywords.Get(ident)
		If kw And kw<>ident Document.ReplaceText( Cursor-ident.Length,Cursor,kw )
		
	End
	
	Method IdentAtCursor:String()
	
		Local text:=Text
		Local start:=Cursor
		
		While start And Not IsIdent( text[start] ) And text[start-1]<>10
			start-=1
		Wend
		While start And IsIdent( text[start-1] ) And text[start-1]<>10
			start-=1
		Wend
		While start<text.Length And IsDigit( text[start] ) And text[start]<>10
			start+=1
		Wend
		
		Local ends:=start
		
		While ends<text.Length And IsIdent( text[ends] ) And text[ends]<>10
			ends+=1
		Wend
		
		Return text.Slice( start,ends )
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		Select event.Type
		Case EventType.KeyDown
		
			Local ctrl := (event.Modifiers & Modifier.Control)
			
			If ctrl
					
				Select event.Key
				
					Case Key.E 'delete whole line
						Local line := Document.FindLine(Cursor)
						SelectText(Document.StartOfLine(line), Document.EndOfLine(line)+1)
						ReplaceText("")
						event.Eat()
						
					Case Key.X
						If CanCopy
							Cut()
						Else
							'nothing selected - cut whole line
							Local line := Document.FindLine(Cursor)
							SelectText(Document.StartOfLine(line), Document.EndOfLine(line)+1)
							Cut()
						Endif
						event.Eat()
						
					Case Key.C, Key.Insert
						If CanCopy
							Copy()
						Else
							'nothing selected - copy whole line
							Local cur := Cursor
							Local line := Document.FindLine(Cursor)
							SelectText(Document.StartOfLine(line), Document.EndOfLine(line))
							Copy()
							SelectText(cur,cur)'restore
						Endif
						event.Eat()
				End
			
			Else 'without ctrl modifier
			
				Select event.Key
							
					Case Key.F1
					
						Local ident:=IdentAtCursor()
						
						If ident MainWindow.ShowQuickHelp( ident )
						
					Case Key.Tab,Key.Enter
						Capitalize()
					
					Case Key.Up,Key.Down
						Capitalize()
						
				End
		
		Endif
		
		
		Case EventType.KeyChar
		
			If Not IsIdent( event.Text[0] )
				Capitalize()
			Endif
		End

		Super.OnKeyEvent( event )

	End

End

Class Monkey2Document Extends Ted2CodeDocument

	Method New( path:String )
		Super.New( path )
	
		' need to extract it from Plugins
		Keywords = Monkey2Keywords.Acquire()
		Highlighter = New Monkey2Highlighter
		
		
		_doc=New TextDocument
		
		_doc.TextChanged=Lambda()
			Dirty=True
		End
		
		_doc.TextHighlighter = Highlighter.Executor
		
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

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".monkey2",".ogg" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New Monkey2Document( path )
	End
	
	Private
	
	Global _instance:=New Monkey2DocumentType
	
End

