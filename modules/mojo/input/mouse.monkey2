
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
		DebugAssert( button>=0 And button<4,"Mouse button out of range" )
		Return _down[button]
	End

	#rem monkeydoc Checks if a mouse button was pressed.
	
	Returns true if `button` was pressed since the last app update.

	@param button Button to check.
	
	#end
	Method ButtonPressed:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse button out of range" )
		Return _pressed[button]
	End
	
	#rem monkeydoc Checks if a mouse button was released.
	
	Returns true if `button` was released since the last app update.
	
	@param button Button to check.
	
	#end
	Method ButtonReleased:Bool( button:MouseButton )
		DebugAssert( button>=0 And button<4,"Mouse button out of range" )
		Return _released[button]
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
	End
	
	#rem monkeydoc @hidden
	#end
	Method Update()
	
		Local mask:=SDL_GetMouseState( Varptr _location.x,Varptr _location.y )
		If App.ActiveWindow	_location=App.ActiveWindow.TransformPointFromView( App.ActiveWindow.MouseScale * _location,Null )
		
		UpdateButton( MouseButton.Left,mask & 1 )
		UpdateButton( MouseButton.Middle,mask & 2 )
		UpdateButton( MouseButton.Right,mask & 4)
	End
	
	#rem monkeydoc @hidden
	#end
	Method UpdateButton( button:MouseButton,down:Bool )
		_pressed[button]=False
		_released[button]=False
		If down=_down[button] Return
		If down _pressed[button]=True Else _released[button]=True
		_down[button]=down
	End
	
	Private

	Field _init:Bool	
	Field _location:Vec2i
	Field _down:=New Bool[4]
	Field _pressed:=New Bool[4]
	Field _released:=New Bool[4]
	
	Method New()
	End
	
End
