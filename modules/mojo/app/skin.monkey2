
Namespace mojo.app

#rem monkeydoc @hidden
#end
Class Skin

	Property Image:Image()
		Return _image
	End
	
	Property Bounds:Recti()
		Return _bounds
	End

	Method Draw( canvas:Canvas,rect:Recti )
	
		Local x0:=rect.Left
		Local x1:=rect.Left+_x1
		Local x2:=rect.Right-(_x3-_x2)
		Local x3:=rect.Right
		
		Local y0:=rect.Top
		Local y1:=rect.Top+_y1
		Local y2:=rect.Bottom-(_y3-_y2)
		Local y3:=rect.Bottom
		
		canvas.DrawRect( x0,y0,x1-x0,y1-y0,_image,_x0,_y0,_x1-_x0,_y1-_y0 )
		canvas.DrawRect( x1,y0,x2-x1,y1-y0,_image,_x1,_y0,_x2-_x1,_y1-_y0 )
		canvas.DrawRect( x2,y0,x3-x2,y1-y0,_image,_x2,_y0,_x3-_x2,_y1-_y0 )
		
		canvas.DrawRect( x0,y1,x1-x0,y2-y1,_image,_x0,_y1,_x1-_x0,_y2-_y1 )
		canvas.DrawRect( x1,y1,x2-x1,y2-y1,_image,_x1,_y1,_x2-_x1,_y2-_y1 )
		canvas.DrawRect( x2,y1,x3-x2,y2-y1,_image,_x2,_y1,_x3-_x2,_y2-_y1 )
		
		canvas.DrawRect( x0,y2,x1-x0,y3-y2,_image,_x0,_y2,_x1-_x0,_y3-_y2 )
		canvas.DrawRect( x1,y2,x2-x1,y3-y2,_image,_x1,_y2,_x2-_x1,_y3-_y2 )
		canvas.DrawRect( x2,y2,x3-x2,y3-y2,_image,_x2,_y2,_x3-_x2,_y3-_y2 )
	
	End

	Function Load:Skin( path:String )
	
		Local pixmap:=Pixmap.Load( path )
		If Not pixmap Return Null
		
		pixmap.PremultiplyAlpha()
		
		Return New Skin( pixmap )
	End
	
	Private
	
	Field _image:Image
	Field _bounds:Recti
	Field _rect:Recti
	
	Field _x0:Int,_x1:Int,_x2:Int,_x3:Int
	Field _y0:Int,_y1:Int,_y2:Int,_y3:Int
	
	Method New( pixmap:Pixmap )
	
		Local _scale:Recti
		Local _fill:Recti
	
		For Local x:=1 Until pixmap.Width-1
			Local p:=pixmap.GetPixelARGB( x,0 )
			If p=UInt( $ff000000 )
				If Not _scale.min.x _scale.min.x=x
				_scale.max.x=x+1
			Endif
			p=pixmap.GetPixelARGB( x,pixmap.Height-1 )
			If p=UInt( $ff000000 )
				If Not _fill.min.x _fill.min.x=x
				_fill.max.x=x+1
			Endif
		Next
		
		For Local y:=1 Until pixmap.Height-1
			Local p:=pixmap.GetPixelARGB( 0,y )
			If p=UInt( $ff000000 )
				If Not _scale.min.y _scale.min.y=y
				_scale.max.y=y+1
			Endif
			p=pixmap.GetPixelARGB( pixmap.Width-1,y )
			If p=UInt( $ff000000 )
				If Not _fill.min.y _fill.min.y=y
				_fill.max.y=y+1
			Endif
		Next
		
		If _scale.min.x And _scale.min.y
			pixmap=pixmap.Window( 1,1,pixmap.Width-2,pixmap.Height-2 )
			If Not _fill.min.x Or Not _fill.min.y _fill=_scale
			_scale-=New Vec2i( 1,1 )
			_fill-=New Vec2i( 1,1 )
		Else
			_scale=New Recti( pixmap.Width/3,pixmap.Height/3,pixmap.Width*2/3,pixmap.Height*2/3 )
			_fill=_scale
		Endif
		
		_rect=New Recti( 0,0,pixmap.Width,pixmap.Height )
		
		_x0=0
		_x1=_scale.min.x
		_x2=_scale.max.x
		_x3=_rect.max.x
		
		_y0=0
		_y1=_scale.min.y
		_y2=_scale.max.y
		_y3=_rect.max.y
		
		_image=New Image( pixmap )
		_bounds=New Recti( -_fill.min,_rect.max-_fill.max )
	
	End
End

