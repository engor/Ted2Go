
Namespace ted2

Class Ted2TextView Extends TextView

	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self )
		
		If Not event.Eaten Super.OnKeyEvent( event )
	End

End
