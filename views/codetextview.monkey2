
Namespace ted2go


Class CodeTextView Extends TextViewExt

	Field Formatter:ICodeFormatter		
	Field Keywords:IKeywords
	Field Highlighter:Highlighter
	
	Field LineChanged:Void( prevLine:Int,newLine:Int )
	
	Method New()
		Super.New()
		
		CursorMoved += OnCursorMoved
		
	End
	
	Method OnCursorMoved()
		
		Local line:=Document.FindLine( Cursor )
		If line <> _prevLine
			LineChanged( _prevLine,line )
			_prevLine=line
		Endif
				
		'If Cursor <> Anchor Return
		'DoFormat( True )
		
	End
	
	Method IsCursorAtTheEndOfLine:Bool()
	
		Local line:=Document.FindLine( Cursor )
		Local pos:=Document.EndOfLine( line )
		Return pos=Cursor
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
	
	Method IdentBeforeCursor:String( withDots:Bool=True )
	
		Local text:=Text
		Local cur:=Cursor
		Local n:=Cursor-1
		Local start:=Document.StartOfLine( Document.FindLine( Cursor ) )
		
		While n >= start
			
			If text[n] = 46 'dot
				If Not withDots Exit
			ElseIf Not (IsIdent( text[n] ) Or text[n] = 35) '35 => #
				Exit
			Endif
			
			n-=1
		Wend
		n+=1
		Local ident:=(n < cur) ? text.Slice( n,cur ) Else ""
		
		Return ident
	End
	
	Method FullIdentUnderCursor:String()
	
		Local text:=Text
		Local cur:=Cursor
		Local n:=Cursor-1
		Local line:=Document.FindLine( Cursor )
		Local start:=Document.StartOfLine( line )
		Local ends:=Document.EndOfLine( line )
		
		While n >= start
			
			If text[n] = 46 'dot
				
			ElseIf Not (IsIdent( text[n] ) Or text[n] = 35) '35 => #
				Exit
			Endif
			
			n-=1
		Wend
		Local p1:=n+1
		n=cur
		While n < ends And IsIdent( text[n] )
			n+=1
		Wend
		Local p2:=n
		Local ident:=(p1 < cur Or p2 > cur) ? text.Slice( p1,p2 ) Else ""
		
		Return ident
	End
	
	Method FirstSelectedLine:Int()
	
		Local min:=Min( Anchor,Cursor )
		Return Document.FindLine( min )
	End
	
	Method LastSelectedLine:Int()
	
		Local max:=Max( Anchor,Cursor )
		Return Document.FindLine( max )
	End
	
	Method FirstIdentInLine:String( cursor:Int )
	
		Local line:=Document.FindLine( cursor )
		Local text:=Document.GetLine( line )
		Local n:=0
		'skip empty chars
		While n < text.Length And text[n] <= 32
			n+=1
		Wend
		Local indent:=n
		While n < text.Length And (IsIdent( text[n] ) Or text[n] = 35)
			n+=1
		Wend
		Return (n > indent ? text.Slice( indent,n ) Else "")
	End
	
	Method GetIndent:Int( text:String )
	
		Local n:=0
		While n < text.Length And text[n] <= 32
			n+=1
		Wend
		Return n
	End

	Method GotoPosition( pos:Vec2i )
	
		If pos.y = 0
			GotoLine( pos.x )
			Return
		Endif
		
		Local dest:=Document.StartOfLine( pos.x )+pos.y
		SelectText( dest,dest )
	End
	
	Property LineTextAtCursor:String()
		Return Document.GetLine( Document.FindLine( Cursor ) )
	End
	
	Property LineNumAtCursor:Int()
		Return Document.FindLine( Cursor )
	End
	
	Property LineNumAtAnchor:Int()
		Return Document.FindLine( Anchor )
	End
	
	Property PosInLineAtCursor:Int()
		Return Cursor-Document.StartOfLine( LineNumAtCursor )
	End
	
	Property PosInLineAtAnchor:Int()
		Return Anchor-Document.StartOfLine( LineNumAtAnchor )
	End
	
	Property CursorPos:Vec2i()
		Return New Vec2i( LineNumAtCursor,PosInLineAtCursor )
	End
	
	Property AnchorPos:Vec2i()
		Return New Vec2i( LineNumAtAnchor,PosInLineAtAnchor )
	End
	
	
	Protected
		
	Method OnKeyEvent(event:KeyEvent) Override
	
		Select event.Type
			
			Case EventType.KeyDown,EventType.KeyRepeat
				
				Local ctrl:=(event.Modifiers & Modifier.Control)
				Local shift:=(event.Modifiers & Modifier.Shift)
				Local key:=event.Key
				
				'map keypad nav keys...
				If Not (event.Modifiers & Modifier.NumLock)
					Select key
					Case Key.Keypad1 key=Key.KeyEnd
					Case Key.Keypad2 key=Key.Down
					Case Key.Keypad3 key=Key.PageDown
					Case Key.Keypad4 key=Key.Left
					Case Key.Keypad6 key=Key.Right
					Case Key.Keypad7 key=Key.Home
					Case Key.Keypad8 key=Key.Up
					Case Key.Keypad9 key=Key.PageUp
					Case Key.Keypad0 key=Key.Insert
					End
				Endif
				
				Select key
			
					#If __TARGET__="windows"
					Case Key.E 'delete whole line
						If ctrl
							Local line:=Document.FindLine( Cursor )
							SelectText( Document.StartOfLine( line ),Document.EndOfLine( line )+1 )
							ReplaceText( "" )
							Return
						Endif
					#Endif
					
						
					Case Key.X
					
						If ctrl And Not CanCopy 'nothing selected - cut whole line
							Local line:=Document.FindLine( Cursor )
							SelectText( Document.StartOfLine( line ),Document.EndOfLine( line )+1 )
							Cut()
							Return
						Endif
						
						
					Case Key.C,Key.Insert
					
						If ctrl And Not CanCopy 'nothing selected - copy whole line
							Local cur:=Cursor
							Local line:=Document.FindLine( Cursor )
							SelectText( Document.StartOfLine( line ),Document.EndOfLine( line ) )
							Copy()
							SelectText( cur,cur )'restore
							Return
						Endif
						
					
					Case Key.Enter,Key.KeypadEnter 'auto indent
						
						If _typing Then DoFormat( False )
						
						Local info:=CurrentTextLine
						Local line:=info.line
						Local text:=info.text
						Local indent:=GetIndent( text )
						
						'fix 'bug' when we delete ~n at the end of line.
						'in this case GetLine return 2 lines, and if they empty
						'then we get double indent
						'need to fix inside mojox
						if indent > info.posInLine Then indent=info.posInLine
						
						Local s:=(indent ? text.Slice( 0,indent ) Else "")
						ReplaceText( "~n"+s )
						
						Return
						
						
					Case Key.Home 'smart Home behaviour
			
						If Not ctrl
							SmartHome( shift )
							
							Return
						Endif
						
					
					Case Key.Tab
					
						'If _typing Then DoFormat( False )
						
						
					Case Key.Up,Key.Down
											
						DoFormat( True )
						
						
					Case Key.V
					
						If CanPaste And ctrl
							SmartParse()
							Return
						Endif
						
					
					Case Key.Insert
					
						If CanPaste And shift
							SmartParse()
							Return
						Endif
					
					
					#If __TARGET__="macos"
					'smart Home behaviour
					Case Key.Left
			
						If event.Modifiers & Modifier.Menu
							SmartHome( True )
							
							Return
						Endif
						
						
					Case Key.Right
			
						If event.Modifiers & Modifier.Menu
							SmartHome( False )
							
							Return
						Endif
					#Endif
					
				End
				
				
			Case EventType.KeyChar
				
				If IsIdent( event.Text[0] )
					_typing=True
				Else
					If _typing Then DoFormat( False )
				Endif
				
		End
		
		Super.OnKeyEvent( event )
		
	End
	
	
	Private
	
	Field _typing:Bool
	Field _prevLine:Int
	
	
	Method SmartHome( shift:Bool )
	
		Local line:=CurrentTextLine
		Local txt:=line.text
		Local n:=0
		Local n2:=txt.Length
		'check for whitespaces before cursor
		While (n < n2 And IsSpace( txt[n]) )
			n+=1
		Wend
		n+=line.posStart
		Local newPos:=0
		If n >= Cursor And Cursor > line.posStart
			newPos=line.posStart
		Else
			newPos=n
		Endif
			
		If shift 'selection
			SelectText( Anchor,newPos )
		Else
			SelectText( newPos,newPos )
		Endif
	End
	
	Method SmartParse()
		
		' get indent of cursor's line
		Local cur:=Min( Cursor,Anchor )
		Local line:=Document.FindLine( cur )
		Local posInLine:=cur-Document.StartOfLine( line )
		Local indent:=GetIndent( Document.GetLine( line ) )
		indent=Min( indent,posInLine )
		
		' check indents inside of pasted text
		Local text:=App.ClipboardText
		text=text.Replace( "~r~n","~n" )
		text=text.Replace( "~r","~n" )
		Local lines:=text.Split( "~n" )
		Local indent2:=1000
		
		' skip first line
		For Local i:=1 Until lines.Length
			Local s:=lines[i]
			indent2=Min( indent2,GetIndent(s) )
		Next
		
		Local delta:=indent2-indent
		Local result:=""
		If delta > 0 'need to remove
			For Local i:=0 Until lines.Length
				Local s:=lines[i]
				If result Then result+="~n"
				result+= (i = 0 ? s Else s.Slice( delta ))
			Next
		Elseif delta < 0 'need to append
			Local add:=Utils.RepeatStr( "~t",Abs(delta) )
			For Local i:=0 Until lines.Length
				Local s:=lines[i]
				If result Then result+="~n"
				result+= (i = 0 ? s Else add+s)
			Next
		Else
			result=text
		Endif
		
		ReplaceText( result )
		
	End
	
	Method DoFormat( all:Bool )
		
		_typing=False
		If Formatter Then Formatter.Format( Self,all )
	End
	
End
