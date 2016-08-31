
Namespace ted2


Class Ted2CodeTextView Extends CodeTextView

	Field FileType:String 'where else we can store this type?
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self,FileType )
		
		If Not event.Eaten Super.OnKeyEvent( event )
	End

End


Class Ted2TextView Extends TextView

	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		TextViewKeyEventFilter.FilterKeyEvent( event,Self )
		
		If Not event.Eaten Super.OnKeyEvent( event )
	End

End

