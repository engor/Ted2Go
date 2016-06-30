
Namespace mojox

Class ScrollBar Extends View

	Field ValueChanged:Void( value:Int )

	Method New( axis:Axis=std.geom.Axis.X )

		_axis=axis

		Layout="fill"
		
		Local taxis:=_axis=Axis.X ? "x" Else "y"
		
		Style=Style.GetStyle( "mojo.ScrollBar:"+taxis )

		_knobStyle=Style.GetStyle( "mojo.ScrollKnob:"+taxis )
	End
	
	Property Axis:Axis()
	
		Return _axis
		
	Setter( axis:Axis )
	
		_axis=axis
	End
	
	Property PageSize:Int()
	
		Return _pageSize
		
	Setter( pageSize:Int )
	
		_pageSize=pageSize
	End
	
	Property Value:Int()
	
		Return _value
		
	Setter( value:Int )
	
		_value=value
		_value=Clamp( _value,_minimum,_maximum )
	End
	
	Property Minimum:Int()
	
		Return _minimum
		
	Setter( minimum:Int )
	
		_minimum=minimum
		_value=Max( _value,_minimum )
	End
	
	Property Maximum:Int()
	
		Return _maximum
		
	Setter( maximum:Int )
	
		_maximum=maximum
		_value=Min( _value,_maximum )
	End
	
	Protected
	
	Field _axis:Axis
	Field _value:Int
	Field _minimum:Int
	Field _maximum:Int
	Field _pageSize:Int=1
	
	Field _knobStyle:Style
	Field _knobRect:Recti
	
	Field _drag:Bool
	Field _hover:Bool
	
	Field _offset:Int
	
	Method OnMeasure:Vec2i() Override
	
		Return _knobStyle.Bounds.Size
	End
	
	Method OnLayout() Override
	
		Local range:=_maximum-_minimum+_pageSize
		
		Select _axis
		Case Axis.X
		
			Local sz:=range ? Max( _pageSize*Width/range,16 ) Else Width
			Local pos:=_maximum>_minimum ? (_value-_minimum)*(Width-sz)/(_maximum-_minimum) Else 0
			
			_knobRect=New Recti( pos,0,pos+sz,Height )
		
'			Local min:=(_value-_minimum)*Width/range
'			Local max:=(_value-_minimum+_pageSize)*Width/range
			
'			_knobRect=New Recti( min,0,max,16 )
			
		Case Axis.Y
		
			Local sz:=range ? Max( _pageSize*Height/range,16 ) Else Height
			Local pos:=_maximum>_minimum ? (_value-_minimum)*(Height-sz)/(_maximum-_minimum) Else 0
			
			_knobRect=New Recti( 0,pos,Width,pos+sz )
			
'			Local min:=(_value-_minimum)*Height/range
'			Local max:=(_value-_minimum+_pageSize)*Height/range
			
'			_knobRect=New Recti( 0,min,16,max )
		End
		
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		If _maximum=_minimum Return
		
		Local style:=_knobStyle
		
		If _drag style=style.GetState( "active" ) Else If _hover style=style.GetState( "hover" )

		style.Render( canvas,_knobRect )
	End

	Method OnMouseEvent( event:MouseEvent ) Override
	
		Local p:=event.Location
		
		Local value:=_value
		
		Local range:=_maximum-_minimum+_pageSize
	
		Select event.Type
		Case EventType.MouseDown
			If _knobRect.Contains( p )
				Select _axis
				Case Axis.X
					_offset=p.x*range/Rect.Width-_value
				Case Axis.Y
					_offset=p.y*range/Rect.Height-_value
				End
				_drag=True
			Else If _axis=Axis.X
				If p.x<_knobRect.Left 
					_value-=_pageSize
				Else If p.x>=_knobRect.Right
					_value+=_pageSize
				Endif
			Else If _axis=Axis.Y
				If p.y<_knobRect.Top
					_value-=_pageSize
				Else If p.y>=_knobRect.Bottom
					_value+=_pageSize
				Endif
			Endif
		Case EventType.MouseMove
			If _drag
				Local range:=_maximum-_minimum+_pageSize
				Select _axis
				Case Axis.X
					_value=p.x*range/Rect.Width-_offset
				Case Axis.Y
					_value=p.y*range/Rect.Height-_offset
				End
			Else If _knobRect.Contains( p )
				_hover=True
			Else
				_hover=False
			Endif
		Case EventType.MouseUp
			_drag=False
		Case EventType.MouseLeave
			_hover=False
		End
		
		_value=Clamp( _value,_minimum,_maximum )
		
		If _value<>value
			ValueChanged( _value )
		Endif

	End

End
