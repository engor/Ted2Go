
Namespace mojo.app

#rem monkeydoc The Style class.
#end
Class Style

	Method New()
		Init( "",Null,False )
	End
	
	Method New( style:Style )
		Init( "",style,True )
	End
	
	#rem monkeydoc @hidden
	#end
	Method New( name:String )
		Init( name,Null,False )
	End
	
	#rem monkeydoc @hidden
	#end
	Method New( name:String,style:Style )
		Init( name,style,True )
	End
	
	#rem monkeydoc @hidden
	#end
	Method AddState:Style( state:String,srcState:String="" )
	
		Local style:=New Style
		
		style.Init( "",GetState( srcState ),False )
		
		_states[state]=style
		
		Return style
	End
	
	#rem monkeydoc @hidden
	#end
	Method GetState:Style( state:String )
	
		Local style:=_states[state]
		If style Return style
		
		Return Self
	End

	#rem monkeydoc Background color.
	#end
	Property BackgroundColor:Color()
		Return _bgcolor
	Setter( backgroundColor:Color )
		_bgcolor=backgroundColor
	End
	
	#rem monkeydoc Padding rect.
	#end
	Property Padding:Recti()
		Return _padding
	Setter( padding:Recti )
		_padding=padding
	End
	
	#rem monkeydoc @hidden
	#end
	Property Skin:Skin()
		Return _skin
	Setter( skin:Skin )
		_skin=skin
	End
	
	#rem monkeydoc @hidden
	#end
	Property SkinColor:Color()
		Return _skcolor
	Setter( skinColor:Color )
		_skcolor=skinColor
	End
		
	#rem monkeydoc Border rect.
	#end
	Property Border:Recti()
		Return _border
	Setter( border:Recti )
		_border=border
	End
	
	#rem monkeydoc Border color.
	#End
	Property BorderColor:Color()
		Return _bdcolor
	Setter( borderColor:Color )
		_bdcolor=borderColor
	End

	#rem monkeydoc Margin rect.
	#end
	Property Margin:Recti()
		Return _margin
	Setter( margin:Recti )
		_margin=margin
	End
	
	#rem monkeydoc Default canvas color.
	#end
	Property DefaultColor:Color()
		Return _color
	Setter( color:Color )
		_color=color
	End

	#rem monkeydoc Default canvas font.
	#end	
	Property DefaultFont:Font()
		Return _font
	Setter( font:Font )
		_font=font
	End
	
	#rem monkeydoc @hidden
	#end
	Method SetImage( name:String,image:Image )
		_images[name]=image
	End
	
	#rem monkeydoc @hidden
	#end
	Method GetImage:Image( name:String )
		Return _images[name]
	End
	
	#rem monkeydoc @hidden
	#end
	Property Bounds:Recti()
		Local bounds:=Padding
		Local skin:=Skin
		If skin bounds+=Skin.Bounds
		bounds+=Border
		bounds+=Margin
		Return bounds
	End
	
	#rem monkeydoc @hidden
	#end
	Method Render( canvas:Canvas,bounds:Recti )

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
		
		canvas.Font=_font
		canvas.Color=_color
		
	End
	
	#rem monkeydoc @hidden
	#end
	Function GetStyle:Style( name:String )
	
		Local style:=_styles[name]
		If style Return style
		
		Local i:=name.Find( ":" )
		If i<>-1 Return GetStyle( name.Slice( 0,i ) )
		
		If Not _defaultStyle _defaultStyle=New Style
		Return _defaultStyle
	End

	Private
	
	Global _defaultStyle:Style
	Global _styles:=New StringMap<Style>
	
	Field _states:=New StringMap<Style>
	
	Field _bgcolor:Color=Color.None
	Field _padding:Recti
	Field _skin:Skin
	Field _skcolor:Color=Color.White
	Field _border:Recti
	Field _bdcolor:Color=Color.None
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
