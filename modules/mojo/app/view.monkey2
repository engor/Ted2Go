
Namespace mojo.app

Class View

	Method New()
	
		_style=New Style
	End

	#rem monkeydoc View visible flag.
	
	Use [[ReallyVisible]] to test if the view is really visible.
	
	#end
	Property Visible:Bool()
	
		Return _visible
	
	Setter( visible:Bool )
		If visible=_visible Return
	
		_visible=visible
	End

	#rem monkeydoc View visibility state.
	
	True if the view's visibility flag is set AND all its parent visibility flags up to the root window are also set.
	
	#end
	Property ReallyVisible:Bool()
	
		Return _visible And (Not _parent Or _parent.ReallyVisible)
	End
	
	#rem monkeydoc View enabled flag.
	
	Use [[ReallyEnabled]] to test if the view is really enabled.
	
	#end
	Property Enabled:Bool()
	
		Return _enabled
	
	Setter( enabled:Bool )
		If enabled=_enabled Return
	
		_enabled=enabled
		
		InvalidateStyle()
	End

	#rem monkeydoc View enabled state.
	
	True if the view's enabled flag is set AND all its parent enabled flags are set AND [[ReallyVisible]] is also true. 
	
	#end
	Property ReallyEnabled:Bool()
	
		Return _enabled And _visible And (Not _parent Or _parent.ReallyEnabled)
	End
	
	#rem monkeydoc View style.
	#end
	Property Style:Style()
	
		Return _style
		
	Setter( style:Style )
		If style=_style Return
	
		_style=style
		
		InvalidateStyle()
	End
	
	#rem monkeydoc @hidden
	#end
	Property StyleState:String()
	
		Return _styleState
	
	Setter( styleState:String )
		If styleState=_styleState Return

		_styleState=styleState
		
		InvalidateStyle()
	End
	
	#rem monkeydoc @hidden
	#end
	Property RenderStyle:Style()
	
		ValidateStyle()
		
		Return _rstyle
	End
	
	#rem monkeydoc Layout mode.
	
	The following layout modes are supported
	
	| Layout mode		| Description
	|:------------------|:-----------
	| "resize"			| View is resized to fit its layout frame.
	| "stretch"			| View is stretched to fit its layout frame.
	| "letterbox"		| View is uniformly stretched on both axii and centered within its layout frame.
	| "float"			| View floats within its layout frame according to the view [[Gravity]].
	
	#end
	Property Layout:String()

		Return _layout

	Setter( layout:String )
		If layout=_layout Return

		_layout=layout
	End

	#rem monkeydoc View frame rect.
	
	The 'frame' the view is contained in.
	
	Note that the frame rect is in 'parent space' coordinates, and is usually set by the parent view when layout occurs.
	
	#end	
	Property Frame:Recti()
	
		Return _frame
	
	Setter( frame:Recti )
		If frame=_frame Return
	
		_frame=frame
	End
	
	#rem monkeydoc Gravity for floating views.
	
	#end
	Property Gravity:Vec2f()

		Return _gravity

	Setter( gravity:Vec2f )
		If gravity=_gravity Return

		_gravity=gravity
	End

	#rem monkeydoc @hidden
	#end	
	Property Offset:Vec2i()
	
		Return _offset
		
	Setter( offset:Vec2i )
		If offset=_offset Return
			
		_offset=offset
	End
	
	#rem monkeydoc Minimum view size.
	#end
	Property MinSize:Vec2i()
	
		Return _minSize
	
	Setter( minSize:Vec2i )
	
		_minSize=minSize
		
		InvalidateStyle()
	End
	
	#rem monkeydoc Maximum view size.
	#end
	Property MaxSize:Vec2i()
	
		Return _maxSize
	
	Setter( maxSize:Vec2i )
	
		_maxSize=maxSize
		
		InvalidateStyle()
	End
	
	#rem monkeydoc View content rect.
	
	The content rect represents the rendering area of the view.
	
	The content rect is in view local coordinates and its origin is always (0,0).
	
	#end
	Property Rect:Recti()
	
		Return _rect
	End
	
	#rem monkeydoc Width of the view content rect.
	#end
	Property Width:Int()

		Return _rect.Width
	End
	
	#rem monkeydoc Height of the view content rect.
	#end
	Property Height:Int()
	
		Return _rect.Height
	End
	
	#rem monkeydoc @hidden
	#end
	Property Bounds:Recti()
	
		Return _bounds
	End
	
	#rem monkeydoc Mouse location relative to the view.
	#end
	Property MouseLocation:Vec2i()

		Return TransformPointFromView( App.MouseLocation,Null )
	End
	
	#rem monkeydoc View clip rect.
	
	The clip rect represents the part of the content rect NOT obscured by an parent views.
	
	The clip rect is in view local coordinates.
	
	#end
	Property ClipRect:Recti()
	
		Return _clip
	End
	
	#rem monkeydoc @hidden
	#end
	Property RenderRect:Recti()
	
		Return _rclip
	End
	
	#rem monkeydoc @hidden
	#end
	Property RenderBounds:Recti()
	
		Return _rbounds
	End
	
	#rem monkeydoc @hidden
	#end
	Property LocalMatrix:AffineMat3f()
	
		Return _matrix
	End
	
	#rem monkeydoc @hidden
	#end
	Property RenderMatrix:AffineMat3f()
	
		Return _rmatrix
	End
	
	#rem monkeydoc @hidden
	#end
	Property Parent:View()
	
		Return _parent
	End
	
	#rem monkeydoc @hidden
	#end
	Method AddChild( view:View )
	
		If Not view Return
		
		Assert( Not view._parent )
		
		_children.Add( view )
		
		view._parent=Self
	End
	
	#rem monkeydoc @hidden
	#end
	Method RemoveChild( view:View )
	
		If Not view Return
		
		Assert( view._parent=Self )
		
		_children.Remove( view )
		
		view._parent=Null
	End
	
	#rem monkeydoc @hidden
	#end
	Method FindViewAtWindowPoint:View( point:Vec2i )
	
		If Not _visible Return Null
	
		If Not _rbounds.Contains( point ) Return Null
		
		For Local i:=0 Until _children.Length
		
			Local child:=_children[_children.Length-i-1]

			Local view:=child.FindViewAtWindowPoint( point )
			If view Return view
		
		Next
		
		Return Self
	End
	
	#rem monkeydoc Transforms a point to another view.
	
	Transforms `point` in coordinates local to this view to coordinates local to `view`.
	
	@param point The point to transform.
	
	@param view View to transform point to.
	
	#end
	Method TransformPointToView:Vec2i( point:Vec2i,view:View )
	
		Local t:=_rmatrix * New Vec2f( point.x,point.y )
		
		If view t=-view._rmatrix * t
		
		Return New Vec2i( Round( t.x ),Round( t.y ) )
	End
	
	#rem monkeydoc Transforms a point from another view.
	
	Transforms `point` in coordinates local to 'view' to coodinates local to this view.
	
	@param point The point to transform.
	
	@param view View to transform point from.
	
	#end
	Method TransformPointFromView:Vec2i( point:Vec2i,view:View )
	
		Local t:=New Vec2f( point.x,point.y )
		
		If view t=view._matrix * t
		
		t=-_rmatrix * t
		
		Return New Vec2i( Round( t.x ),Round( t.y ) )
	End
	
	#rem monkeydoc Transforms a rect to another view.
	
	Transforms `rect` from coordinates local to this view to coordinates local to `view`.
	
	@param rect The rect to transform.

	@param view View to transform rect to.
	
	#end
	Method TransformRectToView:Recti( rect:Recti,view:View )
	
		Return New Recti( TransformPointToView( rect.min,view ),TransformPointToView( rect.max,view ) )
	End
	
	#rem monkeydoc Transforms a rect from another view.
	
	Transform `rect` from coordinates local to `view` to coordinates local to this view.
	
	@param rect The rect to transform.
	
	@param view The view to transform rect from.
	
	#end
	Method TransformRectFromView:Recti( rect:Recti,view:View )
	
		Return New Recti( TransformPointFromView( rect.min,view ),TransformPointFromView( rect.max,view ) )
	End
	
	#rem monkeydoc @hidden
	#end
	Method TransformWindowPointToView:Vec2i( point:Vec2i )
	
		Local t:=-_rmatrix * New Vec2f( point.x,point.y )
		
		Return New Vec2i( Round( t.x ),Round( t.y ) )
	End
	
	
	#rem monkeydoc Makes this view the 'key' view.
	
	The key view is the view that receives keyboard events.
	
	#end
	Method MakeKeyView()
	
		If Not ReallyEnabled Return
	
		OnMakeKeyView()
	End
	
	#rem monkeydoc @hidden
	#end
	Method SendMouseEvent( event:MouseEvent )
	
		If Not ReallyEnabled
			Select event.Type
			Case EventType.MouseUp,EventType.MouseLeave
				OnMouseEvent( event )
			End
			Return
		Endif
	
		OnMouseEvent( event )
		
		If event.Eaten Return
	
		Select event.Type
		Case EventType.MouseWheel
			Local view:=_parent
			While view
				view.OnMouseEvent( event )
				If event.Eaten Return
				view=view._parent
			Wend
		End
		
	End
	
	#rem monkeydoc @hidden
	#end
	Method SendKeyEvent( event:KeyEvent )
	
		If Not ReallyEnabled Return
	
		OnKeyEvent( event )
	End
	
	#rem monkeydoc @hidden
	#end
	Property Container:View() Virtual
	
		Return Self
	End
	
	#rem monkeydoc @hidden
	#end
	Method FindWindow:Window() Virtual
	
		If _parent Return _parent.FindWindow()
		
		Return Null
	End
	
	#rem monkeydoc @hidden
	#end
	Method IsChildOf:Bool( view:View )
		
		If view=Self Return True
		
		If _parent Return _parent.IsChildOf( view )
		
		Return False
	End
	
	#rem monkeydoc @hidden
	#end
	Method InvalidateStyle()
	
		_dirty|=Dirty.Style
	End
	
	#rem monkeydoc @hidden
	#end
	Method ValidateStyle()
	
		If Not (_dirty & Dirty.Style) Return
		
		_rstyle=_style
		
		If Not ReallyEnabled 
			_rstyle=_style.GetState( "disabled" )
		Else If _styleState
			_rstyle=_style.GetState( _styleState )
		Endif
		
		_styleBounds=_rstyle.Bounds

		_dirty&=~Dirty.Style
				
		OnValidateStyle()
	End
	
	Protected
	
	#rem monkeydoc @hidden
	#end
	Method Measure()
	
		If Not _visible Return
		
		For Local view:=Eachin _children
		
			view.Measure()

		Next
		
		ValidateStyle()
		
		Local size:=OnMeasure()
		
		If _minSize.x size.x=Max( size.x,_minSize.x )
		If _minSize.y size.y=Max( size.y,_minSize.y )
		If _maxSize.x size.x=Min( size.x,_maxSize.x )
		If _maxSize.y size.y=Min( size.y,_maxSize.y )
		
		_measuredSize=size
		
		_layoutSize=size+_styleBounds.Size
	End
	
	#rem monkeydoc @hidden
	#end
	Method UpdateLayout()
	
		_rect=New Recti( 0,0,_measuredSize )
		
		_bounds=_rect+_styleBounds
		
		_matrix=New AffineMat3f
		
		If _parent _matrix=_matrix.Translate( _frame.min.x,_frame.min.y )
		
		_matrix=_matrix.Translate( _offset.x,_offset.y )
		
		Select _layout
		Case "fill","resize"
		
			_rect=New Recti( 0,0,_frame.Size-_styleBounds.Size )

			_bounds=_rect+_styleBounds
			
		Case "fill-x"
		
			_rect.max.x=_frame.Width-_styleBounds.Width
			
			_bounds.min.x=_rect.min.x+_styleBounds.min.x
			_bounds.max.x=_rect.max.x+_styleBounds.max.x
			
			_matrix=_matrix.Translate( 0,(_frame.Height-_bounds.Height)*_gravity.y )
			
		Case "float"
		
			_matrix=_matrix.Translate( (_frame.Width-_bounds.Width)*_gravity.x,(_frame.Height-_bounds.Height)*_gravity.y )
			
			_matrix.t.x=Round( _matrix.t.x )
			_matrix.t.y=Round( _matrix.t.y )
			
		Case "stretch"
		
			Local sx:=Float(_frame.Width)/_bounds.Width
			Local sy:=Float(_frame.Height)/_bounds.Height
			_matrix=_matrix.Scale( sx,sy )

		Case "stretch-int"
		
			Local sx:=Float(_frame.Width)/_bounds.Width
			Local sy:=Float(_frame.Height)/_bounds.Height

			If sx>1 sx=Floor( sx )
			If sy>1 sy=Floor( sy )
			
			_matrix=_matrix.Scale( sx,sy )
			
		Case "scale","letterbox"
		
			Local sx:=Float(_frame.Width)/_bounds.Width
			Local sy:=Float(_frame.Height)/_bounds.Height
			
			If sx<sy
				_matrix=_matrix.Translate( 0,(_frame.Height-_bounds.Height*sx)*_gravity.y )
				_matrix=_matrix.Scale( sx,sx )
			Else
				_matrix=_matrix.Translate( (_frame.Width-_bounds.Width*sy)*_gravity.x,0 )
				_matrix=_matrix.Scale( sy,sy )
			Endif
			
		Case "scale-int","letterbox-int"
		
			Local sx:=Float(_frame.Width)/_bounds.Width
			Local sy:=Float(_frame.Height)/_bounds.Height
			
			If sx>1 sx=Floor( sx )
			If sy>1 sy=Floor( sy )
			
			Local sc:=Min( sx,sy )
			_matrix=_matrix.Translate( (_frame.Width-_bounds.Width*sc)*_gravity.x,(_frame.Height-_bounds.Height*sc)*_gravity.y )
			_matrix=_matrix.Scale( sc,sc )
			
		End

		_matrix=_matrix.Translate( -_bounds.min.x,-_bounds.min.y )
		
		If _parent _rmatrix=_parent._rmatrix * _matrix Else _rmatrix=_matrix
		
'		_rmatrix.t.x=Round( _rmatrix.t.x )
'		_rmatrix.t.y=Round( _rmatrix.t.y )
		
		_rclip=TransformRecti( _rect,_rmatrix )
		_rbounds=TransformRecti( _bounds,_rmatrix )
		
		If _parent
			_rclip&=_parent._rclip
			_rbounds&=_parent._rclip
			_clip=TransformRecti( _rclip,-_rmatrix )
		Else
			_clip=_rclip
		End
		
		OnLayout()
		
		For Local view:=Eachin _children
			view.UpdateLayout()
		Next
	End

	#rem monkeydoc @hidden
	#end
	Method Render( canvas:Canvas )

		If Not _visible Return
		
		canvas.BeginRender( _bounds,_matrix )
		
		_rstyle.Render( canvas,New Recti( 0,0,_bounds.Size ) )
		
		canvas.Viewport=_rect
		
		OnRender( canvas )

		For Local view:=Eachin _children
			view.Render( canvas )
		Next
		
		canvas.EndRender()
		
	End
	
	Protected
	
	#rem monkeydoc @hidden
	#end
	Method OnValidateStyle() Virtual
	
	End
	
	#rem monkeydoc @hidden
	#end
	Method OnMeasure:Vec2i() Virtual
	
		Return New Vec2i( 0,0 )
	End
	
	#rem monkeydoc @hidden
	#end
	Method OnMeasure2:Vec2i( size:Vec2i ) Virtual
	
		Return New Vec2i( 0,0 )
	End
	
	#rem monkeydoc @hidden
	#end
	Method OnLayout() Virtual
	
		For Local view:=Eachin _children
			view.Frame=Rect
		Next

	End
	
	#rem monkeydoc Render this view.
	
	Called when the view should render itself.
	
	#end
	Method OnRender( canvas:Canvas ) Virtual
	End
	
	#rem monkeydoc @hidden
	#end
	Method OnRenderBounds( canvas:Canvas ) Virtual
	End
	
	#rem monkeydoc @hidden
	#end
	Method OnMakeKeyView() Virtual
	
		Local window:=FindWindow()
		If window window.KeyView=Self
	
	End
	
	#rem monkeydoc Keyboard event handler.
	
	Called when a keyboard event is sent to this view.
	
	#end
	Method OnKeyEvent( event:KeyEvent ) Virtual
	End
	
	#rem monkeydoc Mouse event handler.
	
	Called when a mouse event is sent to this view.
	
	#end
	Method OnMouseEvent( event:MouseEvent ) Virtual
	End
	
	#rem monkeydoc @hidden
	#end
	Property MeasuredSize:Vec2i()
	
		Return _measuredSize
	End
	
	#rem monkeydoc @hidden
	#end
	Property LayoutSize:Vec2i()
	
		Return _layoutSize
	End
	
	#rem monkeydoc @hidden
	#end
	Property StyleBounds:Recti()
	
		Return _styleBounds
	End
	
	#rem monkeydoc @hidden
	#end
	Method Measure2:Vec2i( size:Vec2i )
		size=OnMeasure2( size-_styleBounds.Size )
		If size.x And size.y _layoutSize=size+_styleBounds.Size
		Return _layoutSize
	End
	
	Private
	
	Enum Dirty
		Style=1
		All=1
	End
	
	Field _dirty:Dirty=Dirty.All

	Field _parent:View
	Field _children:=New Stack<View>
	
	Field _visible:Bool=True
	Field _enabled:Bool=True
	Field _style:Style
	Field _styleState:String

	Field _layout:String
	Field _gravity:=New Vec2f( .5,.5 )
	Field _offset:=New Vec2i( 0,0 )

	Field _minSize:Vec2i
	Field _maxSize:Vec2i
	
	Field _frame:Recti
	
	'After Measuring...
	Field _rstyle:Style
	Field _styleBounds:Recti
	Field _measuredSize:Vec2i
	Field _layoutSize:Vec2i
	
	'After layout
	Field _rect:Recti
	Field _bounds:Recti
	Field _matrix:AffineMat3f
	Field _rmatrix:AffineMat3f
	Field _rbounds:Recti
	Field _rclip:Recti
	Field _clip:Recti
	
End
