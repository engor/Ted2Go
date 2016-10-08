
Namespace mojox

Alias TextHighlighter:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )

#rem monkeydoc The TextDocument class.
#end
Class TextDocument

	#rem monkeydoc Invoked after text has changed.
	#end
	Field TextChanged:Void()

	#rem monkeydoc Invoked after lines have been modified.
	#end
	Field LinesModified:Void( first:Int,removed:Int,inserted:Int )
	
	#rem monkeydoc Creates a new text document.
	#end
	Method New()

		_lines.Push( New Line )
	End

	#rem monkeydoc Document text.
	#end
	Property Text:String()
	
		Return _text
		
	Setter( text:String )
	
		text=text.Replace( "~r~n","~n" )
		text=text.Replace( "~r","~n" )
	
		ReplaceText( 0,_text.Length,text )
	End
	
	#rem monkeydoc Length of doucment text.
	#end
	Property TextLength:Int()
	
		Return _text.Length
	End
	
	#rem monkeydoc Number of lines in document.
	#end
	Property NumLines:Int()
	
		Return _lines.Length
	End

	#rem monkeydoc @hidden
	#end	
	Property Colors:Byte[]()
	
		Return _colors.Data
	End
	
	#rem monkeydoc @hidden
	#end	
	Property TextHighlighter:TextHighlighter()
	
		Return _highlighter
	
	Setter( textHighlighter:TextHighlighter )
	
		_highlighter=textHighlighter
	End
	
	#rem monkeydoc @hidden
	#end	
	Method LineState:Int( line:Int )
		If line>=0 And line<_lines.Length Return _lines[line].state
		Return -1
	End
	
	#rem monkeydoc Gets the index of the first character on a line.
	#end	
	Method StartOfLine:Int( line:Int )
		If line<=0 Return 0
		If line<_lines.Length Return _lines[line-1].eol+1
		Return _text.Length
	End
	
	#rem monkeydoc Gets the index of the last character on a line.
	#end	
	Method EndOfLine:Int( line:Int )
		If line<0 Return 0
		If line<_lines.Length Return _lines[line].eol
		Return _text.Length
	End
	
	#rem monkeydoc Finds the line containing a character.
	#end
	Method FindLine:Int( index:Int )
	
		If index<=0 Return 0
		If index>=_text.Length Return _lines.Length-1
		
		Local min:=0,max:=_lines.Length-1
		
		Repeat
			Local line:=(min+max)/2
			If index>_lines[line].eol
				min=line+1
			Else If max-min<2
				Return min
			Else
				max=line
			Endif
		Forever

		Return 0		
	End

	#rem monkeydoc Gets line text.
	#end
	Method GetLine:String( line:Int )

		Return _text.Slice( StartOfLine( line ),EndOfLine( line ) )
	End

	#rem monkeydoc Appends text to the end of the document.
	#end	
	Method AppendText( text:String )
	
		ReplaceText( _text.Length,_text.Length,text )
	End
	
	#rem monkeydoc Replaces  text in the document.
	#end	
	Method ReplaceText( anchor:Int,cursor:Int,text:String )
	
		Local min:=Min( anchor,cursor )
		Local max:=Max( anchor,cursor )
		
		Local eols1:=0,eols2:=0
		For Local i:=min Until max
			If _text[i]=10 eols1+=1
		Next
		For Local i:=0 Until text.Length
			If text[i]=10 eols2+=1
		Next
		
		Local dlines:=eols2-eols1
		Local dchars:=text.Length-(max-min)
		
		Local line0:=FindLine( min )
		Local line:=line0
		Local eol:=StartOfLine( line )-1
		
'		Print "eols1="+eols1+", eols2="+eols2+", dlines="+dlines+", dchars="+dchars+" text="+text.Length
		
		'Move data!
		'
		Local oldlen:=_text.Length
		_text=_text.Slice( 0,min )+text+_text.Slice( max )
		
		_colors.Resize( _text.Length )
		Local p:=_colors.Data.Data
		libc.memmove( p + min + text.Length, p + max , oldlen-max )
		libc.memset( p + min , 0 , text.Length )
		
		'Update lines
		'
		If dlines>=0
		
			_lines.Resize( _lines.Length+dlines )

			Local i:=_lines.Length
			While i>line+eols2+1
				i-=1
				_lines.Data[i].eol=_lines[i-dlines].eol+dchars
				_lines.Data[i].state=_lines[i-dlines].state
			Wend
		
		Endif

		For Local i:=0 Until eols2+1
			eol=_text.Find( "~n",eol+1 )
			If eol=-1 eol=_text.Length
			_lines.Data[line+i].eol=eol
			_lines.Data[line+i].state=-1
		Next
		
		If dlines<0

			Local i:=line+eols2+1
			While i<_lines.Length+dlines
				_lines.Data[i].eol=_lines[i-dlines].eol+dchars
				_lines.Data[i].state=_lines[i-dlines].state
				i+=1
			Wend

			_lines.Resize( _lines.Length+dlines )
		Endif

		If _highlighter<>Null
		
			'update highlighting
			'
			Local state:=-1
			If line state=_lines[line-1].state
			
			For Local i:=0 Until eols2+1
				state=_highlighter( _text,_colors.Data,StartOfLine( line ),EndOfLine( line ),state )
				_lines.Data[line].state=state
				line+=1
			Next
			
			While line<_lines.Length 'And state<>_lines[line].state
				state=_highlighter( _text,_colors.Data,StartOfLine( line ),EndOfLine( line ),state )
				_lines.Data[line].state=state
				line+=1
			End
		Endif
		
'		LinesModified( line0,eols1+1,eols2+1 )
		LinesModified( line0,eols1,eols2 )
		
		TextChanged()
	End
	
	Private
	
	Struct Line
		Field eol:Int
		Field state:Int
	End
	
	Field _text:String
	
	Field _lines:=New Stack<Line>
	Field _colors:=New Stack<Byte>
	Field _highlighter:TextHighlighter
	
End

#rem monkeydoc The TextView class.
#end
Class TextView Extends ScrollableView

	#rem monkeydoc Invoked when cursor moves.
	#end
	Field CursorMoved:Void()

	#rem monkeydoc Creates a new text view.
	#end
	Method New()
		Style=GetStyle( "TextView" )
		ContentView.Style=GetStyle( "TextViewContent" )

		_lines.Push( New Line )
		
		UpdateColors()
		
		Document=New TextDocument
	End

	Method New( text:String )
		Self.New()
		
		Document.Text=text
	End
	
	Method New( doc:TextDocument )
		Self.New()
		
		Document=doc
	End

	#rem monkeydoc Text document.
	#end	
	Property Document:TextDocument()
	
		Return _doc
		
	Setter( doc:TextDocument )
	
		If _doc _doc.LinesModified-=LinesModified
	
		_doc=doc
		
		_doc.LinesModified+=LinesModified
		
		_cursor=Clamp( _cursor,0,_doc.TextLength )
		_anchor=_cursor
		
		UpdateCursor()
	End
	
	Public
	
	#rem monkeydoc Text colors.
	#end
	Property TextColors:Color[]()
	
		Return _textColors
	
	Setter( textColors:Color[] )
	
		_textColors=textColors
	End
	
	#rem monkeydoc Cursor color.
	#end
	Property CursorColor:Color()
	
		Return _cursorColor
	
	Setter( cursorColor:Color )
	
		_cursorColor=cursorColor
	End
	
	#rem monkeydoc Selection color.
	#end
	Property SelectionColor:Color()
	
		Return _selColor
		
	Setter( selectionColor:Color )
	
		_selColor=selectionColor
	End
	
	#rem monkeydoc Block cursor flag.
	#end
	Property BlockCursor:Bool()
	
		Return _blockCursor
	
	Setter( blockCursor:Bool )
	
		_blockCursor=blockCursor
		
		RequestRender()
	End
	
	#rem monkeydoc Cursor blink rate.
	
	Set to 0 for non-blinking cursor.
	
	#end
	Property CursorBlinkRate:Float()
	
		Return _blinkRate
	
	Setter( blinkRate:Float )
	
		_blinkRate=blinkRate
		
		RequestRender()
	End

	#rem monkeydoc Text.
	#end
	Property Text:String()
	
		Return _doc.Text
		
	Setter( text:String )
	
		_doc.Text=text
	End
	
	#rem monkeydoc Read only flag.
	#end
	Property ReadOnly:Bool()
	
		Return _readOnly
	
	Setter( readOnly:Bool )
	
		_readOnly=readOnly
	End
	
	#rem monkeydoc Tabstop.
	#end
	Property TabStop:Int()
	
		Return _tabStop
		
	Setter( tabStop:Int )
	
		_tabStop=tabStop
		
		InvalidateStyle()
	End
	
	#rem monkeydoc WordWrap flag.
	#end
	Property WordWrap:Bool()
	
		Return _wordWrap
	
	Setter( wordWrap:Bool )
	
		_wordWrap=wordWrap
		
		InvalidateStyle()
	End
	
	#rem monkeydoc Cursor character index.
	#end
	Property Cursor:Int()
	
		Return _cursor
	End
	
	#rem monkeydoc Anchor character index.
	#end
	Property Anchor:Int()
	
		Return _anchor
	End
	
	#rem monkeydoc Line the cursor is on.
	#end
	Property CursorLine:Int()
	
		Return _doc.FindLine( _cursor )
	End
	
	#rem monkeydoc Cursor rect.
	#end
	Property CursorRect:Recti()

		Return _cursorRect
	End
	
	#rem monkeydoc Approximate character width.
	#end
	Property CharWidth:Int()
	
		Return _charw
	End
	
	#rem monkeydoc Approximate character height.
	#end
	Property CharHeight:Int()
	
		Return _charh
	End
	
	#rem monkeydoc Approximate line height.
	
	Deprecated! Use [[LineRect]] instead to properly deal with word wrap.
	
	#end
	Property LineHeight:Int()
	
		Return _charh
	End
	
	#rem monkeydoc True if undo available.
	#end	
	Property CanUndo:Bool()
	
		Return Not _readOnly And Not _undos.Empty
	End
	
	#rem monkeydoc True if redo available.
	#end	
	Property CanRedo:Bool()
	
		Return Not _readOnly And Not _redos.Empty
	End
	
	#rem monkeydoc True if cut available.
	#end	
	Property CanCut:Bool()
	
		Return Not _readOnly And _anchor<>_cursor
	End
	
	#rem monkeydoc True if copy available.
	#end	
	Property CanCopy:Bool()
	
		Return _anchor<>_cursor
	End
	
	#rem monkeydoc True if paste available.
	#end	
	Property CanPaste:Bool()
	
		Return Not _readOnly And Not App.ClipboardTextEmpty
	End
	
	#rem monkeydoc Returns the rect containing a character at a given index.
	#end
	Method CharRect:Recti( index:Int )
	
		Local line:=_doc.FindLine( index )
		Local text:=_doc.Text
		
		Local i0:=_doc.StartOfLine( line )
		Local eol:=_doc.EndOfLine( line )
		
		Local x0:=0,y0:=_lines[line].rect.Top
		
		While i0<eol
		
			Local w:=WordWidth( text,i0,eol,x0 )
			
			If x0+w>_wrapw	'-_charw
				y0+=_charh
				x0=0
			Endif
			
			Local l:=WordLength( text,i0,eol )

			If index<i0+l
				x0+=WordWidth( text,i0,index,x0 )
				Exit
			Endif
			
			x0+=w
			i0+=l
		
		Wend
		
		Local w:=_charw
		If i0<eol And text[i0]>32 w=_font.TextWidth( text.Slice( i0,i0+1 ) )
		
		Return New Recti( x0,y0,x0+w,y0+_charh )
	End
	
	#rem monkeydoc Returns the index of the character nearest to a given point.
	#end
	Method CharAtPoint:Int( p:Vec2i )
	
		Local line:=LineAtPoint( p )
		Local text:=_doc.Text

		Local i0:=_doc.StartOfLine( line )
		Local eol:=_doc.EndOfLine( line )
		
		Local x0:=0,y0:=_lines[line].rect.Top+_charh
		
		While i0<eol
		
			Local w:=WordWidth( text,i0,eol,x0 )
			
			If x0+w>_wrapw	'-_charw
				If p.y<y0 Exit
				y0+=_charh
				x0=0
			Endif
			
			Local l:=WordLength( text,i0,eol )
			
			If p.x<x0+w And p.y<y0 
				For Local i:=0 Until l
					x0+=WordWidth( text,i0,i0+1,x0 )
					If p.x<x0 Exit
					i0+=1
				Next
				Exit
			Endif
			
			x0+=w
			i0+=l
			
		Wend
		
		Return i0
	
	End
	
	#rem monkedoc Returns the index of the line nearest to a given point.
	#end
	Method LineAtPoint:Int( p:Vec2i )
	
		If p.y<=0 Return 0
		If p.y>=_lines.Top.rect.Top Return _lines.Length-1
		
		Local min:=0,max:=_lines.Length-1
		
		Repeat
			Local line:=(min+max)/2
			If p.y>=_lines[line].rect.Bottom
				min=line+1
			Else If max-min>1
				max=line
			Else
				Return min
			Endif
		Forever

		Return 0		
	End

	#rem monkeydoc Gets the bounding rect for a line.
	#end
	Method LineRect:Recti( line:Int )
	
		If line>=0 And line<_lines.Length Return _lines[line].rect
		
		Return New Recti
	End
	
	#rem monkeydoc Clears all text.
	#end
	Method Clear()
		SelectAll()
		ReplaceText( "" )
	End
	
	#rem monkeydoc Move cursor to line.
	#end
	Method GotoLine( line:Int )
		_anchor=_doc.StartOfLine( line )
		_cursor=_anchor
		UpdateCursor()
	End
	
	#rem monkeydoc Selects a line.
	#end
	Method SelectLine( line:Int )
		SelectText( _doc.StartOfLine( line ),_doc.EndOfLine( line ) )
	End

	#rem monkeydoc Selects text in a range.
	#end
	Method SelectText( anchor:Int,cursor:Int )

		_anchor=Clamp( anchor,0,_doc.TextLength )
		_cursor=Clamp( cursor,0,_doc.TextLength )
		
		UpdateCursor()
	End
	
	#rem monkeydoc Appends text.
	#end
	Method AppendText( text:String )
	
		SelectText( _doc.TextLength,_doc.TextLength )
		ReplaceText( text )
	End
	
	#rem monkeydoc Replaces current selection.
	#end
	Method ReplaceText( text:String )
	
		Local undo:=New UndoOp
		undo.text=_doc.Text.Slice( Min( _anchor,_cursor ),Max( _anchor,_cursor ) )
		undo.anchor=Min( _anchor,_cursor )
		undo.cursor=undo.anchor+text.Length
		_undos.Push( undo )
		
		ReplaceText( _anchor,_cursor,text )
	End
	
	'non-undoable
	#rem monkeydoc @hidden
	#end
	Method ReplaceText( anchor:Int,cursor:Int,text:String )
			
		_redos.Clear()
	
		_doc.ReplaceText( anchor,cursor,text )
		_cursor=Min( anchor,cursor )+text.Length
		_anchor=_cursor
		
		UpdateCursor()
	End
	
	#rem monkeydoc Performs an undo.
	#end
	Method Undo()
		If _readOnly Return
	
		If _undos.Empty Return
		
		Local undo:=_undos.Pop()

		Local text:=undo.text
		Local anchor:=undo.anchor
		Local cursor:=undo.cursor
		
		undo.text=_doc.Text.Slice( anchor,cursor )
		undo.cursor=anchor+text.Length
		
		_redos.Push( undo )
		
		_doc.ReplaceText( anchor,cursor,text )
		_cursor=anchor+text.Length
		_anchor=_cursor
		
		UpdateCursor()
	End
	
	#rem monkeydoc Performs a redo.
	#end
	Method Redo()
		If _readOnly Return
		
		If _redos.Empty Return

		Local undo:=_redos.Pop()
		
		Local text:=undo.text
		Local anchor:=undo.anchor
		Local cursor:=undo.cursor
		
		undo.text=_doc.Text.Slice( anchor,cursor )
		undo.cursor=anchor+text.Length
		
		_undos.Push( undo )
		
		_doc.ReplaceText( anchor,cursor,text )
		_cursor=anchor+text.Length
		_anchor=_cursor
		
		UpdateCursor()
	End
	
	#rem monkeydoc Selects all text.
	#end
	Method SelectAll()
		SelectText( 0,_doc.TextLength )
	End
	
	#rem monkeydoc Performs a cut.
	#end
	Method Cut()
		If _readOnly Return
		Copy()
		ReplaceText( "" )
	End
	
	#rem monkeydoc Performs a copy.
	#end
	Method Copy()
		Local min:=Min( _anchor,_cursor )
		Local max:=Max( _anchor,_cursor )
		Local text:=_doc.Text.Slice( min,max )
		App.ClipboardText=text
	End
	
	#rem monkeydoc Performs a paste.
	#end
	Method Paste()
	
		If _readOnly Return
		
		If App.ClipboardTextEmpty Return
		
		Local text:String=App.ClipboardText
		text=text.Replace( "~r~n","~n" )
		text=text.Replace( "~r","~n" )
		
		If text ReplaceText( text )
	End
	
	Protected
	
	Method OnThemeChanged() Override
	
		UpdateColors()
	End
	
	Method OnValidateStyle() Override
	
		Local style:=RenderStyle
		
		_font=style.Font
		
		_charw=_font.TextWidth( "X" )
		_charh=_font.Height
		
		_tabw=_charw*_tabStop
		
		UpdateLines()
	End
	
	Method OnMeasureContent:Vec2i() Override
	
		If _wordWrap Return New Vec2i( 0,0 )
		
		If _wrapw<>$7fffffff
			_wrapw=$7fffffff
			UpdateLines()
		Endif
		
		Return New Vec2i( _lines.Top.maxWidth+_charw,_lines.Top.rect.Bottom )
	End

	Method OnMeasureContent2:Vec2i( size:Vec2i ) Override
	
		If Not _wordWrap Return New Vec2i( 0,0 )
		
		If _wrapw<>size.x
			_wrapw=size.x
			UpdateLines()
		Endif
				
		Return New Vec2i( _lines.Top.maxWidth,_lines.Top.rect.Bottom )
	End
	
	Method OnRenderContent( canvas:Canvas ) Override

		If App.KeyView=Self And Not _blinkTimer RestartBlinkTimer()
		
		Local clip:=VisibleRect
		
		Local firstLine:=LineAtPoint( New Vec2i( 0,clip.Top ) ) 
		Local lastLine:=LineAtPoint( New Vec2i( 0,clip.Bottom-1 ) )+1
		
		If _cursor<>_anchor
		
			Local min:=CharRect( Min( _anchor,_cursor ) )
			Local max:=CharRect( Max( _anchor,_cursor ) )
			
			canvas.Color=_selColor
			
			If min.Y=max.Y
				canvas.DrawRect( min.Left,min.Top,max.Left-min.Left,min.Height )
			Else
				canvas.DrawRect( min.Left,min.Top,(clip.Right-min.Left),min.Height )
				canvas.DrawRect( 0,min.Bottom,clip.Right,max.Top-min.Bottom )
				canvas.DrawRect( 0,max.Top,max.Left,max.Height )
			Endif
			
		Else If Not _readOnly And App.KeyView=Self And _blinkOn
		
			canvas.Color=_cursorColor
			
			If _blockCursor
				canvas.DrawRect( _cursorRect.X,_cursorRect.Y,_cursorRect.Width,_cursorRect.Height )
			Else
				canvas.DrawRect( _cursorRect.X-0,_cursorRect.Y,2,_cursorRect.Height )
				canvas.DrawRect( _cursorRect.X-2,_cursorRect.Y,6,2 )
				canvas.DrawRect( _cursorRect.X-2,_cursorRect.Y+_cursorRect.Height-2,6,2 )
			Endif
			
		Endif

		_textColors[0]=RenderStyle.TextColor
		
		For Local line:=firstLine Until lastLine
		
			RenderLine( canvas,line )
			
		Next
		
	End
	
	Method OnKeyDown:Bool( key:Key,modifiers:Modifier=Null )
	
		Select key
		Case Key.Backspace
			
			If _anchor=_cursor And _cursor>0 SelectText( _cursor-1,_cursor )
			ReplaceText( "" )
				
		Case Key.KeyDelete
			
			If _anchor=_cursor And _cursor<_doc.Text.Length SelectText( _cursor,_cursor+1 )
			ReplaceText( "" )
				
		Case Key.Tab
			
			Local min:=_doc.FindLine( Min( _cursor,_anchor ) )
			Local max:=_doc.FindLine( Max( _cursor,_anchor ) )
				
			If min=max
				ReplaceText( "~t" )
			Else
				
				'block tab/untab
				Local lines:=New StringStack
					
				For Local i:=min Until max
					lines.Push( _doc.GetLine( i ) )
				Next
					
				Local go:=True
				
				If modifiers & Modifier.Shift
					
					For Local i:=0 Until lines.Length
						
						If Not lines[i].Trim()
							lines[i]+="~n"
							Continue
						Endif
							
						If lines[i][0]=9 
							lines[i]=lines[i].Slice( 1 )+"~n"
							Continue
						Endif
							
						go=False
						Exit
					Next
				Else
					
					For Local i:=0 Until lines.Length
						lines[i]="~t"+lines[i]+"~n"
					Next
				Endif
					
				If go
					SelectText( _doc.StartOfLine( min ),_doc.StartOfLine( max ) )
					ReplaceText( lines.Join( "" ) )
					SelectText( _doc.StartOfLine( min ),_doc.StartOfLine( max ) )
					Return False					
				Endif
					
			Endif
				
		Case Key.Enter,Key.KeypadEnter
			
			ReplaceText( "~n" )
				
			'auto indent!
			Local line:=CursorLine
			If line>0
				
				Local ptext:=_doc.GetLine( line-1 )
					
				Local indent:=ptext
				For Local i:=0 Until ptext.Length
					If ptext[i]<=32 Continue
					indent=ptext.Slice( 0,i )
					Exit
				Next
					
				If indent ReplaceText( indent )
				
			Endif
				
		Case Key.Left
			
			If _anchor<>_cursor And Not (modifiers & Modifier.Shift)
				_cursor=Min( _anchor,_cursor )
			Else If _cursor
				_cursor-=1
			Endif
			UpdateCursor()
				
		Case Key.Right
		
			If _anchor<>_cursor And Not (modifiers & Modifier.Shift)
				_cursor=Max( _anchor,_cursor )
			Else If _cursor<_doc.Text.Length 
				_cursor+=1
			Endif
			UpdateCursor()
				
		Case Key.Home
			
			_cursor=_doc.StartOfLine( CursorLine )
			UpdateCursor()
				
		Case Key.KeyEnd
			
			_cursor=_doc.EndOfLine( CursorLine )
			UpdateCursor()

		Case Key.Up
			
			MoveLine( -1 )
			
		Case Key.Down
			
			MoveLine( 1 )
				
		Case Key.PageUp
			
			Local n:=VisibleRect.Height/_charh-1		'shouldn't really use cliprect here...
			MoveLine( -n )
				
		Case Key.PageDown
			
			Local n:=VisibleRect.Height/_charh-1
			MoveLine( n )
		
		Default

			Return False
		End
		
		Return True
	End
	
	Method OnControlKeyDown:bool( key:Key,modifiers:Modifier=Null ) Virtual

		Select key
		Case Key.A
			SelectAll()
		Case Key.X
			Cut()
		Case Key.C
			Copy()
		Case Key.V
			Paste()
		Case Key.Z
			Undo()
		Case Key.Y
			Redo()
		Case Key.Home
			_cursor=0
			UpdateCursor()
			Return True
		Case Key.KeyEnd
			_cursor=_doc.TextLength
			UpdateCursor()
			Return True
		Case Key.Left
			If _anchor<>_cursor And Not (modifiers & Modifier.Shift)
				_cursor=Min( _anchor,_cursor )
			Endif
			Local term:=New Int[1]
			Local start:=FindWord( _cursor,term )
			_cursor=Max( start-1,0 )
			Local text:=Text
			While _cursor And text[_cursor-1]<=32 And text[_cursor-1]<>10
				_cursor-=1
			Wend
			UpdateCursor()
			Return True
		Case Key.Right
			If _anchor<>_cursor And Not (modifiers & Modifier.Shift)
				_cursor=Max( _anchor,_cursor )
			Endif
			Local term:=New Int[1]
			Local start:=FindWord( _cursor,term )
			_cursor=term[0]
			Local text:=Text
			While _cursor<text.Length And text[_cursor]<=32 And text[_cursor]<>10
				_cursor+=1
			Wend
			UpdateCursor()
			Return True
		End
		
		Return False
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		If _readOnly
			If _macosMode
				If (event.Modifiers & Modifier.Gui) And (event.Key=Key.C Or event.Key=Key.A)
					'Copy, Select All
				Else
					Return
				Endif
			Else			
				If (event.Modifiers & Modifier.Control) And (event.Key=Key.C Or event.Key=Key.A)
					'Copy, Select All
				Else
					Return
				Endif
			Endif
		Endif
	
		Select event.Type
		
		Case EventType.KeyDown,EventType.KeyRepeat
		
			If _macosMode
			
				If event.Modifiers & Modifier.Gui
				
					Select event.Key
					Case Key.Home,Key.KeyEnd
					Default
						If Not OnControlKeyDown( event.Key,event.Modifiers ) Return
					End
					
				Else If event.Modifiers & Modifier.Control
				
					Select event.Key
					Case Key.A
						OnKeyDown( Key.Home )
					Case Key.E
						OnKeyDown( Key.KeyEnd )
					End
					
				Else

					Select event.Key
					Case Key.Home
						OnControlKeyDown( Key.Home )
					Case Key.KeyEnd
						OnControlKeyDown( Key.KeyEnd )
					Default
						If Not OnKeyDown( event.Key,event.Modifiers ) Return
					End

				Endif
			
			Else
			
				If event.Modifiers & Modifier.Control
					If Not OnControlKeyDown( event.Key,event.Modifiers ) Return
				Else
					If Not OnKeyDown( event.Key,event.Modifiers ) Return
				Endif
			
			Endif
			
			If Not (event.Modifiers & Modifier.Shift) _anchor=_cursor
			
		Case EventType.KeyChar
		
			If _undos.Length
			
				Local undo:=_undos.Top
				If Not undo.text And _cursor=undo.cursor
					ReplaceText( _anchor,_cursor,event.Text )
					undo.cursor=_cursor
					Return
				Endif
				
			Endif
		
			ReplaceText( event.Text )
			
		End
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseDown
		
			Select event.Clicks
			Case 1

				_cursor=CharAtPoint( event.Location )
				
				If Not (event.Modifiers & Modifier.Shift) _anchor=_cursor
				
				_dragging=True
				
				MakeKeyView()
				
				UpdateCursor()
			
			Case 2

				Local term:=New Int[1]
				Local start:=FindWord( CharAtPoint( event.Location ),term )
				
				SelectText( start,term[0] )
				
			Case 3
			
				SelectLine( LineAtPoint( event.Location ) )
			
			End
		
			Return
			
		#rem			
		Case EventType.MouseClick
		
			_cursor=CharAtPoint( event.Location )
			
			If Not (event.Modifiers & Modifier.Shift) _anchor=_cursor
			
			_dragging=True
			
			MakeKeyView()
			
			UpdateCursor()
			
		Case EventType.MouseDoubleClick
		
			Local term:=New Int[1]
			Local start:=FindWord( CharAtPoint( event.Location ),term )
			
			SelectText( start,term[0] )
		#end
		
		Case EventType.MouseUp
		
			_dragging=False
			
		Case EventType.MouseMove
		
			If _dragging
			
				_cursor=CharAtPoint( event.Location )

				UpdateCursor()
				
			Endif
			
		Case EventType.MouseWheel
		
			Return
		End
		
		event.Eat()
	End
	
	Private
	
	Struct Line
		Field rect:Recti
		Field maxWidth:Int
	End
	
	Class UndoOp
		Field text:String
		Field anchor:Int
		Field cursor:Int
	End
	
	Field _doc:TextDocument
	Field _lines:=New Stack<Line>
	Field _tabStop:Int=4
	Field _tabSpaces:String="    "
	Field _cursorColor:Color=New Color( 0,.5,1,1 )
	Field _selColor:Color=New Color( 1,1,1,.25 )
	Field _blockCursor:Bool=True
	Field _blinkRate:Float=0
	Field _blinkOn:Bool=True
	Field _blinkTimer:Timer
	
#if __HOSTOS__="macos"	
	Field _macosMode:Bool=True
#else
	Field _macosMode:Bool=False
#endif
	
	Field _textColors:Color[]
	
	Field _anchor:Int
	Field _cursor:Int
	
	Field _font:Font
	Field _charw:Int
	Field _charh:Int
	Field _tabw:Int
	
	Field _wordWrap:Bool=False
	Field _wrapw:Int=$7fffffff
	
	Field _cursorRect:Recti
	Field _vcursor:Vec2i
	
	Field _undos:=New Stack<UndoOp>
	Field _redos:=New Stack<UndoOp>
	
	Field _dragging:Bool
	
	Field _readOnly:Bool

	Method UpdateColors()
		
		CursorColor=App.Theme.GetColor( "textview-cursor" )
		
		SelectionColor=App.Theme.GetColor( "textview-selection" )
	
		Local colors:=New Color[8]
		
		For Local i:=0 Until 8
			colors[i]=App.Theme.GetColor( "textview-color"+i )
		Next
		
		TextColors=colors
	End
		
	Method CancelBlinkTimer()
		If Not _blinkTimer Return
		_blinkTimer.Cancel()
		_blinkTimer=Null
		_blinkOn=True
	End
	
	Method RestartBlinkTimer()
		CancelBlinkTimer()
		If Not _blinkRate Or App.KeyView<>Self Return
		_blinkTimer=New Timer( _blinkRate,Lambda()
			If App.KeyView<>Self Or Not _blinkRate
				CancelBlinkTimer()
				Return
			Endif
			_blinkOn=Not _blinkOn
			RequestRender()
		End )
	End
	
	Method UpdateCursor()
	
		Local rect:=CharRect( _cursor )
		
		EnsureVisible( rect )

		_vcursor=rect.Origin
			
		If rect<>_cursorRect
		
			RestartBlinkTimer()
		
			_cursorRect=rect
			
			CursorMoved()
		Endif
		
		RequestRender()
	End
	
	Method FindWord:Int( from:Int,term:Int[] )

		Local text:=Text
		
		If from<0
			term[0]=0
			Return 0
		Else If from>=text.Length
			term[0]=text.Length
			Return text.Length
		Else If text[from]=10
			term[0]=from+1
			Return from
		Endif
	
		Local start:=from,ends:=from+1
		
		If text[from]<=32
			While start And text[start-1]<=32 And text[start-1]<>10
				start-=1
			Wend
			While ends<text.Length And text[ends]<=32 And text[ends]<>10
				ends+=1
			Wend
		Else if IsIdent( text[start] )
			While start And IsIdent( text[start-1] )
				start-=1
			Wend
			While ends<text.Length And IsIdent( text[ends] )
				ends+=1
			Wend
		Else
			While start And text[start-1]>32 And Not IsIdent( text[start-1] )
				start-=1
			Wend
			While ends<text.Length And text[ends]>32 And Not IsIdent( text[ends] )
				ends+=1
			Wend
		Endif

		term[0]=ends
		Return start
	End
	
	Method WordLength:Int( text:String,i0:Int,eol:Int )

		Local i1:=i0
		
		If text[i1]<=32
			While i1<eol And text[i1]<=32
				i1+=1
			Wend
		Else If IsIdent( text[i1] )
			While i1<eol And IsIdent( text[i1] )
				i1+=1
			Wend
		Else
			While i1<eol And text[i1]>32 And Not IsIdent( text[i1] )
				i1+=1
			Wend
		Endif
		
		Return i1-i0
	End
	
	Method WordWidth:Int( text:String,i0:Int,eol:Int,x0:Int )
	
		Local i1:=i0,x1:=x0
		
		If text[i0]<=32
			While i1<eol And text[i1]<=32
				If text[i1]=9
					x1=Int( (x1+_tabw)/_tabw ) * _tabw
				Else
					x1+=_charw
				Endif
				i1+=1
			Wend
		Else 
			If IsIdent( text[i1] )
				While i1<eol And IsIdent( text[i1] )
					i1+=1
				Wend
			Else
				While i1<eol And text[i1]>32 And Not IsIdent( text[i1] )
					i1+=1
				Wend
			Endif
			x1+=_font.TextWidth( text.Slice( i0,i1 ) )
		Endif
		
		Return x1-x0
	End
	
	Method MeasureLine:Vec2i( line:Int )
	
		Local text:=_doc.Text
		Local i0:=_doc.StartOfLine( line )
		Local eol:=_doc.EndOfLine( line )
		
		Local x0:=0,y0:=_charh,maxw:=0

		While i0<eol
				
			Local w:=WordWidth( text,i0,eol,x0 )
			
			If x0+w>_wrapw	'-_charw
				maxw=Max( maxw,x0 )
				y0+=_charh
				x0=0
			Endif
			x0+=w
			
			i0+=WordLength( text,i0,eol )
		Wend
		
		maxw=Max( maxw,x0 )

		Return New Vec2i( maxw,y0 )
	End
	
	Method MoveLine( delta:Int )
	
		Local vcursor:=_vcursor
		
		_vcursor.y+=delta * _charh
		
		_cursor=CharAtPoint( _vcursor )
		
		UpdateCursor()
		
		_vcursor.x=vcursor.x
	End
	
	Method UpdateLines()
	
		Local liney:=0,maxWidth:=0
			
		For Local i:=0 Until _lines.Length
			
			Local size:=MeasureLine( i )
				
			maxWidth=Max( maxWidth,size.x )
				
			_lines.Data[i].maxWidth=maxWidth
			_lines.Data[i].rect=New Recti( 0,liney,size.x,liney+size.y )
				
			liney+=size.y
			
		Next
			
		UpdateCursor()
	End
	
	Method RenderLine( canvas:Canvas,line:Int )
	
		Local text:=_doc.Text
		Local colors:=_doc.Colors
		
		Local i0:=_doc.StartOfLine( line )
		Local eol:=_doc.EndOfLine( line )
		
		Local x0:=0,y0:=_lines[line].rect.Top
		
		While i0<eol
		
			Local w:=WordWidth( text,i0,eol,x0 )
			Local l:=WordLength( text,i0,eol )
				
			If x0+w>_wrapw	'-_charw
				y0+=_charh
				x0=0
			Endif
			
			If text[i0]<=32
				x0+=w
				i0+=l
				Continue
			Endif
			
			Local i1:=i0+l
			
			While i0<i1
			
				Local start:=i0
				Local color:=colors[start]
				i0+=1
			
				While i0<i1 And colors[i0]=color
					i0+=1
				Wend
				
				If color<0 Or color>=_textColors.Length color=0

				canvas.Color=_textColors[color]
				
				Local str:=text.Slice( start,i0 )
				
				canvas.DrawText( str,x0,y0 )
				
				x0+=_font.TextWidth( str )
			Wend
			
		Wend
		
	End
	
	Method LinesModified( first:Int,removed:Int,inserted:Int )
	
'		Print "Lines modified: first="+first+", removed="+removed+", inserted="+inserted+", _charh="+_charh

		ValidateStyle()

		Local last:=first+inserted+1
		
		Local dlines:=inserted-removed
		
		If dlines>=0
		
			_lines.Resize( _lines.Length+dlines )

			Local i:=_lines.Length
			While i>last
				i-=1
				_lines[i]=_lines[i-dlines]
			Wend
		
		Endif

		Local liney:=0,maxWidth:=0
		If first
			liney=_lines[first-1].rect.Bottom
			maxWidth=_lines[first-1].maxWidth
		Endif
		
		For Local i:=first Until last
		
			Local size:=MeasureLine( i )
			
			maxWidth=Max( maxWidth,size.x )
			
			_lines.Data[i].maxWidth=maxWidth
			_lines.Data[i].rect=New Recti( 0,liney,size.x,liney+size.y )
			
			liney+=size.y
		Next
		
		If dlines<0

			Local i:=last
			While i<_lines.Length+dlines
				_lines[i]=_lines[i-dlines]
				i+=1
			Wend

			_lines.Resize( _lines.Length+dlines )
		Endif
		
		For Local i:=last Until _lines.Length
		
			Local size:=_lines[i].rect.Size
			
			maxWidth=Max( maxWidth,size.x )
			
			_lines.Data[i].maxWidth=maxWidth
			_lines.Data[i].rect=New Recti( 0,liney,size.x,liney+size.y )
			
			liney+=size.y
		Next
		
'		Print "Document width="+_lines.Top.maxWidth+", height="+_lines.Top.rect.Bottom
	End
	
End
