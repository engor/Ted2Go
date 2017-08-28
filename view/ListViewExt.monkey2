
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
		
		_items=New List<ListViewItem>
		
		'MaxSize=New Vec2i( width,height )
		
		_selColor=App.Theme.GetColor( "content" )
		_hoverColor=App.Theme.GetColor( "knob" )
		
		OnThemeChanged()
	End
	
	Method AddItems( items:Stack<ListViewItem> )
		
		For Local i:=Eachin items
			_items.AddLast( i )
		Next
		_count=_items.Count()
		_visibleCount=Min( _maxLines,_count )
	End
	
	Method AddItem( item:ListViewItem )
	
		_items.AddLast( item )
		_count=_items.Count()
		_visibleCount=Min( _maxLines,_count )
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
		
		Assert( _selIndex >= 0 And _selIndex < _count,"Index out of bounds!" )
		Return Utils.ValueAt<ListViewItem>( _items,_selIndex )
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
		
		If _selIndex = _count-1 Return
		_selIndex=_count-1
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
		If _selIndex >= _count Then _selIndex=_count-1
	
		EnsureVisible()
		RequestRender()
	End
	
	Property Items:List<ListViewItem>.Iterator()
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
	
		If _selIndex >= _count-1
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
		
		Local clip:=VisibleRect
		
		Local firstVisLine:=Max( clip.Top/_lineH,0 )
		Local lastVisLine:=Min( (clip.Bottom-1)/_lineH,_count )
		
		If _selIndex < firstVisLine
			Local d:=(firstVisLine-_selIndex)*_lineH
			Scroll-=New Vec2i( 0,d )
		Elseif _selIndex >= lastVisLine
			Local d:=(lastVisLine-_selIndex)*_lineH
			Scroll-=New Vec2i( 0,d )
		Endif
	End

	Method OnRender( canvas:Canvas ) Override
	
		Local clip:=VisibleRect
		
		'draw mouse hover
'		If Rect.Contains( MouseLocation ) 
'			Local yy:Int=MouseLocation.y/_lineH
'			canvas.Color=_hoverColor
'			canvas.DrawRect( clip.Left,yy*_lineH,clip.Width,_lineH )
'		Endif
		
		Local firstVisLine:=Max( clip.Top/_lineH,0 )
		Local lastVisLine:=Min( (clip.Bottom-1)/_lineH,_count )
		
		Local posY:=_lineH/2,k:=0
		For Local item:=Eachin _items
			If k >= firstVisLine
				If k > lastVisLine Then Return
				'draw selection
				If k = _selIndex
					canvas.Color=_selColor
					canvas.DrawRect( clip.Left,posY-_lineH/2,clip.Width,_lineH )
				End
				'draw item
				canvas.Color=Color.White
				DrawItem( item,canvas,clip.Left+5,posY,0,0.5 )
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
		
		w=Min( w,MaxSize.x )
		_width=w
		
		Return New Vec2i( w,_count*_lineH )
	End
	
	Method OnMeasure:Vec2i() Override
		
		Local h:=Min( _visibleCount*_lineH,MaxSize.y )
		h=(h/_lineH)*_lineH
		
		Return New Vec2i( _width+40,h ) '+40 for icon + scrollbar
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
			
			If index < 0 Or index >= _count Return
			
			_selIndex=index
			OnItemChoosen()
			
		Case EventType.MouseClick
		
			Local index:=(MouseLocation.y+Scroll.y)/_lineH
			
			If index < 0 Or index >= _count Return
			
			_selIndex=index
			OnItemChoosen()
			
		Default
			Return
		End
		
		event.Eat()
	End
	
	Private
	
	Field _items:List<ListViewItem>
	Field _lineH:Int,_lineHeightEtalon:Int
	Field _count:Int,_visibleCount:Int
	Field _maxLines:Int
	Field _selIndex:Int
	Field _selColor:Color,_hoverColor:Color
	Field _width:Int
	Field _moveCyclic:Bool
	
End
