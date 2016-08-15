
Namespace mojox

Alias TextHighlighter:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )

#rem monkeydoc The TextDocument class.
#end
Class TextDocument

	#rem monkeydoc Invoked when text has changed.
	#end
	Field TextChanged:Void()

	#rem monkeydoc Invoked when lines modified.
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
		
		LinesModified( line0,eols1+1,eols2+1 )
		
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

		_doc=New TextDocument
		
		_textColors=New Color[8]
		
		For Local i:=0 Until 7
			_textColors[i]=App.Theme.GetColor( "textview-color"+i )
		Next
	End

	Method New( text:String )
		Self.New()
		
		Document.Text=text
	End
	
	Method New( doc:TextDocument )
		Self.New()
	
		_doc=doc
	End

	#rem monkeydoc Text document.
	#end	
	Property Document:TextDocument()
	
		Return _doc
		
	Setter( doc:TextDocument )
	
		_doc=doc
		
		_cursor=Clamp( _cursor,0,_doc.TextLength )
		_anchor=_cursor
		
		UpdateCursor()
	End
	
	#rem monkeydoc Text colors.
	#end
	Property TextColors:Color[]()
	
		Return _textColors
	
	Setter( textColors:Color[] )
	
		_textColors=textColors
	End
	
	#rem monkeydoc Selection color.
	#end
	Property SelectionColor:Color()
	
		Return _selColor
		
	Setter( selectionColor:Color )
	
		_selColor=selectionColor
	End
	
	#rem monkeydoc Cursor color.
	#end
	Property CursorColor:Color()
	
		Return _cursorColor
	
	Setter( cursorColor:Color )
		_cursorColor=cursorColor
	End
	
	#rem monkeydoc Block cursor flag.
	#end
	Property BlockCursor:Bool()
	
		Return _blockCursor
	
	Setter( blockCursor:Bool )
	
		_blockCursor=blockCursor
	End

	#rem monkeydoc Text.
	#end
	Property Text:String()
	
		Return _doc.Text
		
	Setter( text:String )
	
		_doc.Text=text
	End
	
	#rem monkeydoc Read only flags.
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

	#rem monkeydoc Cursor column.
	#end
	Property CursorColumn:Int()
	
		Return Column( _cursor )
	End
	
	#rem monkeydoc Cursor row.
	#end
	Property CursorRow:Int()
	
		Return Row( _cursor )
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
	
	#rem monkeydoc Line height.
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
	
'		Local anchor:=_anchor
'		Local cursor:=_cursor
		
		SelectText( _doc.TextLength,_doc.TextLength )
		ReplaceText( text )
		
'		SelectText( anchor,cursor )
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
	
	Private
	
	Class UndoOp
		Field text:String
		Field anchor:Int
		Field cursor:Int
	End
	
	Field _doc:TextDocument
	Field _tabStop:Int=4
	Field _tabSpaces:String="    "
	Field _cursorColor:Color=New Color( 0,.5,1,1 )
	Field _selColor:Color=New Color( 1,1,1,.25 )
	Field _blockCursor:Bool=True
	
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
	
	Field _cursorRect:Recti
	Field _columnX:Int
	
	Field _undos:=New Stack<UndoOp>
	Field _redos:=New Stack<UndoOp>
	
	Field _dragging:Bool
	
	Field _readOnly:Bool
	
	Method Row:Int( index:Int )
		Return _doc.FindLine( index )
	End
	
	Method Column:Int( index:Int )
		Return index-_doc.StartOfLine( _doc.FindLine( index ) )
	End
	
	Method UpdateCursor()
	
		ValidateStyle()
	
		Local rect:=MakeCursorRect( _cursor )
		
		EnsureVisible( rect )
			
		If rect<>_cursorRect
		
			_cursorRect=rect
			_columnX=rect.X
			
			CursorMoved()
		Endif
		
		RequestRender()
	End
	
	Method MakeCursorRect:Recti( cursor:Int )
	
		ValidateStyle()
		
		Local line:=_doc.FindLine( cursor )
		Local text:=_doc.GetLine( line )
		
		Local x:=0.0,i0:=0,e:=cursor-_doc.StartOfLine( line )
		
		While i0<e
		
			Local i1:=text.Find( "~t",i0 )
			If i1=-1 i1=e
			
			If i1>i0
				If i1>e i1=e
				x+=_font.TextWidth( text.Slice( i0,i1 ) )
				If i1=e Exit
			Endif
			
			x=Int( (x+_tabw)/_tabw ) * _tabw
			i0=i1+1
			
		Wend
		
		Local w:=_charw
		
		If e<text.Length
			If text[e]=9
'				w=Int( (x+_tabw)/_tabw ) * _tabw-x
			Else
				w=_font.TextWidth( text.Slice( e,e+1 ) )
			Endif
		Endif
		
		Local y:=line*_charh
		
		Return New Recti( x,y,x+w,y+_charh )
	End
	
	Method PointXToIndex:Int( px:Int,line:Int )
	
		ValidateStyle()

		Local text:=_doc.GetLine( line )
		Local sol:=_doc.StartOfLine( line )
		
		Local x:=0.0,i0:=0,e:=text.Length
		
		While i0<e
		
			Local i1:=text.Find( "~t",i0 )
			If i1=-1 i1=e
			
			If i1>i0
				For Local i:=i0 Until i1
					x+=_font.TextWidth( text.Slice( i,i+1 ) )
					If px<x Return sol+i
				Next
				If i1=e Exit
			Endif
			
			x=Int( (x+_tabw)/_tabw ) * _tabw
			If px<x Return sol+i0
			
			i0=i1+1
		Wend
		
		Return sol+e
	
	End
	
	Method PointToIndex:Int( p:Vec2i )
	
		If p.y<0 Return 0
		
		Local line:=p.y/_charh
		If line>_doc.NumLines Return _doc.TextLength
		
		Return PointXToIndex( p.x,line )
	End
	
	Method MoveLine( delta:Int )
	
		Local line:=Clamp( Row( _cursor )+delta,0,_doc.NumLines-1 )
		
		_cursor=PointXToIndex( _columnX,line )
		
		Local x:=_columnX
		
		UpdateCursor()
		
		_columnX=x
	End
	
	Protected
	
	Method OnValidateStyle() Override
	
		Local style:=RenderStyle
		
		_font=style.Font
		
		_charw=_font.TextWidth( "X" )
		_charh=_font.Height
		
		_tabw=_charw*_tabStop
		
		UpdateCursor()
	End
	
	Method OnMeasureContent:Vec2i() Override

		Return New Vec2i( 320*_charw,_doc.NumLines*_charh )
'		Return New Vec2i( 160,_doc.NumLines*_charh )
	End

	Method OnRenderContent( canvas:Canvas ) Override
	
		Local clip:=VisibleRect
		
		Local firstVisLine:=Max( clip.Top/_charh,0 )
		Local lastVisLine:=Min( (clip.Bottom-1)/_charh+1,_doc.NumLines )
		
		If _cursor<>_anchor
		
			Local min:=MakeCursorRect( Min( _anchor,_cursor ) )
			Local max:=MakeCursorRect( Max( _anchor,_cursor ) )
			
			canvas.Color=_selColor
			
			If min.Y=max.Y
				canvas.DrawRect( min.Left,min.Top,max.Left-min.Left,min.Height )
			Else
				canvas.DrawRect( min.Left,min.Top,(clip.Right-min.Left),min.Height )
				canvas.DrawRect( 0,min.Bottom,clip.Right,max.Top-min.Bottom )
				canvas.DrawRect( 0,max.Top,max.Left,max.Height )
			Endif
			
		Else If Not _readOnly And App.KeyView=Self
		
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
		
		For Local line:=firstVisLine Until lastVisLine
		
			Local sol:=_doc.StartOfLine( line )
			Local eol:=_doc.EndOfLine( line )

			Local text:=_doc.Text.Slice( sol,eol )
			Local colors:=_doc.Colors
			
			Local x:=0,y:=line*_charh,i0:=0
			
			While i0<text.Length
			
				Local i1:=text.Find( "~t",i0 )
				If i1=-1 i1=text.Length
				
				If i1>i0
					
					Local color:=colors[sol+i0]
					Local start:=i0
					
					Repeat
						
						While i0<i1 And colors[sol+i0]=color
							i0+=1
						Wend
						
						If i0>start
							If color<0 Or color>=_textColors.Length color=0
							canvas.Color=_textColors[color]
							
							Local t:=text.Slice( start,i0 )
							canvas.DrawText( t,x,y )
							x+=Style.Font.TextWidth( t )
						Endif
						
						If i0=i1 Exit
						
						color=colors[sol+i0]
						start=i0
						i0+=1
						
					Forever
				
					If i1=text.Length Exit
					
				Endif
				
				x=Int( (x+_tabw) / _tabw ) * _tabw
				
				i0=i1+1
			
			Wend
			
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
				
		Case Key.Enter
			
			ReplaceText( "~n" )
				
			'auto indent!
			Local line:=CursorRow
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
			
			If _cursor 
				_cursor-=1
				UpdateCursor()
			Endif
				
		Case Key.Right
			
			If _cursor<_doc.Text.Length
				_cursor+=1
				UpdateCursor()
			Endif
				
		Case Key.Home
			
			_cursor=_doc.StartOfLine( Row( _cursor ) )
			UpdateCursor()
				
		Case Key.KeyEnd
			
			_cursor=_doc.EndOfLine( Row( _cursor ) )
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
	
	Method OnControlKeyDown:bool( key:Key )

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
		End
		
		Return False
		
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		If _readOnly Return
	
		Select event.Type
		
		Case EventType.KeyDown,EventType.KeyRepeat
		
			If _macosMode
			
				If event.Modifiers & Modifier.Gui
				
					Select event.Key
					Case Key.A,Key.X,Key.C,Key.V,Key.Z,Key.Y
					
						If Not OnControlKeyDown( event.Key ) Return
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
					
						If Not OnKeyDown( event.Key ) Return
					End

				Endif
			
			Else
			
				If event.Modifiers & Modifier.Control
				
					If Not OnControlKeyDown( event.Key ) Return
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
		
			Return
			
		Case EventType.MouseClick
		
			_cursor=PointToIndex( event.Location )
			_anchor=_cursor
			
			_dragging=True
			
			MakeKeyView()
			
			UpdateCursor()

		Case EventType.MouseUp
		
			_dragging=False
			
		Case EventType.MouseMove
		
			If _dragging
			
				_cursor=PointToIndex( event.Location )

				UpdateCursor()
				
			Endif
			
		Case EventType.MouseWheel
		
			Return
		End
		
		event.Eat()
	End
	
'	Method OnKeyViewChanged( oldKeyView:View,newKeyView:View ) Override
	
'		If newKeyView=Self UpdateCursor()

'	End
	
End
