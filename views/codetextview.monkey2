
Namespace ted2go


Class CodeTextView Extends TextView

	Field Formatter:ICodeFormatter		
	Field Keywords:IKeywords
	Field Highlighter:Highlighter
	
	Field LineChanged:Void( prevLine:Int,newLine:Int )
	
	Method New()
		Super.New()
		
		CursorBlinkRate=2.5
		BlockCursor=False
		
		CursorMoved += OnCursorMoved
		
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
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Select event.Type
			
			Case EventType.MouseWheel 'little faster scroll
		
				Scroll-=New Vec2i( 0,RenderStyle.Font.Height*event.Wheel.Y*3 )
				Return
				
		End

		Super.OnContentMouseEvent( event )
					
	End
	
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
					
						If ctrl 'nothing selected - cut whole line
							OnCut( Not CanCopy )
							Return
						Endif
						
						
					Case Key.C
					
						If ctrl 'nothing selected - copy whole line
							OnCopy( Not CanCopy )
							Return
						Endif
					
					
					Case Key.Insert 'ctrl+insert - copy, shift+insert - paste
					
						If shift
							SmartPaste()
						Elseif ctrl And CanCopy
							OnCopy()
						Endif
						Return
						
					
					Case Key.KeyDelete
					
						If shift 'shift+del - cut selected
							If CanCopy Then OnCut()
						Else
							If Anchor = Cursor
								Local len:=Text.Length
								If Cursor < len
									Local ends:=Cursor+1
									If Text[Cursor] = 10 ' do we delete \n ?
										Local i:=Cursor+1
										While i<len And Text[i]<32 And Text[i]<>10
											i+=1
										Wend
										ends=i
									Endif
									SelectText( Cursor,ends )
									ReplaceText( "" )
								Endif
							Else
								ReplaceText( "" )
							Endif
						Endif
						Return
						
							
					Case Key.Enter,Key.KeypadEnter 'auto indent
						
						If _typing Then DoFormat( False )
						
						Local line:=CursorLine
						Local text:=Document.GetLine( line )
						Local indent:=GetIndent( text )
						Local posInLine:=PosInLineAtCursor
						'fix 'bug' when we delete ~n at the end of line.
						'in this case GetLine return 2 lines, and if they empty
						'then we get double indent
						'need to fix inside mojox
						if indent > posInLine Then indent=posInLine
						
						Local s:=(indent ? text.Slice( 0,indent ) Else "")
						ReplaceText( "~n"+s )
						
						Return
						
						
					Case Key.Home 'smart Home behaviour
			
						If ctrl
							If shift 'selection
								SelectText( 0,Anchor )
							Else
								SelectText( 0,0 )
							Endif
						Else
							SmartHome( shift )
						Endif
						Return
						
					
					Case Key.Tab
											
						If Cursor = Anchor 'has no selection
						
							If Not shift
								ReplaceText( "~t" )
							Else
								If Cursor > 0 And Document.Text[Cursor-1]=Chars.TAB
									SelectText( Cursor-1,Cursor )
									ReplaceText( "" )
								Endif
							Endif
							
						Else 'block tab/untab
							
							Local minPos:=Min( Cursor,Anchor )
							Local maxPos:=Max( Cursor,Anchor )
							Local min:=Document.FindLine( minPos )
							Local max:=Document.FindLine( maxPos )
							
							' if we are at the beginning of bottom line - skip it
							Local strt:=Document.StartOfLine( max )
							If maxPos = strt
								max-=1
								DebugStop()
							Endif
							
							Local lines:=New StringStack
								
							For Local i:=min To max
								lines.Push( Document.GetLine( i ) )
							Next
								
							Local go:=True
							Local shiftFirst:=0,shiftLast:=0
							
							If shift
								
								Local changes:=0
								For Local i:=0 Until lines.Length
									If lines[i].StartsWith( "~t" )
										lines[i]=lines[i].Slice( 1 )+"~n"
										changes+=1
										If i=0 Then shiftFirst=-1
										if i=lines.Length-1 Then shiftLast=-1
									Else
										lines[i]+="~n"
									Endif
								Next
								
								go=(changes > 0)
							Else
								shiftFirst=1
								shiftLast=1
								For Local i:=0 Until lines.Length
									lines[i]="~t"+lines[i]+"~n"
								Next
							Endif
								
							If go
								Local minStart:=Document.StartOfLine( min )
								Local maxStart:=Document.StartOfLine( max )
								Local maxEnd:=Document.EndOfLine( max )

								Local p1:=minPos+shiftFirst 'absolute pos
								Local p2:=maxPos-maxStart+shiftLast 'pos in line
								SelectText( minStart,maxEnd+1 )
								ReplaceText( lines.Join( "" ) )
								p2+=Document.StartOfLine( max )
								' case when cursor is between tabs and we move both of them, so jump to prev line
								p1=Max( p1,Document.StartOfLine( min ) )
								SelectText( p1,p2 )
							Endif
								
						Endif
						Return
						
						
					Case Key.Up,Key.Down
											
						DoFormat( True )
						
						
					Case Key.V
					
						If CanPaste And ctrl
							SmartPaste()
							Return
						Endif
						
					
					Case Key.Insert
					
						If CanPaste And shift
							SmartPaste()
							Return
						Endif
					
					Case Key.KeyDelete
					
						If shift
							OnCut()
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
	
	Property Line:Int()
		Return _line
	End
	
	
	Private
	
	Field _typing:Bool
	Field _line:Int
	
	Method OnCursorMoved()
		
		Local line:=Document.FindLine( Cursor )
		If line <> _line
			LineChanged( _line,line )
			_line=line
		Endif
				
		'If Cursor <> Anchor Return
		'DoFormat( True )
		
	End
	
	Method SmartHome( shift:Bool )
	
		Local line:=Document.FindLine( Cursor )
		Local txt:=Document.GetLine( line )
		Local n:=0
		Local n2:=txt.Length
		'check for whitespaces before cursor
		While (n < n2 And IsSpace( txt[n]) )
			n+=1
		Wend
		Local posStart:=Document.StartOfLine( line )
		n+=posStart
		Local newPos:=0
		If n >= Cursor And Cursor > posStart
			newPos=posStart
		Else
			newPos=n
		Endif
			
		If shift 'selection
			SelectText( Anchor,newPos )
		Else
			SelectText( newPos,newPos )
		Endif
	End
	
	Method SmartPaste()
		
		' get indent of cursor's line
		Local cur:=Min( Cursor,Anchor )
		Local line:=Document.FindLine( cur )
		Local indent:=GetIndent( Document.GetLine( line ) )
		Local posInLine:=cur-Document.StartOfLine( line )
		indent=Min( indent,posInLine )
		
		Local txt:=App.ClipboardText
		txt=txt.Replace( "~r~n","~n" )
		txt=txt.Replace( "~r","~n" )
		Local lines:=txt.Split( "~n" )
		
		' add indent at cursor
		If indent
			Local add:=Utils.RepeatStr( "~t",indent )
			For Local i:=1 Until lines.Length
				lines[i]=add+lines[i]
			Next
		Endif
		
		' result text
		Local result:=""
		For Local i:=0 Until lines.Length
			If result Then result+="~n"
			result+=lines[i]
		Next
		
		ReplaceText( result )
		
	End
	
	Method DoFormat( all:Bool )
		
		_typing=False
		If Formatter Then Formatter.Format( Self,all )
	End
	
	Method OnCut( wholeLine:Bool=False )
		
		If wholeLine
			Local line:=Document.FindLine( Cursor )
			SelectText( Document.StartOfLine( line ),Document.EndOfLine( line )+1 )
		Else
			SelectText( Cursor,Anchor )
		Endif
		SmartCopySelected()
		ReplaceText( "" )
	End
	
	Method OnCopy( wholeLine:Bool=False )
		
		If wholeLine
			Local line:=Document.FindLine( Cursor )
			SelectText( Document.StartOfLine( line ),Document.EndOfLine( line ) )
		Else
			SelectText( Cursor,Anchor )
		Endif
		SmartCopySelected()
		
		SelectText( Cursor,Anchor )
	End
	
	Method SmartCopySelected()
		
		' here we strip indents from all lines - the same as in first-line indent
		Local min:=Min( Cursor,Anchor )
		Local max:=Max( Cursor,Anchor )
		Local line:=Document.FindLine( min )
		Local line2:=Document.FindLine( max )
		
		If line = line2 'nothing to strip
			Copy()
			Return
		Endif
		
		Local txt:=Document.GetLine( line )
		Local indent:=GetIndent( txt )
		Local posInLine:=min-Document.StartOfLine( line )
		indent=Min( indent,posInLine )
		
		If indent = 0 'nothing to strip
			Copy()
			Return
		Endif
		
		Local selText:=Document.Text.Slice( min,max )
		Local lines:=selText.Split( "~n" )
		
		Local indent2:=indent
		
		' get min indent, except of first
		For Local i:=1 Until lines.Length
			Local s:=lines[i]
			If Not s.Trim() Continue 'skip empty lines
			indent2=Min( indent2,GetIndent(s) )
		Next
		
		If indent2 = 0 'nothing to strip
			Copy()
			Return
		Endif
		
		Local result:=txt.Slice( posInLine )
		' strip
		For Local i:=1 Until lines.Length
			Local s:=lines[i]
			If result Then result+="~n"
			If Not s.Trim() Continue 'empty
			result+=s.Slice( indent2 )
		Next
		
		App.ClipboardText=result
	End
	
End
