
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
		
		UpdateThemeColors()
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
	
	Method FullIdentAtCursor:String()
		
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
	
	Property ShowWhiteSpaces:Bool()
	
		Return _showWhiteSpaces
	
	Setter( value:Bool )
	
		_showWhiteSpaces=value
	End
	
	
	Protected
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Select event.Type
			
			Case EventType.MouseWheel 'little faster scroll
		
				Scroll-=New Vec2i( 0,RenderStyle.Font.Height*event.Wheel.Y*3 )
				Return
			
			Case EventType.MouseDown 'prevent selection by dragging with right-button
				
				If event.Button = MouseButton.Right Return
				
				
			Case EventType.MouseUp
				
				If event.Button = MouseButton.Right
					
					MainWindow.ShowEditorMenu( Self )
					Return
				Endif
				
		End

		Super.OnContentMouseEvent( event )
					
	End
	
	Method OnKeyEvent(event:KeyEvent) Override
	
		Select event.Type
			
			Case EventType.KeyChar
				
				If IsIdent( event.Text[0] )
					_typing=True
				Else
					If _typing Then DoFormat( False )
				Endif
				
				' select next char in override mode
				If Cursor=Anchor And MainWindow.OverwriteTextMode
				
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
	
	
	Protected
	
	Field _typing:Bool
	
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
	
	Method DoFormat( all:Bool )
	
		_typing=False
		If Formatter Then Formatter.Format( Self,all )
	End
	
	Method OnThemeChanged() Override
		
		Super.OnThemeChanged()
		UpdateThemeColors()
	End
	
	Method UpdateThemeColors() Virtual
	
		_whitespacesColor=App.Theme.GetColor( "textview-whitespaces" )
	End
	
	Method OnRenderLine( canvas:Canvas,line:Int ) Override
	
		Super.OnRenderLine( canvas,line )
	
		' draw whitespaces
		If Not _showWhiteSpaces Return
	
		Local text:=Document.Text
		Local colors:=Document.Colors
		Local r:Recti
	
		For Local word:=Eachin WordIterator.ForLine( Self,line )
	
			If text[word.Index]=9 ' tab
	
				canvas.Color=_whitespacesColor
	
				Local len:=word.Length
	
				r=word.Rect
				Local x0:=r.Left,y0:=r.Top+1,y1:=y0+r.Height
				Local ww:=r.Width/len
				Local xx:=x0+ww
	
				Local after:=word.Index+len
				If after < text.Length And text[after] > 32 Then len-=1
	
				For Local i:=0 Until len
					canvas.DrawLine( xx,y0,xx,y1 )
					xx+=ww
				Next
			Endif
		Next
	
	End
	
	
	Private
	
	Field _line:Int
	Field _whitespacesColor:Color
	Field _showWhiteSpaces:Bool
	Field _font:Font
	Field _charw:Int
	Field _charh:Int
	Field _tabw:Int
	
	
	Method OnCursorMoved()
		
		Local line:=Document.FindLine( Cursor )
		If line <> _line
			LineChanged( _line,line )
			_line=line
		Endif
				
		'If Cursor <> Anchor Return
		'DoFormat( True )
		
	End
	
	
End
