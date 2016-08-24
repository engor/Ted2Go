
Namespace mojo.input

#rem monkeydoc Global instance of the MouseDevice class.
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

#rem monkeydoc The MouseDevice class.

To access the mouse device, use the global [[Mouse]] constant.

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
	
	#rem monkeydoc Pointer visiblity state.
	#end
	Property PointerVisible:Bool()
	
		Return SDL_ShowCursor( -1 )=SDL_ENABLE
		
	Setter( pointerVisible:Bool )
	
		SDL_ShowCursor( pointerVisible ? SDL_ENABLE Else SDL_DISABLE )
	
	End
	
	#rem monkeydoc X coordinate of the mouse location.
	#end
	Property X:Int()
		Return Location.x
	End
	
	#rem monkeydoc Y coordinate of the mouse location.
	#end
	Property Y:Int()
		Return Location.y
	End

	#rem monkeydoc The mouse location.
	#end
	Property Location:Vec2i()
		Return _location
	End
	
	#rem monkeydoc Checks the current up/down state of a mouse button.
	
	Returns true if `button` is currently held down.
	
	@param button Button to checl.
	#end
	Method ButtonDown:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse buttton out of range" )
		Return _buttons[button]
	End

	#rem monkeydoc Checks if a mouse button was pressed.
	
	Returns true if `button` was pressed since the last call to ButtonPressed with the same button.

	@param button Button to check.
	
	#end
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
	
	#rem monkeydoc Checks if a mouse button was released.
	
	Returns true if `button` was released since the last call to ButtonReleased with the same button.
	
	@param button Button to check.
	
	#end
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
	
	#rem monkeydoc @hidden
	#end
	Method ButtonHit:Bool( button:MouseButton )
		Return ButtonPressed( button )
	End

	'***** Internal *****

	#rem monkeydoc @hidden
	#end
	Method Init()
		If _init Return
		App.Idle+=Poll
		_init=True
		Reset()
	End
	
	Method SendEvent( event:SDL_Event Ptr )
		'NOP for now...
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
