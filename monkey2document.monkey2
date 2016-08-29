
Namespace ted2

Private

Const COLOR_NONE:=0
Const COLOR_IDENT:=1
Const COLOR_KEYWORD:=2
Const COLOR_STRING:=3
Const COLOR_NUMBER:=4
Const COLOR_COMMENT:=5
Const COLOR_PREPROC:=6
Const COLOR_OTHER:=7

Global Keywords:Keywords



Function Monkey2TextHighlighter:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )

	Local i0:=sol
	
	Local icolor:=0
	Local istart:=sol
	Local preproc:=False
	
	If state>-1 icolor=COLOR_COMMENT
	
	While i0<eol
	
		Local start:=i0
		Local chr:=text[i0]
		i0+=1
		If IsSpace( chr ) Continue
		
		If chr=35 And istart=sol
			preproc=True
			If state=-1 icolor=COLOR_PREPROC
			Continue
		Endif
		
		If preproc And (IsAlpha( chr ) Or chr=95)

			While i0<eol And (IsAlpha( text[i0] ) Or IsDigit( text[i0] )  Or text[i0]=95)
				i0+=1
			Wend
			
			Local id:=text.Slice( start,i0 )
			
			Select id.ToLower()
			Case "rem"
				state+=1
				icolor=COLOR_COMMENT
			Case "end"
				If state>-1 
					state-=1
					icolor=COLOR_COMMENT
				Endif
			End
			
			Exit
		
		Endif
		
		If state>-1 Or preproc Exit
		
		Local color:=icolor
		
		If chr=39
		
			i0=eol
			color=COLOR_COMMENT
			
		Else If chr=34
		
			While i0<eol And text[i0]<>34
				i0+=1
			Wend
			If i0<eol i0+=1
			
			color=COLOR_STRING
			
		Else If IsAlpha( chr ) Or chr=95

			While i0<eol And (IsAlpha( text[i0] ) Or IsDigit( text[i0] )  Or text[i0]=95)
				i0+=1
			Wend
			
			Local id:=text.Slice( start,i0 )
			
			If preproc And istart=sol
			
				Select id.ToLower()
				Case "rem"				
					state+=1
				Case "end"
					state=Max( state-1,-1 )
				End
				
				icolor=COLOR_COMMENT
				
				Exit
			Else
			
				color=COLOR_IDENT
				
				If Keywords.Contains( id.ToLower() ) color=COLOR_KEYWORD
			
			Endif
			
		Else If IsDigit( chr )
		
			While i0<eol And IsDigit( text[i0] )
				i0+=1
			Wend
			
			color=COLOR_NUMBER
			
		Else If chr=36 And i0<eol And IsHexDigit( text[i0] )
		
			i0+=1
			While i0<eol And IsHexDigit( text[i0] )
				i0+=1
			Wend
			
			color=COLOR_NUMBER
			
		Else
			
			color=COLOR_NONE
			
		Endif
		
		If color=icolor Continue
		
		For Local i:=istart Until start
			colors[i]=icolor
		Next
		
		icolor=color
		istart=start
	
	Wend
	
	For Local i:=istart Until eol
		colors[i]=icolor
	Next
	
	Return state

End

Public

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
			If color<>COLOR_KEYWORD And color<>COLOR_IDENT Return
		Endif
		
		Local ident:=text.Slice( start,cursor )
		If Not ident Return
		
		Local kw:=Keywords.Get(ident)
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

Class Monkey2Document Extends Ted2Document

	Method New( path:String )
		Super.New( path )
	
		Keywords = KeywordsManager.Get("monkey2")
		
		_doc=New TextDocument
		
		_doc.TextChanged=Lambda()
			Dirty=True
		End
		
		_doc.TextHighlighter=Monkey2TextHighlighter
		
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

