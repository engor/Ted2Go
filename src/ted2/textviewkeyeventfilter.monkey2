
Namespace ted2

Class TextViewKeyEventFilter Extends Plugin

	Function FilterKeyEvent( event:KeyEvent,textView:TextView )
	
		Local filters:=Plugin.PluginsOfType<TextViewKeyEventFilter>()
		
		For Local filter:=Eachin filters
		
			If event.Eaten Return
			
			filter.OnFilterKeyEvent( event,textView )
		Next
	
	End

	Protected
	
	Method New()
	
		AddPlugin( Self )
	End
	
	Method OnFilterKeyEvent( event:KeyEvent,textView:TextView ) Virtual

	End
	
End

Class IJKMTextViewKeyEventFilter Extends TextViewKeyEventFilter

	Protected
	
	Method New()
	
		AddPlugin( Self ) 'don't REALLY need this unless when want to enum all IJKTextViewBlah filters!
	End
	
	Method OnFilterKeyEvent( event:KeyEvent,textView:TextView ) Override
	
		If (event.Type<>EventType.KeyDown And event.Type<>EventType.KeyRepeat) Or Not (event.Modifiers & Modifier.Alt) Return

		Local fake:Key
		Select event.Key
		Case Key.I fake=Key.Up
		Case Key.J fake=Key.Left
		Case Key.K fake=Key.Right
		Case Key.M fake=Key.Down
		Default
			Return
		End
			
		textView.SendKeyEvent( New KeyEvent( EventType.KeyDown,textView,fake,Null,event.Modifiers & Modifier.Shift,"" ) )
			
		event.Eat()
	End
	
	Private
	
	Global _instance:=New IJKMTextViewKeyEventFilter

End
