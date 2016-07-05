
Namespace mojox

Alias TextHighlighter:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )

Class TextDocument

	Field LinesModified:Void( first:Int,removed:Int,inserted:Int )

	Field TextChanged:Void()
	
	Method New()
	
		_lines.Push( New Line )
	End

	Property Text:String()
	
		Return _text
		
	Setter( text:String )
	
		text=text.Replace( "~r~n","~n" )
		text=text.Replace( "~r","~n" )
	
		ReplaceText( 0,_text.Length,text )
	End
	
	Property TextLength:Int()
	
		Return _text.Length
	End
	
	Property LineCount:Int()
	
		Return _lines.Length
	End
	
	Property Colors:Byte[]()
	
		Return _colors.Data
	End
	
	Property TextHighlighter:TextHighlighter()
	
		Return _highlighter
	
	Setter( textHighlighter:TextHighlighter )
	
		_highlighter=textHighlighter
	End
	
	Method LineState:Int( line:Int )
		If line>=0 And line<_lines.Length Return _lines[line].state
		Return -1
	End
	
	Method StartOfLine:Int( line:Int )
		If line<=0 Return 0
		If line<_lines.Length Return _lines[line-1].eol+1
		Return _text.Length
	End
	
	Method EndOfLine:Int( line:Int )
		If line<0 Return 0
		If line<_lines.Length Return _lines[line].eol
		Return _text.Length
	End
	
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

	Method GetLine:String( line:Int )
		Return _text.Slice( StartOfLine( line ),EndOfLine( line ) )
	End
	
	Method AppendText( text:String )
	
		ReplaceText( _text.Length,_text.Length,text )
	End
	
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
		
'		Print "lines="+_lines.Length+", chars="+_text.Length

		LinesModified( line0,eols1+1,eols2+1 )
		
		TextChanged()
	End
	
	#rem
		_lines.Resize( _lines.Length+dlines )
		
		
		'eols1=eols deleted, eols2=eols inserted, dchars=delta chars
		
		
		Local oldlen:=Text.Length
		_text=_text.Slice( 0,min )+text+_text.Slice( max )
		
		_colors.Resize( _text.Length )
		
		Local p:=Varptr( _colors.Data[0] )
		libc.memmove( p+min+text.Length,p+max,oldlen-max )
		libc.memset( p+min,0,text.Length )
		
		UpdateEols()
		
		If eols1>eols2
			LinesDeleted( FindLine( min ),eols1-eols2 )
		Else If eols2>eols1
			LinesInserted( FindLine( min ),eols2-eols1 )
		Endif
		
		TextChanged()
	End
	#end
	
	Method HighlightLine( line:Int )
#rem	
		Return
	
		If _highlighter=Null Return
		
		If _lines[line].state<>-1 Return
	
		Local sol:=StartOfLine( line )
		Local eol:=EndOfLine( line )
		If eol>sol
			Local colors:=_colors.Data
			_highlighter( _text,colors,sol,eol )
		Endif
		
		_lines.Data[line].state=0
#end

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
	
	#rem
	'not very efficient - scans entire document and recalcs all EOLs.
	'
	Method UpdateEols()
	
		_nlines=1
		Local eol:=-1
		
		Repeat
			eol=_text.Find( "~n",eol+1 )
			If eol=-1 Exit
			_nlines+=1
		Forever
		
		_eols.Resize( _nlines )
		
		Local line:=0
		Repeat
			eol=_text.Find( "~n",eol+1 )
			If eol=-1
				_eols.Data[line].eol=_text.Length
				Exit
			Endif
			
			_eols.Data[line].eol=eol
			line+=1
		Forever
		
		'invalidate all line coloring
		'
		_colors.Resize( _text.Length )
		
		For Local i:=0 Until _nlines
			Local sol:=StartOfLine( i )
			If sol>=_colors.Length Exit
			_colors[ sol ]=-1
		Next
		
'		Print "lines="+_nlines
'		For Local i:=0 Until _nlines
'			Print "eol="+_eols[i]
'		Next
	End
	
	#end
	
End

Class TextView Extends View

	Field CursorMoved:Void()

	Field FieldEntered:Void()
	
	Field FieldTabbed:Void()

	Method New()
	
		Layout="fill"
	
		Style=Style.GetStyle( "mojo.TextView" )

		_doc=New TextDocument
		
'		_textColors=New Color[]( New Color( 0,0,0,1 ),New Color( 0,0,.5,1 ),New Color( 0,.5,0,1 ),New Color( .5,0,0,1 ),New Color( .5,0,.5,1 ) )
		_textColors=New Color[]( New Color( 1,1,1,1 ),New Color( 0,1,0,1 ),New Color( 1,1,0,1 ),New Color( 0,.5,1,1 ),New Color( 0,1,.5,1 ) )
	End
	
	Method New( doc:TextDocument )
		Self.New()
	
		_doc=doc
	End
	
	Property Document:TextDocument()
	
		Return _doc
		
	Setter( doc:TextDocument )
	
		_doc=doc
		
		_cursor=Clamp( _cursor,0,_doc.TextLength )
		_anchor=_cursor
		
		UpdateCursor()
	End
	
	Property TextColors:Color[]()
	
		Return _textColors
	
	Setter( textColors:Color[] )
	
		_textColors=textColors
	End
	
	Property SelectionColor:Color()
	
		Return _selColor
		
	Setter( selectionColor:Color )
	
		_selColor=selectionColor
	End
	
	Property CursorColor:Color()
	
		Return _cursorColor
	
	Setter( cursorColor:Color )
	
		_cursorColor=cursorColor
	End
	
	Property BlockCursor:Bool()
	
		Return _blockCursor
	
	Setter( blockCursor:Bool )
	
		_blockCursor=blockCursor
	End

	Property Text:String()
	
		Return _doc.Text
		
	Setter( text:String )
	
		_doc.Text=text
	End
	
	Property ReadOnly:Bool()
	
		Return _readOnly
	
	Setter( readOnly:Bool )
	
		_readOnly=readOnly
	End
	
	Property TabsStop:Int()
	
		Return _tabStop
		
	Setter( tabStop:Int )
	
		_tabStop=tabStop
		_tabSpaces=" "
		For Local i:=1 Until tabStop
			_tabSpaces+=" "
		Next
	End
	
	Property Cursor:Int()
	
		Return _cursor
	End
	
	Property Anchor:Int()
	
		Return _anchor
	End
	
	Property CursorColumn:Int()
	
		Return Column( _cursor )
	End
	
	Property CursorRow:Int()
	
		Return Row( _cursor )
	End
	
	Property CursorRect:Recti()

		Return _cursorRect
	End
	
	Property LineHeight:Int()
	
		Return _charh
	End
	
	Property CanUndo:Bool()
	
		Return Not _readOnly And Not _undos.Empty
	End
	
	Property CanRedo:Bool()
	
		Return Not _readOnly And Not _redos.Empty
	End
	
	Property CanCut:Bool()
	
		Return Not _readOnly And _anchor<>_cursor
	End
	
	Property CanCopy:Bool()
	
		Return _anchor<>_cursor
	End
	
	Property CanPaste:Bool()
	
		Return Not _readOnly And Not App.ClipboardTextEmpty
	End
	
	Property Container:View() Override
	
		If Not _scroller
		
			_scroller=New ScrollView
			_scroller.ContentView=Self
			
			CursorMoved+=Lambda()
				_scroller.EnsureVisible( CursorRect-New Vec2i( _gutterw,0 ) )
			End
			
		Endif
		
		Return _scroller
	End
	
	Method Clear()
		SelectAll()
		ReplaceText( "" )
	End
	
	Method SelectText( anchor:Int,cursor:Int )
		_anchor=Clamp( anchor,0,_doc.TextLength )
		_cursor=Clamp( cursor,0,_doc.TextLength )
		UpdateCursor()
	End
	
	Method ReplaceText( text:String )
	
		Local undo:=New UndoOp
		undo.text=_doc.Text.Slice( Min( _anchor,_cursor ),Max( _anchor,_cursor ) )
		undo.anchor=Min( _anchor,_cursor )
		undo.cursor=undo.anchor+text.Length
		_undos.Push( undo )
		
		ReplaceText( _anchor,_cursor,text )
	End
	
	'non-undoable
	Method ReplaceText( anchor:Int,cursor:Int,text:String )
			
		_redos.Clear()
	
		_doc.ReplaceText( anchor,cursor,text )
		_cursor=Min( anchor,cursor )+text.Length
		_anchor=_cursor
		
		UpdateCursor()
	End
	
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
	
	Method SelectAll()
		SelectText( 0,_doc.TextLength )
	End
	
	Method Cut()
		If _readOnly Return
		Copy()
		ReplaceText( "" )
	End
	
	Method Copy()
		Local min:=Min( _anchor,_cursor )
		Local max:=Max( _anchor,_cursor )
		Local text:=_doc.Text.Slice( min,max )
		App.ClipboardText=text
	End
	
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
	
	Field _textColors:Color[]
	
	Field _anchor:Int
	Field _cursor:Int
	
	Field _tabw:Int
	Field _charw:Int
	Field _charh:Int
	Field _gutterw:Int
	Field _columnX:Int
	Field _cursorRect:Recti
	
	Field _contentMargin:Recti
	
	Field _undos:=New Stack<UndoOp>
	Field _redos:=New Stack<UndoOp>
	
	Field _dragging:Bool
	
	Field _scroller:ScrollView
	
	Field _readOnly:Bool
	
	Method Row:Int( index:Int )
		Return _doc.FindLine( index )
	End
	
	Method Column:Int( index:Int )
		Return index-_doc.StartOfLine( _doc.FindLine( index ) )
	End
	
	Method UpdateCursor()
	
		Local rect:=MakeCursorRect( _cursor )
		If rect=_cursorRect Return
		
		_cursorRect=rect
		_columnX=rect.X
		
		CursorMoved()
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
				x+=Style.DefaultFont.TextWidth( text.Slice( i0,i1 ) )
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
				w=Style.DefaultFont.TextWidth( text.Slice( e,e+1 ) )
			Endif
		Endif
		
		x+=_gutterw
		Local y:=line*_charh
		
		Return New Recti( x,y,x+w,y+_charh )
	End
	
	Method PointXToIndex:Int( px:Int,line:Int )
	
		ValidateStyle()

		px=Max( px-_gutterw,0 )
		
		Local text:=_doc.GetLine( line )
		Local sol:=_doc.StartOfLine( line )
		
		Local x:=0.0,i0:=0,e:=text.Length
		
		While i0<e
		
			Local i1:=text.Find( "~t",i0 )
			If i1=-1 i1=e
			
			If i1>i0
				For Local i:=i0 Until i1
					x+=Style.DefaultFont.TextWidth( text.Slice( i,i+1 ) )
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
		If line>_doc.LineCount Return _doc.TextLength
		
		Return PointXToIndex( p.x,line )
	End
	
	Method MoveLine( delta:Int )
	
		Local line:=Clamp( Row( _cursor )+delta,0,_doc.LineCount-1 )
		
		_cursor=PointXToIndex( _columnX,line )
		
		Local x:=_columnX
		
		UpdateCursor()
		
		_columnX=x
	End
	
	Protected
	
	Property GutterWidth:Int()
	
		Return _gutterw
	
	Setter( gutterWidth:Int )
	
		_gutterw=gutterWidth
	End
	
	Property ContentMargin:Recti()
	
		Return _contentMargin
	
	Setter( contentMargin:Recti )
	
		_contentMargin=contentMargin
	End
	
	Method OnValidateStyle() Override
	
		_charw=Style.DefaultFont.TextWidth( "X" )
		_charh=Style.DefaultFont.Height
		_tabw=_charw*_tabStop
		
		UpdateCursor()
	End
	
	Method OnMeasure:Vec2i() Override
		Return New Vec2i( 320*_charw+_gutterw,_doc.LineCount*_charh )+_contentMargin.Size
	End

	Method OnRender( canvas:Canvas ) Override
	
		Local firstVisLine:=ClipRect.Top/_charh
		Local lastVisLine:=Min( (ClipRect.Bottom-1)/_charh+1,_doc.LineCount )
		
		If _cursor<>_anchor
		
			Local min:=MakeCursorRect( Min( _anchor,_cursor ) )
			Local max:=MakeCursorRect( Max( _anchor,_cursor ) )
			
			canvas.Color=_selColor
			
			If min.Y=max.Y
				canvas.DrawRect( min.Left,min.Top,max.Left-min.Left,min.Height )
			Else
				canvas.DrawRect( min.Left,min.Top,(ClipRect.Right-min.Left),min.Height )
				canvas.DrawRect( _gutterw,min.Bottom,ClipRect.Right-_gutterw,max.Top-min.Bottom )
				canvas.DrawRect( _gutterw,max.Top,max.Left-_gutterw,max.Height )
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

		_textColors[0]=Style.DefaultColor
		
		For Local line:=firstVisLine Until lastVisLine
		
			_doc.HighlightLine( line )
		
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
							canvas.DrawText( t,x+_gutterw,y )
							x+=Style.DefaultFont.TextWidth( t )
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
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		If _readOnly Return
	
		Select event.Type
		
		Case EventType.KeyDown,EventType.KeyRepeat

			Local control:=event.Modifiers & Modifier.Control
		
			Select event.Key
			
			Case Key.A
			
				If control SelectAll()
				Return
				
			Case Key.X
			
				If control Cut()
				Return
				
			Case Key.C
			
				If control Copy()
				Return
			
			Case Key.V
			
				If control Paste()
				Return
				
			Case Key.Z
			
				If control Undo()
				Return
			
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
					If event.Modifiers & Modifier.Shift
						For Local i:=0 Until lines.Length
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
						Return						
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
			
				If control
					_cursor=0
				Else				
					_cursor=_doc.StartOfLine( Row( _cursor ) )
				Endif
				
				UpdateCursor()
				
			Case Key.KeyEnd
			
				If control
					_cursor=_doc.TextLength
				Else
					_cursor=_doc.EndOfLine( Row( _cursor ) )
				Endif
				
				UpdateCursor()

			Case Key.Up
			
				MoveLine( -1 )
			
			Case Key.Down
			
				MoveLine( 1 )
				
			Case Key.PageUp
			
				Local n:=ClipRect.Height/_charh-1		'shouldn't really use cliprect here...
				
				MoveLine( -n )
				
			Case Key.PageDown
			
				Local n:=ClipRect.Height/_charh-1
				
				MoveLine( n )
				
			Default
			
				Return
			End
			
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
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseDown
			App.KeyView=Self
			_cursor=PointToIndex( event.Location )
			_anchor=_cursor
			_dragging=True
			UpdateCursor()
		Case EventType.MouseUp
			_dragging=False
		Case EventType.MouseMove
			If _dragging
				_cursor=PointToIndex( event.Location )
				UpdateCursor()
			Endif
		Case EventType.MouseWheel
			Super.OnMouseEvent( event )
			Return
		End
		
	End
	
	Method OnMakeKeyView() Override
		Super.OnMakeKeyView()
		UpdateCursor()
	End
	
End
