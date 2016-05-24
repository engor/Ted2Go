
Namespace mojo.input

Global Mouse:=New MouseDevice

#rem monkeydoc Mouse buttons.

| MouseButton	| Description
|:--------------|------------
| Left			| Left mouse button.
| Middle		| Middle mouse button.
| Right			| Right mouse button.

#end
Enum MouseButton
	None=0
	Left=1
	Middle=2
	Right=3
	X1=4
	X2=5
End

Class MouseDevice Extends InputDevice

	Method Reset()
		Init()
		For Local i:=0 Until 6
			_hits[i]=True
		Next
	End
	
	Property X:Int()
		Return Location.x
	End
	
	Property Y:Int()
		Return Location.y
	End

	Property Location:Vec2i()
		Init()
		Return _location
	End
	
	Method ButtonDown:Bool( button:MouseButton )
		Init()
		Return _buttons[button]
	End

	Method ButtonHit:Bool( button:MouseButton )
		Init()
		If _buttons[button]
			If _hits[button] Return False
			_hits[button]=True
			Return True
		Endif
		_hits[button]=False
		Return False
	End
	
	#rem monkeydoc @hidden
	#end	
	'Method GetButton:Bool( index:Int ) Override
	'	Return ButtonDown( Cast<MouseButton>( index ) )
	'End
	
	#rem monkeydoc @hidden
	#end	
	'Method GetPointer:Vec2i( index:Int ) Override
	'	Return Location
	'End
	
	Private

	Field _init:Bool	
	Field _location:Vec2i
	Field _buttons:=New Bool[6]
	Field _hits:=New Bool[6]
	
	Method New()
	End
	
	Method Poll()
		Local mask:=SDL_GetMouseState( Varptr _location.x,Varptr _location.y )
		If App.ActiveWindow _location=App.ActiveWindow.TransformPointFromView( _location,Null )
		_buttons[MouseButton.Left]=mask & 1
		_buttons[MouseButton.Middle]=mask & 2
		_buttons[MouseButton.Right]=mask & 4
		App.Idle+=Poll
	End

	Method Init()
		If _init Return
		App.Idle+=Poll
		_init=True
	End
	
End
