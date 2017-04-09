
Namespace ted2go


Class CodeGutterView Extends View

	Method New( doc:CodeDocument )
		Style=GetStyle( "GutterView" )
	
		_doc = doc
		'_textView = doc.TextView
	End
	
	Protected
	
	Method OnValidateStyle() Override
	
		Local font:=RenderStyle.Font
	
		_width=font.TextWidth( "1234567" )

		_size=New Vec2i( font.TextWidth( "12345678" ),0 )
	End
	
	Method OnMeasure:Vec2i() Override
	
		Return _size
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		_textView=_doc.TextView
		
		Local selLine:=_textView.Document.FindLine( _textView.Cursor )
		
		canvas.Color=RenderStyle.BackgroundColor
		
		canvas.DrawRect( Rect.X,Rect.Y,Rect.Width,Rect.Height )
		
		Local textColor:=RenderStyle.TextColor
		
		Local vrect:=_textView.VisibleRect
		
		Local firstLine:=_textView.LineAtPoint( vrect.TopLeft )

		Local lastLine:=_textView.LineAtPoint( vrect.BottomLeft )+1
		
		canvas.Translate( 0,-vrect.Top )
		
		If _errorIcon = Null Then _errorIcon=CodeItemIcons.GetIcon( "warning" )
		
		canvas.Color=textColor
		
		For Local i:=firstLine Until lastLine
		
			Local rect:=_textView.LineRect( i )
		
			If i<>selLine And (i+1) Mod 10 <> 0
				canvas.Alpha=0.5
				canvas.DrawRect( _width-4,rect.Top+rect.Height*0.5-1,2,2 )
				canvas.Alpha=1
				Continue
			Endif
			
			' show error bubble
			
			If _doc.HasErrors And _doc.HasErrorAt( i )
				If _errorIcon <> Null
					canvas.Color=Color.White
					canvas.DrawImage( _errorIcon,_width-_errorIcon.Width,rect.Top )
					canvas.Color=textColor
				Endif
			Else
				canvas.Color=(i = selLine) ? textColor*1.1 Else textColor 'make selected line number little brighter
				canvas.DrawText( i+1,_width,rect.Top,1,0 )
			Endif
			
		Next
		
	End
	
	#Rem
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Select event.Type
			Case EventType.MouseMove
				
			
		End
		
		Super.OnContentMouseEvent( event )
		
	End
	#End
	
	Private
	
	Field _width:Int
	Field _size:Vec2i
	Field _textView:TextView
	Field _doc:CodeDocument
	
	Global _errorIcon:Image
	
End
