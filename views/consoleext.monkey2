
Namespace ted2go


Class ConsoleExt Extends Console

	Method New()
		Super.New()
	End
	
	
	Protected
	
	Method OnKeyEvent(event:KeyEvent) Override
		
		If CanCopy And (event.Key = Key.C Or event.Key = Key.Insert) And  event.Type = EventType.KeyDown And event.Modifiers & Modifier.Control
			Copy()
		Endif
		
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		'select whole line by double click
		If event.Type = EventType.MouseDoubleClick
			Local line := Document.FindLine(Cursor)
			SelectText( Document.StartOfLine(line),Document.EndOfLine(line) )
			Return
		Endif
		
		Super.OnContentMouseEvent(event)
	End
	
End
