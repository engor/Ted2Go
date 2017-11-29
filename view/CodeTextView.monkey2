
Namespace ted2go


Class CodeTextView Extends TextView

	Field Formatter:ICodeFormatter
	Field Keywords:IKeywords
	Field Highlighter:Highlighter
	
	Field LineChanged:Void( prevLine:Int,newLine:Int )
	Field TextChanged:Void()
	
	Method New()
		
		Super.New()
		
		CursorBlinkRate=2.5
		BlockCursor=False
		
		CursorMoved += OnCursorMoved
		Document.TextChanged += TextChanged
		
		
'		Document.LinesModified += Lambda( first:Int,removed:Int,inserted:Int )
'			
'			If _extraSelStart=-1 Return
'			If first>=_extraSelEnd Print "ret" ; Return
'			
'			Print "LinesModified: "+first+", "+removed+", "+inserted
'			
'			If inserted>0
'				
'				If first<_extraSelStart
'					Print "if 1-1"
'					_extraSelStart+=inserted
'				Endif
'				_extraSelEnd+=inserted
'				
'			Else
'				
'				If first<=_extraSelStart And first+removed>=_extraSelEnd
'					ResetExtraSelection()
'					Print "reset"
'					Return
'				Endif
'				
'				If first<_extraSelStart
'					Print "if 2-1"
'					_extraSelStart-=removed
'					_extraSelEnd-=removed
'				Else
'					Print "if 2-2"
'					_extraSelEnd-=Min( removed,_extraSelEnd-first )
'				Endif
'				
'			Endif
'		End
		
		UpdateThemeColors()
	End
	
	Property IsCursorAtTheEndOfLine:Bool()
		
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
		
		Local pair:=GetIndentBeforePos_Mx2( LineTextAtCursor,PosInLineAtCursor,withDots )
		Return pair.Item1
	End
	
	Property WordAtCursor:String()
		
		Local text:=Text
		Local cur:=Cursor
		Local n:=Cursor-1
		Local line:=Document.FindLine( Cursor )
		Local start:=Document.StartOfLine( line )
		Local ends:=Document.EndOfLine( line )
		
		While n >= start
			If Not IsIdent( text[n] ) Exit
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
		
	Property FullIdentAtCursor:String()
		
		Local text:=Text
		Local cur:=Cursor
		Local n:=Cursor-1
		Local line:=Document.FindLine( Cursor )
		Local start:=Document.StartOfLine( line )
		Local ends:=Document.EndOfLine( line )
		
		While n >= start
			
			If text[n] = Chars.DOT 'dot
				
			ElseIf Not (IsIdent( text[n] ) Or text[n] = Chars.GRID) '#
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

	Method GotoPosition( pos:Vec2i,lenToSelect:Int=0 )
	
		'If pos.y = 0
		'	GotoLine( pos.x )
		'Else
			Local dest:=Document.StartOfLine( pos.x )+pos.y
			SelectText( dest,dest+lenToSelect )
		'Endif
		
		MakeCentered()
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
	
	Property StartOfLineAtCursor:Int()
		Return Document.StartOfLine( LineNumAtCursor )
	End
	
	Property CursorPos:Vec2i()
		Return New Vec2i( LineNumAtCursor,PosInLineAtCursor )
	End
	
	Property AnchorPos:Vec2i()
		Return New Vec2i( LineNumAtAnchor,PosInLineAtAnchor )
	End
	
	Property ShowWhiteSpaces:Bool()
	
		Return _showWhiteSpaces
	
	Setter( value:Bool )
	
		_showWhiteSpaces=value
	End
	
	Property OverwriteMode:Bool()
	
		Return _overwriteMode
	
	Setter( value:Bool )
	
		_overwriteMode=value
		
		BlockCursor=_overwriteMode
	End
	
	Method MarkSelectionAsExtraSelection()
		
		_extraSelStart=Anchor
		_extraSelEnd=Cursor
		RequestRender()
	End
	
	Method ResetExtraSelection()
		
		_extraSelStart=-1
		_extraSelEnd=-1
		RequestRender()
	End
	
	Property ExtraSelectionStart:Int()
		Return _extraSelStart
	Setter( value:Int )
		_extraSelStart=value
		RequestRender()
	End
	
	Property ExtraSelectionEnd:Int()
		Return _extraSelEnd
	Setter( value:Int )
		_extraSelEnd=value
		RequestRender()
	End
	
	Property HasExtraSelection:Bool()
		Return _extraSelStart>=0
	End
	
	Protected
	
	Method CheckFormat( event:KeyEvent )
		
		
		Select event.Type
		
			Case EventType.KeyChar
				
				If IsIdent( event.Text[0] )
					_typing=True
				Else
					If _typing Then FormatWord()
				Endif
				
			Case EventType.KeyDown
				
				local key:=FixNumpadKeys( event )
				Select key
					
					Case Key.Tab
						If _typing Then FormatWord() ' like for Key.Space
					
					Case Key.Backspace,Key.KeyDelete,Key.Enter,Key.KeypadEnter
						_typing=True
					
				End
				
		End
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Select event.Type
			
			Case EventType.MouseWheel 'little faster scroll
		
				Scroll-=New Vec2i( 0,RenderStyle.Font.Height*event.Wheel.Y*3 )
				Return
			
			Case EventType.MouseDown 'prevent selection by dragging with right-button
				
				If event.Button = MouseButton.Right
					If Not CanCopy
						Local cur:=CharAtPoint( event.Location )
						SelectText( cur,cur )
					Else
						Local r:=CursorRect | CharRect( Anchor )
						If Not r.Contains( event.Location )
							Local cur:=CharAtPoint( event.Location )
							SelectText( cur,cur )
						Endif
					Endif
					Return
				Endif
				
			Case EventType.MouseUp
				
				If event.Button = MouseButton.Right
					
					MainWindow.ShowEditorMenu( Self )
					Return
				Endif
			
			Case EventType.MouseEnter
				
				Mouse.Cursor=MouseCursor.IBeam
				
			Case EventType.MouseLeave
				
				Mouse.Cursor=MouseCursor.Arrow
				
		End
		
		' correct click position for beam cursor
		event=event.Copy( event.Location+New Vec2i( 6,3 ) ) 'magic offset
		
		Super.OnContentMouseEvent( event )
		
	End
	
	Method OnKeyEvent(event:KeyEvent) Override
	
		Select event.Type
			
			Case EventType.KeyChar
				
				' select next char in overwrite mode
				If Cursor=Anchor And _overwriteMode
				
					' don't select new-line-char ~n
					If Cursor < Text.Length And Text[Cursor]<>10
						SelectText( Cursor,Cursor+1 )
					Endif
				Endif
			
		End
		
		Super.OnKeyEvent( event )
		
	End
	
	Property Line:Int()
		Return _line
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
	
	Method SmartEnd( shift:Bool )
	
		Local line:=Document.FindLine( Cursor )
		Local newPos:=Document.EndOfLine( line )
	
		If shift 'selection
			SelectText( Anchor,newPos )
		Else
			SelectText( newPos,newPos )
		Endif
	End
	
	Method SmartPaste( customText:String=Null )
	
		Local txt:= customText ? customText Else App.ClipboardText
	
		ReplaceText( PrepareSmartPaste( txt ) )
		
	End
	
	Method PrepareSmartPaste:String( txt:String )
	
		' get indent of cursor's line
		Local cur:=Min( Cursor,Anchor )
		Local line:=Document.FindLine( cur )
		Local indent:=GetIndent( Document.GetLine( line ) )
		Local posInLine:=cur-Document.StartOfLine( line )
		indent=Min( indent,posInLine )
	
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
	
		Return result
	End
	
	Method OnThemeChanged() Override
		
		Super.OnThemeChanged()
		
		UpdateThemeColors()
	End
	
	Method UpdateThemeColors() Virtual
		
		_whitespacesColor=App.Theme.GetColor( "textview-whitespaces" )
		_extraSelColor=App.Theme.GetColor( "textview-extra-selection" )
	End
	
	Method OnRenderContent( canvas:Canvas,clip:Recti ) Override
		
		' extra selection
		If _extraSelStart<>-1
			Local min:=CharRect( Min( _extraSelStart,_extraSelEnd ) )
			Local max:=CharRect( Max( _extraSelStart,_extraSelEnd ) )
			
			canvas.Color=_extraSelColor
			
			If min.Y=max.Y
				canvas.DrawRect( min.Left,min.Top,max.Left-min.Left,min.Height )
			Else
				canvas.DrawRect( min.Left,min.Top,(clip.Right-min.Left),min.Height )
				canvas.DrawRect( 0,min.Bottom,clip.Right,max.Top-min.Bottom )
				canvas.DrawRect( 0,max.Top,max.Left,max.Height )
			Endif
		Endif
		
		Super.OnRenderContent( canvas,clip )
	End
	
	Method OnRenderLine( canvas:Canvas,line:Int ) Override
		
		Super.OnRenderLine( canvas,line )
	
		' draw whitespaces
		If Not _showWhiteSpaces Return
	
		Local text:=Document.Text
		Local colors:=Document.Colors
		Local r:Recti
		Local start:=Document.StartOfLine( line )
		
		For Local word:=Eachin WordIterator.ForLine( Self,line )
			
			If text[word.Index]=9 ' tab
				
				Local ind:=word.Index-1
				Local cnt:=0
				' ckeck tab width
				While ind>=start
					If text[ind]=9 Exit
					cnt+=1
					ind-=1
				Wend
				
				cnt = cnt Mod TabStop
				
				canvas.Color=_whitespacesColor
				
				Local len:=word.Length
				
				r=word.Rect
				Local x0:=r.Left,y0:=r.Top+1,y1:=y0+r.Height
				
				Local xx:=x0 + (cnt=0 ? _tabw Else Float(TabStop-cnt)/Float(TabStop)*_tabw)
				
				Local after:=word.Index+len
				If after < text.Length And text[after] > 32 Then len-=1
				
				For Local i:=0 Until len
					canvas.DrawLine( xx,y0,xx,y1 )
					xx+=_tabw
				Next
			Endif
		Next
	
	End
	
	Method OnValidateStyle() Override
		
		Super.OnValidateStyle()
		
		Local style:=RenderStyle
		_tabw=style.Font.TextWidth( "X" )*TabStop
	End
	
	
	Private
	
	Field _line:Int
	Field _whitespacesColor:Color
	Field _showWhiteSpaces:Bool
	Field _tabw:Int
	Field _overwriteMode:Bool
	Field _extraSelStart:Int=-1,_extraSelEnd:Int
	Field _extraSelColor:Color=Color.DarkGrey
	Field _storedCursor:Int
	Field _typing:Bool
	
	Method OnCursorMoved()
		
		Local line:=Document.FindLine( Cursor )
		If line <> _line
			If _typing Then FormatLine( _line )
			
			LineChanged( _line,line )
			_line=line
		Endif
		
		_storedCursor=Cursor
	End
	
	Method FormatWord( customCursor:Int=-1 )
	
		_typing=False
		If Formatter
			Local cur:=(customCursor<>-1) ? customCursor Else _storedCursor
			Formatter.FormatWord( Self,cur )
		Endif
	End
	
	Method FormatLine( line:Int )
	
		_typing=False
		If Formatter
			Formatter.FormatLine( Self,line )
		Endif
	End
	
End


Class MouseEvent Extension
	
	Method Copy:MouseEvent( location:Vec2i )
		
		Return New MouseEvent( Self.Type,Self.View,location,Self.Button,Self.Wheel,Self.Modifiers,Self.Clicks )
	End
End


Function FixNumpadKeys:Key( event:KeyEvent )
	
	Local key:=event.Key
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
	Return key
End
