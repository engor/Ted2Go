
Namespace ted2go


Class ListViewItem
	
	Property Text:String()
		Return _text
	Setter( value:String )
		_text=value
	End

	Property Icon:Image()
		Return _icon
	Setter( value:Image )
		_icon=value
	End
	
	Method New( text:String,icon:Image=Null )
		_text=text
		_icon=icon
	End
	
	Method Draw( canvas:Canvas,x:Float,y:Float,handleX:Float=0,handleY:Float=0 ) Virtual
		Local dx:=0.0
		If _icon <> Null
			canvas.DrawImage( _icon,x-_icon.Width*handleX,y-_icon.Height*handleY )
			dx=_icon.Width+8
		Endif
		canvas.Color=App.Theme.DefaultStyle.TextColor
		canvas.DrawText( _text,x+dx,y,handleX,handleY )
	End

	
	Private
	
	Field _text:String
	Field _icon:Image
	
End


Class ListViewExt Extends ScrollableView

	Field OnItemChoosen:Void()
	
	Method New()
		Self.New( 20,50 )
	End
	
	Method New( lineHeight:Int,maxLines:Int )
		
		_lineHeightEtalon=lineHeight
		_maxLines=maxLines
		
		_selColor=App.Theme.GetColor( "content" )
		_hoverColor=App.Theme.GetColor( "knob" )
		
		OnThemeChanged()
	End
	
	Method AddItems( items:Stack<ListViewItem> )
		
		_items.AddAll( items )
		
		_visibleCount=Min( _maxLines,_items.Length )
	End
	
	Method AddItem( item:ListViewItem )
	
		_items.Add( item )
		
		_visibleCount=Min( _maxLines,_items.Length )
	End
	
	Method SetItems<T>( items:Stack<T> ) Where T Extends ListViewItem
		
		_items.Clear()
		AddItems( items )
	End
	
	Method SetItems<T>( items:T[] ) Where T Extends ListViewItem
	
		_items.Clear()
		AddItems( items )
	End
	
	Method Reset()
		
		_selIndex=0
		Scroll=New Vec2i
	End
	
	Method Clear()
	
		Reset()
		_items.Clear()
	End
	
	Property LineHeight:Float()
		Return _lineH
	End
	
	Property MaxLines:Int()
		Return _maxLines
	Setter( value:Int )
		_maxLines=value
	End
	
	Property CurrentItem:ListViewItem()
		
		Assert( _selIndex >= 0 And _selIndex < _items.Length,"Index out of bounds!" )
		Return _items[_selIndex]
	End
	
	Property MoveCyclic:Bool()
		Return _moveCyclic
	Setter( value:Bool )
		_moveCyclic=value
	End
	
	Method SelectPrev()
		SelectPrevInternal( True )
	End
	
	Method SelectNext()
		SelectNextInternal( True )
	End
	
	Method SelectFirst()
		
		If _selIndex = 0 Return
		_selIndex=0
		EnsureVisible()
		RequestRender()
	End
	
	Method SelectLast()
		
		If _selIndex = _items.Length-1 Return
		_selIndex=_items.Length-1
		EnsureVisible()
		RequestRender()
	End
	
	Method PageUp()
	
		_selIndex-=_visibleCount
		If _selIndex < 0 Then _selIndex=0
		
		EnsureVisible()
		RequestRender()
	End
	
	Method PageDown()
	
		_selIndex+=_visibleCount
		If _selIndex >= _items.Length Then _selIndex=_items.Length-1
	
		EnsureVisible()
		RequestRender()
	End
	
	Property Items:Stack<ListViewItem>.Iterator()
		Return _items.All()
	End
	
	Method DrawItem( item:ListViewItem,canvas:Canvas,x:Float,y:Float,handleX:Float=0,handleY:Float=0 ) Virtual
	
		item.Draw( canvas,x,y,handleX,handleY )
	End
	
	
	Protected
	
	Method OnThemeChanged() Override
	
		_lineH=_lineHeightEtalon*App.Theme.Scale.y
	End
	
	Method SelectPrevInternal( ensureVis:Bool )
	
		If _selIndex = 0
			If MoveCyclic Then SelectLast()
			Return
		Endif
		_selIndex-=1
		If ensureVis
			EnsureVisible()
			RequestRender()
		Endif
	End
	
	Method SelectNextInternal( ensureVis:Bool )
	
		If _selIndex >= _items.Length-1
			If MoveCyclic Then SelectFirst()
			Return
		Endif
		
		_selIndex+=1
		If ensureVis
			EnsureVisible()
			RequestRender()
		Endif
	End
	
	Method EnsureVisible()
		
		Local clip:=ClipRect+Scroll
		
		Local firstVisLine:=Max( clip.Top/_lineH,0 )
		Local lastVisLine:=Min( (clip.Bottom-1)/_lineH,_items.Length )
		
		If _selIndex < firstVisLine
			Local d:=(firstVisLine-_selIndex)*_lineH
			Scroll-=New Vec2i( 0,d )
		Elseif _selIndex >= lastVisLine
			Local d:=(lastVisLine-_selIndex)*_lineH - _dh
			Scroll-=New Vec2i( 0,d )
		Endif
		
	End

	Method OnRender( canvas:Canvas ) Override
	
		Local clip:=ClipRect+Scroll
		
		Local firstVisLine:=Max( clip.Top/_lineH,0 )
		Local lastVisLine:=Min( (clip.Bottom-1)/_lineH,_items.Length )
		
		Local posY:=_lineH/2,k:=0
		Local left:=clip.Left-Scroll.x*2
		For Local item:=Eachin _items
			If k >= firstVisLine
				If k > lastVisLine Then Return
				'draw selection
				If k = _selIndex
					canvas.Color=_selColor
					canvas.DrawRect( left,posY-_lineH/2,_width,_lineH )
				End
				'draw item
				canvas.Color=Color.White
				DrawItem( item,canvas,left+5,posY,0,0.5 )
				posY+=_lineH
			Endif
			k+=1
		Next
			
	End
	
	Method OnMeasureContent:Vec2i() Override
		
		Local w:=0
		For Local i:=Eachin _items
			w=Max( w,Int(RenderStyle.Font.TextWidth( i.Text )) )
		Next
		w+=50 '+20 for icons
		_width=w
		
		Local h:=_items.Length*_lineH
		
		_dh=0
		Local maxH:=Min( _visibleCount*_lineH,MaxSize.y )
		If h>maxH 'has scroll
			_dh=20*App.Theme.Scale.y '+20 for scrollbar
			h+=_dh
		Endif
		
		_height=h
		
		Return New Vec2i( w,h )
	End
	
	Method OnMeasure:Vec2i() Override
		
		Local maxH:=Min( _visibleCount*_lineH,MaxSize.y )
		
		Local sx:=(_width > MaxSize.x)
		Local sy:=(_height > maxH)
		Local w:=Min( _width,MaxSize.x )
		Local h:=_height
		If sy
			h=(maxH/_lineH)*_lineH
		Endif
		If sx Then h+=_lineH
		
		Return New Vec2i( w,h )
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseWheel
			
			Local dy:=event.Wheel.Y
			Scroll-=New Vec2i( 0,_lineH*dy*3 )
			
		Case EventType.MouseMove
			
			'If VisibleRect.Contains(MouseLocation) Then RequestRender()
		
		Case EventType.MouseDoubleClick
		
			Local index:=(MouseLocation.y+Scroll.y)/_lineH
			
			If index < 0 Or index >= _items.Length Return
			
			_selIndex=index
			OnItemChoosen()
			
		Case EventType.MouseClick
		
			Local index:=(MouseLocation.y+Scroll.y)/_lineH
			
			If index < 0 Or index >= _items.Length Return
			
			_selIndex=index
			OnItemChoosen()
			
		Default
			Return
		End
		
		event.Eat()
	End
	
	Private
	
	Field _items:=New Stack<ListViewItem>
	Field _lineH:Int,_lineHeightEtalon:Int
	Field _visibleCount:Int
	Field _maxLines:Int
	Field _selIndex:Int
	Field _selColor:Color,_hoverColor:Color
	Field _width:Int,_height:Int
	Field _moveCyclic:Bool
	Field _dh:Float
	
End
