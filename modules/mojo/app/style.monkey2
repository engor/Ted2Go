
Namespace mojo.app

Class Style

	Method New()
		Init( "",Null,False )
	End
	
	Method New( name:String )
		Init( name,Null,False )
	End
	
	Method New( style:Style )
		Init( "",style,True )
	End
	
	Method New( name:String,style:Style )
		Init( name,style,True )
	End
	
	Method AddState:Style( state:String,srcState:String="" )
	
		Local style:=New Style
		
		style.Init( "",GetState( srcState ),False )
		
		_states[state]=style
		
		Return style
	End
	
	Method GetState:Style( state:String )
	
		Local style:=_states[state]
		If style Return style
		
		Return Self
	End

	Property BackgroundColor:Color()
		Return _bgcolor
	Setter( backgroundColor:Color )
		_bgcolor=backgroundColor
	End
	
	Property Padding:Recti()
		Return _padding
	Setter( padding:Recti )
		_padding=padding
	End
	
	Property Skin:Skin()
		Return _skin
	Setter( skin:Skin )
		_skin=skin
	End
	
	Property SkinColor:Color()
		Return _skcolor
	Setter( skinColor:Color )
		_skcolor=skinColor
	End
		
	Property Border:Recti()
		Return _border
	Setter( border:Recti )
		_border=border
	End
	
	Property BorderColor:Color()
		Return _bdcolor
	Setter( borderColor:Color )
		_bdcolor=borderColor
	End
	
	Property Margin:Recti()
		Return _margin
	Setter( margin:Recti )
		_margin=margin
	End
	
	Property DefaultColor:Color()
		Return _color
	Setter( color:Color )
		_color=color
	End
	
	Property DefaultFont:Font()
		Return _font
	Setter( font:Font )
		_font=font
	End
	
	Method SetImage( name:String,image:Image )
		_images[name]=image
	End
	
	Method GetImage:Image( name:String )
		Return _images[name]
	End
	
	Property Bounds:Recti()
		Local bounds:=Padding
		Local skin:=Skin
		If skin bounds+=Skin.Bounds
		bounds+=Border
		bounds+=Margin
		Return bounds
	End
	
	Method Render( canvas:Canvas,bounds:Recti )
	
		canvas.BlendMode=BlendMode.Alpha
	
		bounds-=Margin
		
		Local border:=Border
		Local bdcolor:=BorderColor
		
		If (border.Width Or border.Height) And bdcolor.a
		
			canvas.Color=bdcolor
			
			Local x:=bounds.X,y:=bounds.Y
			Local w:=bounds.Width,h:=bounds.Height
			Local l:=-border.min.x,r:=border.max.x
			Local t:=-border.min.y,b:=border.max.y
			
			canvas.DrawRect( x,y,l,h-b )
			canvas.DrawRect( x+l,y,w-l,t )
			canvas.DrawRect( x+w-r,y+t,r,h-t )
			canvas.DrawRect( x,y+h-b,w-r,b )

		Endif
		
		bounds-=border
		
		Local bgcolor:=BackgroundColor
		If bgcolor.a
			canvas.Color=bgcolor
			canvas.DrawRect( bounds.X,bounds.Y,bounds.Width,bounds.Height )
		Endif
		
		Local skin:=Skin
		Local skcolor:=SkinColor
		
		If skin And skcolor.a
			canvas.Color=skcolor
			skin.Draw( canvas,bounds )
		Endif
		
		Local font:=DefaultFont
		Local color:=DefaultColor
		
		canvas.Font=font
		canvas.Color=color
		
	End
	
	Function GetStyle:Style( name:String )
	
		Local style:=_styles[name]
		If style Return style
		
		Local i:=name.Find( ":" )
		If i<>-1 Return GetStyle( name.Slice( 0,i ) )
		
		Return _defaultStyle
	End

	Private
	
	Global _defaultStyle:=New Style
	Global _styles:=New StringMap<Style>
	
	Field _states:=New StringMap<Style>
	
	Field _bgcolor:Color=Color.None
	Field _padding:Recti
	Field _skin:Skin
	Field _skcolor:Color=Color.White
	Field _border:Recti
	Field _bdcolor:Color=Color.Black
	Field _margin:Recti
	Field _color:Color
	Field _font:Font
	Field _images:=New StringMap<Image>
	
	Method Init( name:String,style:Style,copyStates:Bool )
	
		If Not style style=_defaultStyle
		
		If style
			_bgcolor=style._bgcolor
			_padding=style._padding
			_skin=style._skin
			_skcolor=style._skcolor
			_border=style._border
			_bdcolor=style._bdcolor
			_margin=style._margin
			_color=style._color
			_font=style._font
			_images=style._images.Copy()
			
			If copyStates
				For Local it:=Eachin style._states
					_states[it.Key]=New Style( it.Value )
				Next
			Endif
		Endif
		
		If name
			_styles[name]=Self
		Endif
	End
	
End
