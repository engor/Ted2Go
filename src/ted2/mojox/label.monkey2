
Namespace mojox

Class Label Extends View

	Field Clicked:Void()
	
	Field Dragged:Void( offset:Vec2i )

	Method New()
		Layout="float"
		Style=Style.GetStyle( "mojo.Label" )
		Gravity=New Vec2f( 0,.5 )
		TextGravity=New Vec2f( 0,.5 )
	End
	
	Method New( icon:Image )
		Self.New()
		
		Icon=icon
	End
	
	Method New( text:String,icon:Image=Null )
		Self.New()
		
		Text=text
		Icon=icon
	End
	
	Property Text:String()
	
		Return _text
		
	Setter( text:String )
	
		_text=text
	End
	
	Property Icon:Image()
	
		Return _icon
	
	Setter( icon:Image )
	
		_icon=icon
	End
	
	Property CheckMark:Image()
	
		Return _check
		
	Setter( checkMark:Image )
	
		_check=checkMark
	End
	
	Property TextGravity:Vec2f()
	
		Return _textGravity
	
	Setter( textGravity:Vec2f )
	
		_textGravity=textGravity
	End
	
	Protected

	Method OnMeasure:Vec2i() Override
	
		Local size:=New Vec2i
		
		If _text
			size.x=RenderStyle.DefaultFont.TextWidth( _text )
			size.y=RenderStyle.DefaultFont.Height
		Endif

		If _icon
			size.x+=_icon.Width
			size.y=Max( size.y,Int( _icon.Height ) )
		Endif
		
		If _check
			size.x+=_check.Width
			size.y=Max( size.y,Int( _check.Height ) )
		Endif
		
		Return size
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		Local x:=0,w:=0
		
		If _icon
			Local y:=(MeasuredSize.y-_icon.Height)/2
			canvas.DrawImage( _icon,0,y )
			w+=_icon.Width
			x=_icon.Width
		Endif
		
		If _check
			Local y:=(MeasuredSize.y-_check.Height)/2
			canvas.DrawImage( _check,Width-_check.Width,y )
			w+=_check.Width
		Endif
		
		If _text
			Local tx:=((Width-w)-(MeasuredSize.x-w)) * _textGravity.x
			Local ty:=(Height-MeasuredSize.y) * _textGravity.y
			canvas.DrawText( _text,tx+x,ty )
		Endif

	End
	
	Private
	
	Field _text:String
	Field _textGravity:Vec2f
	Field _icon:Image
	Field _check:Image
	
End

