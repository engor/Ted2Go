
Namespace ted2

Class Ted2TextView Extends TextView

	Method New()

		CursorBlinkRate=2.5
	End

	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self )
		
		If Not event.Eaten Super.OnKeyEvent( event )
	End

End
