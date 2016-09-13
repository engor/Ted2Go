
Namespace ted2go


Interface ListViewItem
	
	Property Text:String()
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
	
End


Class StringListViewItem Implements ListViewItem
	
	Property Text:String()
		Return _text
	End
	
	Method New(text:String)
		_text = text
	End
	
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
		canvas.DrawText(_text,x,y,handleX,handleY)
	End
	
	Private
	
	Field _text:String
	
End


Class ListView Extends ScrollableView

	Field OnItemChoosen:Void()
	
	Method New(lineHeight:Int, width:Int=300, maxHeight:Int=480)
		_items = New List<ListViewItem>
		_lineH = lineHeight
		_selColor = New Color(0.2,0.4,0.6)
		_hoverColor = New Color(0.4,0.4,0.4,0.5)
		_width = width
		_maxHeight = maxHeight
	End
	
	Method AddItems(items:List<ListViewItem>)
		For Local i := Eachin items
			_items.AddLast(i)
		Next
		_count = _items.Count()
	End
	
	Method SetItems(items:List<ListViewItem>)
		_items.Clear()
		AddItems(items)
	End
	
	Method Reset()
		_selIndex = 0
	End
	
	Property CurrentItem:ListViewItem()
		Assert(_selIndex >= 0 And _selIndex < _count, "Index out of bounds!")
		Return Utils.ValueAt<ListViewItem>(_items,_selIndex)
	End
	
	Method SelectPrev()
		SelectPrevInternal(True)
	End
	
	Method SelectNext()
		SelectNextInternal(True)
	End
	
	Method SelectFirst()
		If _selIndex = 0 Return
		_selIndex = 0
		EnsureVisible()
		RequestRender()
	End
	
	Method SelectLast()
		If _selIndex = _count-1 Return
		_selIndex = _count-1
		EnsureVisible()
		RequestRender()
	End
	
	
	Protected
	
	Method New()
	End
	
	Method SelectPrevInternal(ensureVis:Bool)
		If _selIndex = 0 Return
		_selIndex -= 1
		If ensureVis
			EnsureVisible()
			RequestRender()
		Endif
	End
	
	Method SelectNextInternal(ensureVis:Bool)
		If _selIndex >= _count-1 Return
		_selIndex += 1
		If ensureVis
			EnsureVisible()
			RequestRender()
		Endif
	End
	
	Method EnsureVisible()
		Local clip := VisibleRect
			
		Local firstVisLine := Max( clip.Top/_lineH,0 )
		Local lastVisLine := Min( (clip.Bottom-1)/_lineH,_count )
		
		If _selIndex < firstVisLine
			Local d := (firstVisLine-_selIndex)*_lineH
			Scroll -= New Vec2i(0,d)
		Elseif _selIndex >= lastVisLine
			Local d := (lastVisLine-_selIndex)*_lineH
			Scroll -= New Vec2i(0,d)
		Endif
	End

	Method OnRender(canvas:Canvas) Override
	
		Local clip := VisibleRect
		
		'draw mouse hover
		If Rect.Contains(MouseLocation) 
			Local yy:Int = MouseLocation.y/_lineH
			canvas.Color = _hoverColor
			canvas.DrawRect(clip.Left, yy*_lineH, clip.Width, _lineH)
		Endif
		
		Local firstVisLine := Max( clip.Top/_lineH,0 )
		Local lastVisLine := Min( (clip.Bottom-1)/_lineH,_count )
				
		Local posY := _lineH/2, k := 0
		For Local item := Eachin _items
			If k >= firstVisLine
				If k > lastVisLine Then Return
				'draw selection
				If k = _selIndex
					canvas.Color = _selColor
					canvas.DrawRect(clip.Left, posY-_lineH/2, clip.Width, _lineH)
				End
				'draw item
				canvas.Color = Color.White
				item.Draw(canvas, clip.Left+5, posY, 0, 0.5)
				posY += _lineH
			Endif
			k += 1
		Next
			
	End
	
	Method OnMeasureContent:Vec2i() Override
		Return New Vec2i( _width-20,_count*_lineH )
	End
	
	Method OnMeasure:Vec2i() Override
		Local h := Min(_count*_lineH,_maxHeight)
		h = (h/_lineH)*_lineH
		Return New Vec2i( _width,h )
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseWheel
			
			Local dy := event.Wheel.Y
			Scroll -= New Vec2i( 0,_lineH*dy*3 )
			
		Case EventType.MouseMove
			
			'If VisibleRect.Contains(MouseLocation) Then RequestRender()
		
		Case EventType.MouseDoubleClick
		
			Local index := (MouseLocation.y+Scroll.y)/_lineH
			
			_selIndex = index
			OnItemChoosen()
			
		Default
			Return
		End
		
		event.Eat()
	End
	
	Private
	
	Field _items:List<ListViewItem>
	Field _lineH:Int
	Field _count:Int
	Field _selIndex:Int
	Field _selColor:Color, _hoverColor:Color
	Field _maxHeight:Int, _width:Int
	
End
