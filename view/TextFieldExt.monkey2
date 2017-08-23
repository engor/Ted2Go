
Namespace ted2go


Class TextFieldExt Extends TextField 'Implements IKeyView
	
	Property NextView:TextFieldExt()
		
		Return _next
		
	Setter( view:TextFieldExt )
		
		_next=view
		view._prev=Self 'set prev automatically
	End
	
	Property PrevView:TextFieldExt()
		
		Return _prev
		
	Setter( view:TextFieldExt )
		
		_prev=view
		view._next=Self 'set next automatically
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		If ProcessKeyEvent( event ) Return
		
		Super.OnKeyEvent( event )
	End
	
	Method MakeMeKeyView()
		
		MakeKeyView()
	End
	
	Private
	
	Field _next:TextFieldExt,_prev:TextFieldExt
	
	Method ProcessKeyEvent:Bool( event:KeyEvent )
		
		If event.Key=Key.Tab 
			Local shift:=(event.Modifiers & Modifier.Shift)
			If _next And Not shift
				If event.Type=EventType.KeyUp Then _next.MakeMeKeyView()
				Return True
			Elseif _prev And shift
				If event.Type=EventType.KeyUp Then _prev.MakeMeKeyView()
				Return True
			Endif
		Endif
		Return False
	End
	
End


'Interface IKeyView
'	
'	Method ProcessKeyEvent:Bool( event:KeyEvent )
'	Method MakeMeKeyView()
'	Method SetNextView:IKeyView( view:IKeyView )
'	Method SetPrevView:IKeyView( view:IKeyView )
'	
'End
