
Namespace mojo.input

#rem monkeydoc Application mouse device instance.
#end
Const Mouse:=New MouseDevice

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
End

#rem monkeydoc The MouseDevice singleton class.

To access the mouse device, use the [[Mouse]] constant.

The mouse device should only used after a new [[app.AppInstance]] is created.

#end
Class MouseDevice Extends InputDevice

	#rem monkeydoc @hidden
	#end
	Method Reset()
		For Local i:=0 Until 4
			_pressed[i]=True
			_released[i]=True
		Next
	End
	
	Property PointerVisible:Bool()
	
		Return SDL_ShowCursor( -1 )=SDL_ENABLE
		
	Setter( pointerVisible:Bool )
	
		SDL_ShowCursor( pointerVisible ? SDL_ENABLE Else SDL_DISABLE )
	
	End
	
	Property X:Int()
		Return Location.x
	End
	
	Property Y:Int()
		Return Location.y
	End

	Property Location:Vec2i()
		Return _location
	End
	
	Method ButtonDown:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse buttton out of range" )
		Return _buttons[button]
	End

	Method ButtonPressed:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse buttton out of range" )
		If _buttons[button]
			If _pressed[button] Return False
			_pressed[button]=True
			Return True
		Endif
		_pressed[button]=False
		Return False
	End
	
	Method ButtonReleased:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse buttton out of range" )
		If Not _buttons[button]
			If _released[button] Return False
			_released[button]=True
			Return True
		Endif
		_released[button]=False
		Return False
	End
	
	Method ButtonHit:Bool( button:MouseButton )
		Return ButtonPressed( button )
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
	
	'***** Internal *****

	Method Init()
		If _init Return
		App.Idle+=Poll
		_init=True
		Reset()
	End
	
	Private

	Field _init:Bool	
	Field _location:Vec2i
	Field _buttons:=New Bool[4]
	Field _pressed:=New Bool[4]
	Field _released:=New Bool[4]
	
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

End
