
Namespace mojox

Class DragKnob Extends View

	Field Dragged:Void( v:Vec2i )

	Method New()
		Layout="fill"
		Style=Style.GetStyle( "mojo.DragKnob" )
	End
	
	Private
	
	Field _org:Vec2i
	
	Field _drag:Bool
	Field _hover:Bool
	
	Method OnMeasure:Vec2i() Override
	
		Return New Vec2i( 0,0 )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseDown
			_drag=True
			_org=event.Location
		Case EventType.MouseUp
			_drag=False
		Case EventType.MouseEnter
			_hover=True
		Case EventType.MouseLeave
			_hover=False
		Case EventType.MouseMove
			If _drag Dragged( event.Location-_org )
		End
		
		If _drag
			StyleState="active"
		Else If _hover
			StyleState="hover"
		Else
			StyleState=""
		Endif
		
	End
	
End

Class DockView Extends View

	Method New( view:View,location:String,size:Int,resizable:Bool )
		_view=view
		_location=location
		_size=size
		_resizable=resizable
		
		Layout="fill"
		Style=Style.GetStyle( "mojo.DockView" )
		
		AddChild( _view.Container )

		If _size And _resizable
			_knob=New DragKnob
			_knob.Dragged=Lambda( v:Vec2i )
				Select _location
				Case "top"
					_size+=v.y
				Case "bottom"
					_size-=v.y
				Case "left"
					_size+=v.x
				Case "right"
					_size-=v.x
				End
				_size=Max( _size,0 )
			End
			AddChild( _knob )
		Endif
	End
	
	Property View:View()
	
		Return _view
		
	Setter( view:View )
	
		If _view RemoveChild( _view.Container )
		
		_view=view
		
		If _view AddChild( _view.Container )
	End
	
	Property Location:String()
	
		Return _location
	End
	
	Property Size:Int()
	
		Return _size
		
	Setter( size:Int )
	
		_size=size
	End
	
	Private
	
	Field _view:View
	Field _knob:DragKnob
	Field _location:String
	Field _size:Int
	Field _resizable:Bool
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=_view.Container.LayoutSize
		
		If _knob
			Local w:=_knob.LayoutSize.x
			Local h:=_knob.LayoutSize.y
			Select _location
			Case "top","bottom"
				size.y=_size+h
			Case "left","right"
				size.x=_size+w
			End
		Else If _size
			Select _location
			Case "top","bottom"
				size.y=_size
			Case "left","right"
				size.x=_size
			End
		Endif
		
		Return size
	End
	
	Method OnLayout:Void() Override
	
		Local rect:=Rect
		
		If _knob
			Local w:=_knob.LayoutSize.x
			Local h:=_knob.LayoutSize.y
			Select _location
			Case "top"
				_knob.Frame=New Recti( 0,Height-h,Width,Height )
				rect.Bottom-=h
			Case "bottom"
				_knob.Frame=New Recti( 0,0,Width,h )
				rect.Top+=h
			Case "left"
				_knob.Frame=New Recti( Width-w,0,Width,Height )
				rect.Right-=w
			Case "right"
				_knob.Frame=New Recti( 0,0,w,Height )
				rect.Left+=w
			End
		Endif
		
		_view.Container.Frame=rect
	End

End

Class DockingView Extends View

	Method New()
		Layout="fill"
	End
	
	Property ContentView:View()

		Return _content
			
	Setter( contentView:View )
	
		If _content RemoveChild( _content.Container )
		
		_content=contentView
		
		If _content AddChild( _content.Container )
	End
	
	Method AddView( view:View,location:String,size:Int=0,resizable:Bool=True )
	
		Local dock:=New DockView( view,location,size,resizable )

		_docks.Add( dock )
		
		AddChild( dock )
	End
	
	Method RemoveView( view:View )
	
		Local dock:=FindView( view )
		If Not dock Return
		
		dock.View=Null
		
		RemoveChild( dock )
		
		_docks.Remove( dock )
	End
	
	Method GetViewSize:Int( view:View )
	
		Return FindView( view ).Size
	End
	
	Method SetViewSize( view:View,size:Int )
	
		FindView( view ).Size=size
	End
	
	Method ClearViews()
	
		For Local dock:=Eachin _docks
		
			dock.View=Null
			
			RemoveChild( dock )
		Next
		
		_docks.Clear()
	End
	
	Method OnMeasure:Vec2i() Override

		Local size:=New Vec2i
		
		If _content size=_content.Container.LayoutSize
	
		For Local dock:=Eachin _docks

			'FIXME - silly place to do this...		
			dock.Visible=dock.View.Visible
			If Not dock.Visible Continue
	
			Select dock.Location
			Case "top","bottom"
				size.x=Max( size.x,dock.LayoutSize.x )
				size.y+=dock.LayoutSize.y
			Case "left","right"
				size.x+=dock.LayoutSize.x
				size.y=Max( size.y,dock.LayoutSize.y )
			End

		Next
		
		Return size

	End
	
	Method OnLayout() Override
	
		Local rect:=Rect
		
		For Local dock:=Eachin _docks

			If Not dock.Visible Continue
		
			Local size:=dock.LayoutSize
		
			Select dock.Location
			Case "top"

				Local top:=rect.Top+size.y
				If top>rect.Bottom top=rect.Bottom
				dock.Frame=New Recti( rect.Left,rect.Top,rect.Right,top )
				rect.Top=top
				
'				dock.Frame=New Recti( rect.Left,rect.Top,rect.Right,rect.Top+size.y )
'				rect.Top+=size.y
			Case "bottom"
			
				Local bottom:=rect.Bottom-size.y
				If bottom<rect.Top bottom=rect.Top
				dock.Frame=New Recti( rect.Left,bottom,rect.Right,rect.Bottom )
				rect.Bottom=bottom
				
'				dock.Frame=New Recti( rect.Left,rect.Bottom-size.y,rect.Right,rect.Bottom )
'				rect.Bottom-=size.y
			Case "left"
			
				Local left:=rect.Left+size.x
				If left>rect.Right left=rect.Right
				dock.Frame=New Recti( rect.Left,rect.Top,left,rect.Bottom )
				rect.Left=left
				
'				dock.Frame=New Recti( rect.Left,rect.Top,rect.Left+size.x,rect.Bottom )
'				rect.Left+=size.x
			Case "right"
				Local right:=rect.Right-size.x
				If right<rect.Left right=rect.Left
				dock.Frame=New Recti( right,rect.Top,rect.Right,rect.Bottom )
				rect.Right=right
				
'				dock.Frame=New Recti( rect.Right-size.x,rect.Top,rect.Right,rect.Bottom )
'				rect.Right-=size.x
			End

		Next
		
		If _content _content.Container.Frame=rect
	End
	
	Private
	
	Field _content:View
	Field _docks:=New Stack<DockView>
	
	Method FindView:DockView( view:View )
	
		For Local dock:=Eachin _docks
			If dock.View=view Return dock
		Next
		
		Return Null
	End

End
