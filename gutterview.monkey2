
Namespace ted2

Class GutterView Extends View

	Method New( textView:TextView )
	
		_textView=textView
		
		Style.Margin=New Recti( 0,0,8,0 )
	End
	
	Protected
	
	Method OnMeasure:Vec2i() Override

		Return New Vec2i( RenderStyle.Font.TextWidth( "XXXXXXX" ),0 )
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		canvas.Color=_textView.RenderStyle.BackgroundColor
		
		canvas.DrawRect( Rect.X,Rect.Y,Rect.Width,Rect.Height )
		
		canvas.Color=Color.Grey
		
		Local vrect:=_textView.VisibleRect
		
		Local firstLine:=_textView.LineAtPoint( vrect.TopLeft )
		Local lastLine:=_textView.LineAtPoint( vrect.BottomLeft )+1
		
		canvas.Translate( 0,-vrect.Top )
		
		For Local i:=firstLine Until lastLine
		
			Local rect:=_textView.LineRect( i )
		
			canvas.DrawText( i+1,Width,rect.Top,1,0 )
		Next
		
	End
	
	Field _textView:TextView
	
End
