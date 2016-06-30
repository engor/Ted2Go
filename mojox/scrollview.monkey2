
Namespace mojox

Class ClipView Extends View

	Method New()
	
		Layout="fill"
	End
	
	Property ContentView:View()
	
		Return _content
		
	Setter( contentView:View )
	
		If _content RemoveChild( _content )
		
		_content=contentView
		
		If _content AddChild( _content )
	End
	
	Property ContentFrame:Recti()
	
		Return _contentFrame
	
	Setter( contentFrame:Recti )
	
		_contentFrame=contentFrame
	End
	
	Private
	
	Field _content:View
	Field _contentFrame:Recti
	
	Method OnMeasure:Vec2i() Override
	
		If _content Return _content.LayoutSize
		
		Return New Vec2i
	End
	
	Method OnLayout() Override
	
		If _content _content.Frame=_contentFrame
	End
	
End

Class ScrollView Extends View

	Method New()
		Layout="fill"
		Style=Style.GetStyle( "mojo.ScrollView" )
		
		_clipper=New ClipView
		AddChild( _clipper )

		_scrollx=New ScrollBar( Axis.X )
		_scrollx.ValueChanged=Lambda( value:Int )
			_scroll.x=value
		End
		AddChild( _scrollx )
		
		_scrolly=New ScrollBar( Axis.Y )
		_scrolly.ValueChanged=Lambda( value:Int )
			_scroll.y=value
		End
		AddChild( _scrolly )
	End

	Method New( contentView:View )
		Self.New()
		
		ContentView=contentView
	End

	Property ContentView:View()
	
		Return _content
		
	Setter( contentView:View )
	
		_content=contentView
		
		_clipper.ContentView=_content
	End
	
	Property ContentMargin:Recti()
	
		Return _contentMargin
	
	Setter( contentMargin:Recti )
	
		_contentMargin=contentMargin
	End
	
	Property ContentClipRect:Recti()
	
		Return New Recti( _scroll,_scroll+_clipper.Frame.Size )
'		Return New Recti( -_clipper.ContentFrame.Origin,_clipper.Frame.Size )
	End
	
	Property ScrollBarsVisible:Bool()
	
		Return _scrollBarsVisible
	
	Setter( scrollBarsVisible:Bool )
	
		_scrollBarsVisible=scrollBarsVisible
	End
	
	Method ScrollTo( scroll:Vec2i )

		If Not _clipper.Frame.Width Or Not _clipper.Frame.Height Return
		
		Local frame:=_clipper.Frame
		If _content frame-=_content.Style.Bounds
		
		scroll.x=Min( scroll.x,_content.Width-frame.Width )
		scroll.x=Max( scroll.x,0 )
		
		scroll.y=Min( scroll.y,_content.Height-frame.Height )
		scroll.y=Max( scroll.y,0 )
		
		_scroll=scroll
	End
	
	Method EnsureVisible( rect:Recti )

		If Not _clipper.Frame.Width Or Not _clipper.Frame.Height Return
		
		Local frame:=_clipper.Frame
		If _content frame-=_content.Style.Bounds
		
		If rect.Right>_scroll.x+frame.Width
			_scroll.x=rect.Right-frame.Width
		Endif
		
		If rect.Left<_scroll.x
			_scroll.x=rect.Left
		Endif
		
		If rect.Bottom>_scroll.y+frame.Height
			_scroll.y=rect.Bottom-frame.Height
		Endif
		
		If rect.Top<_scroll.y
			_scroll.y=rect.Top
		Endif
			
	End
	
	Protected
	
	Method OnMeasure:Vec2i() Override
	
		Return _clipper.LayoutSize+_contentMargin.Size
	End
	
	Method OnLayout() Override
	
		If Not _content Return
	
		Local size:=Rect.Size
		
		Local csize:=size-_contentMargin.Size
		Local vsize:=_content.Measure2( size-New Vec2i( _scrolly.LayoutSize.x,0 ) )
		
		If _scrollBarsVisible

	'		Print "size="+size.ToString()
	'		Print "csize="+csize.ToString()
	'		Print "vsize="+vsize.ToString()
			
			Local xbar:=_scrollx.LayoutSize.y
			Local ybar:=_scrolly.LayoutSize.x
			
			If vsize.y<=csize.y
				If vsize.x<=csize.x xbar=0
			Else
				If vsize.x<=csize.x-ybar xbar=0
			Endif
			
			If vsize.y<=csize.y-xbar ybar=0
			
			csize.x-=ybar
			csize.y-=xbar
			
			If xbar
				_scrollx.Visible=True
				_scrollx.Frame=New Recti( 0,size.y-xbar,size.x-ybar,size.y )
				_scrollx.PageSize=csize.x
				_scrollx.Maximum=vsize.x-csize.x
				_scrollx.Value=_scroll.x
			Else
				_scrollx.Visible=False
				_scrollx.Value=0
				vsize.x=csize.x
			Endif
			
			If ybar
				_scrolly.Visible=True
				_scrolly.Frame=New Recti( size.x-ybar,0,size.x,size.y-xbar )
				_scrolly.PageSize=csize.y
				_scrolly.Maximum=vsize.y-csize.y
				_scrolly.Value=_scroll.y
			Else
				_scrolly.Visible=False
				_scrolly.Value=0
				vsize.y=csize.y
			Endif

		Else
			_scrollx.Visible=False
			_scrollx.PageSize=csize.x
			_scrollx.Maximum=vsize.x-csize.x
			_scrollx.Value=_scroll.x
			
			_scrolly.Visible=False
			_scrolly.PageSize=csize.y
			_scrolly.Maximum=vsize.y-csize.y
			_scrolly.Value=_scroll.y

		Endif
		
		_scroll.x=_scrollx.Value
		_scroll.y=_scrolly.Value
		
		_clipper.ContentFrame=New Recti( -_scroll,-_scroll+vsize )
		
		_clipper.Frame=New Recti( 0,0,csize )-_contentMargin.Origin

	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		If _content _content.SendKeyEvent( event )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseWheel
			_scroll.y-=event.Wheel.Y*16
		End
		
	End

	Private
	
	Field _content:View
	Field _contentMargin:Recti
	
	Field _scroll:Vec2i

	Field _clipper:ClipView	
	Field _scrollx:ScrollBar
	Field _scrolly:ScrollBar
	
	Field _scrollBarsVisible:Bool=True
	
End

	
	
	