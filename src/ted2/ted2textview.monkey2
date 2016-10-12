
Namespace ted2

Class Ted2TextView Extends TextView

	Method New()

#If __TARGET__<>"raspbian"
		CursorBlinkRate=2.5	'crashing on Pi?
#Endif

	End

	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self )
		
		If Not event.Eaten Super.OnKeyEvent( event )
	End

End
