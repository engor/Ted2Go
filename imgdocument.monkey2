
Namespace ted2

Class ImgView Extends View

	Method New( doc:ImgDocument )
		_doc=doc
		
		Layout="fill"
	End
	
	Protected
	
	Method OnRender( canvas:Canvas ) Override
	
		For Local x:=0 Until Width Step 64
			For Local y:=0 Until Height Step 64
				canvas.Color=(x~y) & 64 ? New Color( .1,.1,.1 ) Else New Color( .2,.2,.2 )
				canvas.DrawRect( x,y,64,64 )
			Next
		Next
		
		If Not _doc.Image Return
		
		canvas.Color=Color.White
		
		canvas.Translate( Width/2,Height/2 )
		
		canvas.Scale( _zoom,_zoom )
	
		canvas.DrawImage( _doc.Image,0,0 )
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseWheel
			If event.Wheel.Y>0
				_zoom*=2
			Else If event.Wheel.Y<0
				_zoom/=2
			Endif
		End
	
	End
	
	Private

	Field _zoom:Float=1
		
	Field _doc:ImgDocument
End

Class ImgDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_view=New ImgView( Self )
	End
	
	Property Image:Image()
	
		Return _image
	End
	
	Protected
	
	Method OnLoad:Bool() Override
	
		Print "Loading image:"+Path
	
		_image=Image.Load( Path )
		If Not _image Return False
		
		Print "OK!"
		
		_image.Handle=New Vec2f( .5,.5 )
		
		Return True
	End
	
	Method OnSave:Bool() Override

		Return False
	End
	
	Method OnClose() Override
	
		If _image _image.Discard()
	End
	
	Method OnCreateView:ImgView() Override
	
		Return _view
	End
	
	Private
	
	Field _image:Image
	
	Field _view:ImgView
	
End
