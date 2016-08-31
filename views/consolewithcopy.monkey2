
Namespace ted2


Class ConsoleWithCopy Extends Console

	Method New()
		Super.New()
	End
	
	
	Protected
	
	Method OnKeyEvent(event:KeyEvent) Override
		
		If CanCopy And (event.Key = Key.C Or event.Key = Key.Insert) And  event.Type = EventType.KeyDown And event.Modifiers & Modifier.Control
			Copy()
		Endif
		
	End
	
End
